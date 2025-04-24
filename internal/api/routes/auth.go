// File may not exist, I'll create it with a complete JWT refresh token implementation
package routes

import (
	"context"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
)

// LoginRequest represents the login request structure
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// RegisterRequest represents the registration request structure
type RegisterRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required"`
	LastName  string `json:"last_name" validate:"required"`
}

// RefreshTokenRequest represents the request structure for token refresh
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// TokenResponse represents the token response structure
type TokenResponse struct {
	AccessToken           string    `json:"access_token"`
	RefreshToken          string    `json:"refresh_token"`
	AccessTokenExpiresAt  time.Time `json:"access_token_expires_at"`
	RefreshTokenExpiresAt time.Time `json:"refresh_token_expires_at"`
	TokenType             string    `json:"token_type"`
}

// AuthHandler manages authentication related endpoints
type AuthHandler struct {
	config       *config.Config
	logger       logging.Logger
	tokenService *auth.TokenService
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(cfg *config.Config, logger logging.Logger, tokenService *auth.TokenService) *AuthHandler {
	return &AuthHandler{
		config:       cfg,
		logger:       logger,
		tokenService: tokenService,
	}
}

// Login handles user login
func (h *AuthHandler) Login(c echo.Context) error {
	// Parse request
	req := new(LoginRequest)
	if err := c.Bind(req); err != nil {
		h.logger.Error("Failed to bind login request", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request format")
	}

	// TODO: Validate credentials against database
	// For now, using a mock user ID since we're not connecting to the database yet
	mockUserID := "user-123"

	// Generate token pair
	ctx := context.Background()
	tokenPair, err := h.tokenService.GenerateTokenPair(ctx, mockUserID)
	if err != nil {
		h.logger.Error("Failed to generate token pair", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate authentication tokens")
	}

	// Return tokens
	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:           tokenPair.AccessToken,
		RefreshToken:          tokenPair.RefreshToken,
		AccessTokenExpiresAt:  tokenPair.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: tokenPair.RefreshTokenExpiresAt,
		TokenType:             "Bearer",
	})
}

// Register handles user registration
func (h *AuthHandler) Register(c echo.Context) error {
	// Parse request
	req := new(RegisterRequest)
	if err := c.Bind(req); err != nil {
		h.logger.Error("Failed to bind registration request", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request format")
	}

	// TODO: Create user in database
	// For now, using a mock user ID since we're not connecting to the database yet
	mockUserID := "user-123"

	// Generate token pair
	ctx := context.Background()
	tokenPair, err := h.tokenService.GenerateTokenPair(ctx, mockUserID)
	if err != nil {
		h.logger.Error("Failed to generate token pair", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate authentication tokens")
	}

	// Return tokens
	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:           tokenPair.AccessToken,
		RefreshToken:          tokenPair.RefreshToken,
		AccessTokenExpiresAt:  tokenPair.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: tokenPair.RefreshTokenExpiresAt,
		TokenType:             "Bearer",
	})
}

// RefreshToken handles token refresh
func (h *AuthHandler) RefreshToken(c echo.Context) error {
	// Parse request
	req := new(RefreshTokenRequest)
	if err := c.Bind(req); err != nil {
		h.logger.Error("Failed to bind refresh token request", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request format")
	}

	// Refresh tokens
	ctx := context.Background()
	tokenPair, err := h.tokenService.RefreshTokens(ctx, req.RefreshToken)
	if err != nil {
		h.logger.Error("Failed to refresh tokens", err)
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired refresh token")
	}

	// Return new tokens
	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:           tokenPair.AccessToken,
		RefreshToken:          tokenPair.RefreshToken,
		AccessTokenExpiresAt:  tokenPair.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: tokenPair.RefreshTokenExpiresAt,
		TokenType:             "Bearer",
	})
}

// RegisterAuthRoutes registers all authentication related routes
func RegisterAuthRoutes(e *echo.Echo, cfg *config.Config, tokenService *auth.TokenService, logger logging.Logger) {
	handler := NewAuthHandler(cfg, logger, tokenService)

	// Public auth endpoints (no auth required)
	authGroup := e.Group("/api/v1/auth")
	authGroup.POST("/login", handler.Login)
	authGroup.POST("/register", handler.Register)
	authGroup.POST("/refresh", handler.RefreshToken)
}
