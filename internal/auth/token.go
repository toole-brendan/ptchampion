package auth

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"ptchampion/internal/store/redis"
)

// TokenType defines the type of token issued
type TokenType string

const (
	// AccessToken is a short-lived token for API access
	AccessToken TokenType = "access"
	// RefreshToken is a longer-lived token for getting new access tokens
	RefreshToken TokenType = "refresh"

	// Token durations
	accessTokenDuration  = time.Hour * 12     // 12 hours
	refreshTokenDuration = time.Hour * 24 * 7 // 7 days
	tokenIssuer          = "ptchampion"
)

// TokenPair represents a pair of access and refresh tokens
type TokenPair struct {
	AccessToken           string    `json:"access_token"`
	RefreshToken          string    `json:"refresh_token"`
	AccessTokenExpiresAt  time.Time `json:"access_token_expires_at"`
	RefreshTokenExpiresAt time.Time `json:"refresh_token_expires_at"`
}

// JWTClaims contains JWT claims with user information
type JWTClaims struct {
	jwt.RegisteredClaims
	UserID    string    `json:"user_id"`
	TokenType TokenType `json:"token_type"`
}

// TokenService handles token operations and refresh token storage
type TokenService struct {
	accessSecret  []byte
	refreshSecret []byte
	RefreshStore  redis.RefreshStore
	accessTTL     time.Duration
	refreshTTL    time.Duration
}

// NewTokenService creates a new TokenService with configured secrets and token store
func NewTokenService(accessSecret, refreshSecret string, store redis.RefreshStore) *TokenService {
	return &TokenService{
		accessSecret:  []byte(accessSecret),
		refreshSecret: []byte(refreshSecret),
		RefreshStore:  store,
		accessTTL:     accessTokenDuration,
		refreshTTL:    refreshTokenDuration,
	}
}

// GenerateTokenPair creates a new access and refresh token pair
func (s *TokenService) GenerateTokenPair(ctx context.Context, userID string) (*TokenPair, error) {
	// Generate access token
	accessTokenExpiry := time.Now().Add(s.accessTTL)
	accessToken, err := s.generateToken(userID, AccessToken, accessTokenExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate refresh token
	refreshTokenID := uuid.New().String()
	refreshTokenExpiry := time.Now().Add(s.refreshTTL)
	refreshToken, err := s.generateToken(userID, RefreshToken, refreshTokenExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Store refresh token in Redis
	token := redis.RefreshToken{
		ID:        refreshTokenID,
		UserID:    userID,
		IssuedAt:  time.Now(),
		ExpiresAt: refreshTokenExpiry,
	}

	if err := s.RefreshStore.Save(ctx, token); err != nil {
		return nil, fmt.Errorf("failed to save refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:           accessToken,
		RefreshToken:          refreshToken,
		AccessTokenExpiresAt:  accessTokenExpiry,
		RefreshTokenExpiresAt: refreshTokenExpiry,
	}, nil
}

// RefreshTokens validates a refresh token and issues a new token pair
// Returns the new token pair, the user ID, and an error.
func (s *TokenService) RefreshTokens(ctx context.Context, refreshToken string) (*TokenPair, string, error) {
	// Parse and validate the refresh token
	token, err := jwt.ParseWithClaims(refreshToken, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		return s.refreshSecret, nil
	})

	if err != nil {
		return nil, "", fmt.Errorf("invalid refresh token: %w", err)
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, "", errors.New("invalid token claims")
	}

	// Verify this is a refresh token
	if claims.TokenType != RefreshToken {
		return nil, "", errors.New("token is not a refresh token")
	}

	// Verify the token exists in our store
	tokenID := claims.ID
	_, err = s.RefreshStore.Find(ctx, tokenID)
	if err != nil {
		return nil, "", fmt.Errorf("refresh token not found: %w", err)
	}

	// Revoke the used refresh token (one-time use)
	if err := s.RefreshStore.Revoke(ctx, tokenID); err != nil {
		return nil, "", fmt.Errorf("failed to revoke refresh token: %w", err)
	}

	// Generate a new token pair
	newTokenPair, err := s.GenerateTokenPair(ctx, claims.UserID)
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate new token pair during refresh: %w", err)
	}

	// Return the new token pair AND the user ID from the original claims
	return newTokenPair, claims.UserID, nil
}

// ValidateAccessToken validates an access token and returns the claims
func (s *TokenService) ValidateAccessToken(tokenString string) (*JWTClaims, error) {
	log.Printf("DEBUG: ValidateAccessToken called with token starting with %s...", tokenString[:15])

	// First basic parsing to extract claims without full validation
	parser := &jwt.Parser{}
	token, _, err := parser.ParseUnverified(tokenString, &JWTClaims{})
	if err != nil {
		log.Printf("ERROR: Failed to parse token (unverified): %v", err)
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}
	log.Printf("DEBUG: Initial token parsing (unverified) successful")

	// Get claims for type checking
	claims, ok := token.Claims.(*JWTClaims)
	if !ok {
		log.Printf("ERROR: Token claims not of type JWTClaims, got %T", token.Claims)
		return nil, errors.New("invalid token claims")
	}
	log.Printf("DEBUG: Claims extracted: user_id=%s, token_type=%s, exp=%v", claims.UserID, claims.TokenType, claims.ExpiresAt)

	// Check token type before validation (early rejection for wrong token types)
	if claims.TokenType != AccessToken {
		log.Printf("ERROR: Wrong token type: expected %s, got %s", AccessToken, claims.TokenType)
		return nil, errors.New("wrong token type")
	}
	log.Printf("DEBUG: Token type validated as AccessToken")

	// Now validate the token fully
	token, err = jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method (optional but recommended)
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			log.Printf("ERROR: Unexpected signing method: %v", token.Header["alg"])
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.accessSecret, nil
	})

	if err != nil {
		log.Printf("ERROR: Full token validation failed: %v", err)
		return nil, fmt.Errorf("invalid access token: %w", err)
	}
	log.Printf("DEBUG: Full token validation successful")

	claims, ok = token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		log.Printf("ERROR: Invalid token claims after full validation: valid=%v, ok=%v", token.Valid, ok)
		return nil, errors.New("invalid token claims")
	}
	log.Printf("DEBUG: Token is valid and all checks passed for user_id=%s", claims.UserID)

	return claims, nil
}

// RevokeAllUserTokens revokes all refresh tokens for a user
func (s *TokenService) RevokeAllUserTokens(ctx context.Context, userID string) error {
	return s.RefreshStore.RevokeAllForUser(ctx, userID)
}

// generateToken creates a signed JWT token
func (s *TokenService) generateToken(userID string, tokenType TokenType, expiry time.Time) (string, error) {
	// Add a unique ID to the token
	tokenID := uuid.New().String()

	claims := &JWTClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiry),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    tokenIssuer,
			Subject:   userID,
			ID:        tokenID,
		},
		UserID:    userID,
		TokenType: tokenType,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	var secret []byte
	if tokenType == AccessToken {
		secret = s.accessSecret
	} else {
		secret = s.refreshSecret
	}

	tokenString, err := token.SignedString(secret)
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, nil
}

// GetAccessTokenDuration returns the access token duration
func GetAccessTokenDuration() time.Duration {
	return accessTokenDuration
}

// generateRandomString creates a random string for use in token IDs
func generateRandomString(length int) (string, error) {
	b := make([]byte, length)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b)[:length], nil
}
