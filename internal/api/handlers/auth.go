package handlers

import (
	"net/http"
	"time"

	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/store"

	"github.com/labstack/echo/v4"
)

// AuthHandler handles authentication related requests
type AuthHandler struct {
	store      store.Store
	jwtService *auth.JWTService
}

// NewAuthHandler creates a new AuthHandler
func NewAuthHandler(store store.Store, cfg *config.Config) *AuthHandler {
	// Access token TTL 15m, refresh token TTL 7d (adjust via config later)
	accessTTL := 15 * time.Minute
	refreshTTL := 7 * 24 * time.Hour

	jwtSvc := auth.NewJWTService(cfg.JWTSecret, cfg.RefreshTokenSecret, accessTTL, refreshTTL)

	return &AuthHandler{
		store:      store,
		jwtService: jwtSvc,
	}
}

// LoginRequest represents a login request body
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// AuthResponse represents an authentication response
type AuthResponse struct {
	User         *store.User `json:"user"`
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	ExpiresAt    time.Time   `json:"expires_at"`
}

// RefreshRequest represents a token refresh request
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// TokenResponse represents the token response
type TokenResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	UserID       string    `json:"user_id"`
}

// Login handles user login
func (h *AuthHandler) Login(c echo.Context) error {
	req := new(LoginRequest)
	if err := c.Bind(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	user, err := h.store.GetUserByEmail(c.Request().Context(), req.Email)
	if err != nil || !auth.VerifyPassword(user.PasswordHash, req.Password) {
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid credentials")
	}

	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate token")
	}

	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		UserID:       user.ID,
	})
}

// RegisterRequest represents a user registration request
type RegisterRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required"`
	LastName  string `json:"last_name" validate:"required"`
}

// Register handles user registration
func (h *AuthHandler) Register(c echo.Context) error {
	req := new(RegisterRequest)
	if err := c.Bind(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// Check if user already exists
	_, err := h.store.GetUserByEmail(c.Request().Context(), req.Email)
	if err == nil {
		return echo.NewHTTPError(http.StatusConflict, "User already exists")
	}

	// Hash the password
	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
	}

	// Create the user
	userModel := store.NewUser(req.Email, hashedPassword, req.FirstName, req.LastName)
	user, err := h.store.CreateUser(c.Request().Context(), userModel)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create user")
	}

	// Generate tokens
	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate token")
	}

	return c.JSON(http.StatusCreated, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		UserID:       user.ID,
	})
}

// RefreshToken handles token refresh
func (h *AuthHandler) RefreshToken(c echo.Context) error {
	req := new(RefreshRequest)
	if err := c.Bind(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// Validate and refresh the token
	tokenPair, err := h.jwtService.RefreshTokens(req.RefreshToken)
	if err != nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid refresh token")
	}

	// Extract user ID from the validated token
	claims, err := h.jwtService.ValidateAccessToken(tokenPair.AccessToken)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to validate token")
	}

	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		UserID:       claims.UserID,
	})
}
