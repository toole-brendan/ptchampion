// File may not exist, I'll create it with a complete JWT refresh token implementation
package routes

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
)

// RefreshTokenRequest represents the request structure for token refresh
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// TokenResponse represents the token refresh response
type TokenResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	TokenType    string    `json:"token_type"`
}

// AuthHandler manages authentication related endpoints
type AuthHandler struct {
	jwtService *auth.JWTService
	config     *config.Config
	logger     logging.Logger
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(cfg *config.Config, logger logging.Logger) *AuthHandler {
	// Initialize JWTService with access and refresh token configuration
	jwtService := auth.NewJWTService(
		cfg.JWTSecret,
		cfg.RefreshTokenSecret,
		15*time.Minute, // Access token TTL (15 min)
		7*24*time.Hour, // Refresh token TTL (7 days)
	)

	return &AuthHandler{
		jwtService: jwtService,
		config:     cfg,
		logger:     logger,
	}
}

// RefreshToken handles JWT token refresh requests
// Validates a refresh token and issues a new pair of tokens
func (h *AuthHandler) RefreshToken(c echo.Context) error {
	// Bind and validate request
	req := new(RefreshTokenRequest)
	if err := c.Bind(req); err != nil {
		h.logger.Error("Failed to bind refresh token request", zap.Error(err))
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request format")
	}

	if err := c.Validate(req); err != nil {
		h.logger.Error("Invalid refresh token request", zap.Error(err))
		return echo.NewHTTPError(http.StatusBadRequest, "Refresh token is required")
	}

	// Validate and refresh tokens
	tokenPair, err := h.jwtService.RefreshTokens(req.RefreshToken)
	if err != nil {
		h.logger.Warn("Refresh token validation failed",
			zap.Error(err),
			zap.String("remote_ip", c.RealIP()),
		)
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired refresh token")
	}

	// Log successful token refresh
	h.logger.Info("Tokens refreshed successfully",
		zap.String("subject", tokenPair.AccessToken),
		zap.Time("expires_at", tokenPair.AccessTokenExpiresAt),
	)

	// Return new token pair
	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		TokenType:    "Bearer",
	})
}

// RegisterAuthRoutes registers all authentication related routes
func RegisterAuthRoutes(e *echo.Echo, cfg *config.Config, logger logging.Logger) {
	handler := NewAuthHandler(cfg, logger)

	// Public auth endpoints (no auth required)
	authGroup := e.Group("/api/v1/auth")

	// Register the refresh token endpoint
	authGroup.POST("/refresh", handler.RefreshToken)

	// Other auth endpoints would also be registered here:
	// authGroup.POST("/login", handler.Login)
	// authGroup.POST("/register", handler.Register)
}
