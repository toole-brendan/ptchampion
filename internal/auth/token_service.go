package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// Constants for token-related settings
const (
	AccessTokenDuration  = time.Minute * 15   // Short-lived token
	RefreshTokenDuration = time.Hour * 24 * 7 // 7 days
	TokenIssuer          = "ptchampion.com"
)

// Claims is our custom JWT claims structure
type Claims struct {
	UserID   int64  `json:"uid"`
	Username string `json:"usr"`
	TokenID  string `json:"tid"` // Unique ID for this token
	jwt.RegisteredClaims
}

// RefreshTokenData represents a refresh token entry
type RefreshTokenData struct {
	ID        string    `json:"id"`
	UserID    int64     `json:"user_id"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiresAt time.Time `json:"expires_at"`
	Revoked   bool      `json:"revoked"`
}

// TokenService handles JWT token operations
type TokenService struct {
	accessSecret  []byte
	refreshSecret []byte
	// In production, store active refresh tokens in Redis
	// refreshStore is a mock in-memory store for refresh tokens
	refreshStore map[string]RefreshTokenData
}

// NewTokenService creates a new TokenService instance
func NewTokenService(accessSecret, refreshSecret string) *TokenService {
	return &TokenService{
		accessSecret:  []byte(accessSecret),
		refreshSecret: []byte(refreshSecret),
		refreshStore:  make(map[string]RefreshTokenData),
	}
}

// GenerateTokenPair creates a new access and refresh token pair
func (s *TokenService) GenerateTokenPair(userID int64, username string) (accessToken, refreshToken string, err error) {
	// Generate a unique token ID
	tokenID := uuid.New().String()

	// Create access token
	accessToken, err = s.createAccessToken(userID, username, tokenID)
	if err != nil {
		return "", "", err
	}

	// Create refresh token
	refreshToken, refreshData, err := s.createRefreshToken(userID)
	if err != nil {
		return "", "", err
	}

	// Store refresh token (in production, this would be in Redis or database)
	s.refreshStore[refreshData.ID] = refreshData

	return accessToken, refreshToken, nil
}

// createAccessToken generates a JWT access token
func (s *TokenService) createAccessToken(userID int64, username, tokenID string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID:   userID,
		Username: username,
		TokenID:  tokenID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenDuration)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    TokenIssuer,
			Subject:   username,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.accessSecret)
}

// createRefreshToken generates a refresh token
func (s *TokenService) createRefreshToken(userID int64) (string, RefreshTokenData, error) {
	now := time.Now()
	refreshID := uuid.New().String()

	refreshData := RefreshTokenData{
		ID:        refreshID,
		UserID:    userID,
		IssuedAt:  now,
		ExpiresAt: now.Add(RefreshTokenDuration),
		Revoked:   false,
	}

	// Create claims for the refresh token
	claims := jwt.MapClaims{
		"tid": refreshID,
		"sub": userID,
		"iat": now.Unix(),
		"exp": refreshData.ExpiresAt.Unix(),
		"iss": TokenIssuer,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	refreshToken, err := token.SignedString(s.refreshSecret)
	if err != nil {
		return "", RefreshTokenData{}, err
	}

	return refreshToken, refreshData, nil
}

// VerifyAccessToken validates an access token
func (s *TokenService) VerifyAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return s.accessSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// RefreshAccessToken validates a refresh token and issues a new access token
func (s *TokenService) RefreshAccessToken(refreshTokenString string) (newAccessToken, newRefreshToken string, err error) {
	// Parse refresh token
	token, err := jwt.Parse(refreshTokenString, func(token *jwt.Token) (interface{}, error) {
		return s.refreshSecret, nil
	})

	if err != nil {
		return "", "", err
	}

	if !token.Valid {
		return "", "", errors.New("invalid refresh token")
	}

	// Extract claims
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", errors.New("invalid token claims")
	}

	// Validate token ID
	refreshID, ok := claims["tid"].(string)
	if !ok {
		return "", "", errors.New("invalid token ID")
	}

	// Check if token exists in store
	storedToken, exists := s.refreshStore[refreshID]
	if !exists {
		return "", "", errors.New("unknown refresh token")
	}

	// Check if token is revoked
	if storedToken.Revoked {
		return "", "", errors.New("refresh token has been revoked")
	}

	// Check expiration
	if time.Now().After(storedToken.ExpiresAt) {
		return "", "", errors.New("refresh token expired")
	}

	// Extract user ID
	userIDFloat, ok := claims["sub"].(float64)
	if !ok {
		return "", "", errors.New("invalid user ID in token")
	}
	userID := int64(userIDFloat)

	// Get username from user service/database (mocked here)
	username := "username" // In production, you'd fetch this from the user service

	// Revoke old refresh token
	s.RevokeRefreshToken(refreshID)

	// Generate new token pair
	return s.GenerateTokenPair(userID, username)
}

// RevokeRefreshToken marks a refresh token as revoked
func (s *TokenService) RevokeRefreshToken(tokenID string) error {
	token, exists := s.refreshStore[tokenID]
	if !exists {
		return errors.New("token not found")
	}

	token.Revoked = true
	s.refreshStore[tokenID] = token

	return nil
}

// RevokeAllUserTokens revokes all refresh tokens for a user
func (s *TokenService) RevokeAllUserTokens(userID int64) {
	for id, token := range s.refreshStore {
		if token.UserID == userID {
			token.Revoked = true
			s.refreshStore[id] = token
		}
	}
}
