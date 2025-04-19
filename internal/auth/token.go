package auth

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// TokenType defines the type of token issued
type TokenType string

const (
	// AccessToken is a short-lived token (15m) for API access
	AccessToken TokenType = "access"
	// RefreshToken is a longer-lived token (7d) for getting new access tokens
	RefreshToken TokenType = "refresh"
)

// TokenPair represents a pair of access and refresh tokens
type TokenPair struct {
	AccessToken           string    `json:"access_token"`
	RefreshToken          string    `json:"refresh_token"`
	AccessTokenExpiresAt  time.Time `json:"access_token_expires_at"`
	RefreshTokenExpiresAt time.Time `json:"refresh_token_expires_at"`
}

// CustomClaims extends jwt.RegisteredClaims to include custom data
type CustomClaims struct {
	jwt.RegisteredClaims
	UserID    string    `json:"user_id"`
	TokenType TokenType `json:"token_type"`
}

// JWTService handles JWT token generation and validation
type JWTService struct {
	accessSecret  []byte
	refreshSecret []byte
	accessTTL     time.Duration
	refreshTTL    time.Duration
}

// NewJWTService creates a new JWTService
func NewJWTService(accessSecret, refreshSecret string, accessTTL, refreshTTL time.Duration) *JWTService {
	return &JWTService{
		accessSecret:  []byte(accessSecret),
		refreshSecret: []byte(refreshSecret),
		accessTTL:     accessTTL,
		refreshTTL:    refreshTTL,
	}
}

// GenerateTokenPair creates a new access and refresh token pair
func (s *JWTService) GenerateTokenPair(userID string) (*TokenPair, error) {
	// Generate access token
	accessTokenExpiry := time.Now().Add(s.accessTTL)
	accessToken, err := s.generateToken(userID, AccessToken, accessTokenExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate refresh token
	refreshTokenExpiry := time.Now().Add(s.refreshTTL)
	refreshToken, err := s.generateToken(userID, RefreshToken, refreshTokenExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:           accessToken,
		RefreshToken:          refreshToken,
		AccessTokenExpiresAt:  accessTokenExpiry,
		RefreshTokenExpiresAt: refreshTokenExpiry,
	}, nil
}

// RefreshTokens validates a refresh token and issues a new token pair
func (s *JWTService) RefreshTokens(refreshToken string) (*TokenPair, error) {
	// Parse and validate the refresh token
	token, err := jwt.ParseWithClaims(refreshToken, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		return s.refreshSecret, nil
	})

	if err != nil {
		return nil, fmt.Errorf("invalid refresh token: %w", err)
	}

	claims, ok := token.Claims.(*CustomClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	// Verify this is a refresh token
	if claims.TokenType != RefreshToken {
		return nil, errors.New("token is not a refresh token")
	}

	// Generate a new token pair
	return s.GenerateTokenPair(claims.UserID)
}

// ValidateAccessToken validates an access token and returns the claims
func (s *JWTService) ValidateAccessToken(tokenString string) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		return s.accessSecret, nil
	})

	if err != nil {
		return nil, fmt.Errorf("invalid access token: %w", err)
	}

	claims, ok := token.Claims.(*CustomClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	// Verify this is an access token
	if claims.TokenType != AccessToken {
		return nil, errors.New("token is not an access token")
	}

	return claims, nil
}

// generateToken creates a signed JWT token
func (s *JWTService) generateToken(userID string, tokenType TokenType, expiry time.Time) (string, error) {
	// Add a unique jitter to the token ID to prevent token reuse
	jitter, err := generateRandomString(16)
	if err != nil {
		return "", fmt.Errorf("failed to generate jitter: %w", err)
	}

	claims := &CustomClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiry),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "ptchampion",
			Subject:   userID,
			ID:        jitter,
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

// generateRandomString creates a random string for use in token IDs
func generateRandomString(length int) (string, error) {
	b := make([]byte, length)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b)[:length], nil
}
