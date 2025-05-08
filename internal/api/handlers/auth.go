package handlers

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strings"
	"time"

	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	"ptchampion/internal/store"
	"ptchampion/internal/store/redis"

	"github.com/labstack/echo/v4"
	"github.com/lib/pq" // Added for pq.Error
)

// AuthHandler handles authentication related requests
type AuthHandler struct {
	store        store.Store
	tokenService *auth.TokenService
	config       *config.Config
	logger       logging.Logger
}

// NewAuthHandler creates a new AuthHandler
func NewAuthHandler(store store.Store, cfg *config.Config, logger logging.Logger) *AuthHandler {
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = cfg.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		// If Redis connection fails, token service cannot be initialized.
		// This is critical for auth, so log fatal.
		// In a more complex setup, NewAuthHandler might return an error.
		logger.Fatal(context.Background(), "Redis connection failed, cannot initialize TokenService for AuthHandler", err)
		// The line above will terminate the program, so the code below won't run if err != nil.
	}

	refreshStore := redis.NewRedisRefreshStore(redisClient)
	tokenService := auth.NewTokenService(cfg.JWTSecret, cfg.RefreshTokenSecret, refreshStore)

	logger.Info(context.Background(), "AuthHandler initialized successfully with TokenService.")

	return &AuthHandler{
		store:        store,
		tokenService: tokenService,
		config:       cfg,
		logger:       logger,
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
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	ExpiresAt    time.Time   `json:"expires_at"`
	User         *store.User `json:"user"`
}

// Login handles user login
func (h *AuthHandler) Login(c echo.Context) error {
	req := new(LoginRequest)
	if err := c.Bind(req); err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	ctx := c.Request().Context()
	user, err := h.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Invalid credentials")
		}
		h.logger.Error(ctx, "Error getting user by email", "error", err, "email", req.Email)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Invalid credentials")
	}

	if !auth.VerifyPassword(user.PasswordHash, req.Password) {
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Invalid credentials")
	}

	// Generate token pair
	tokenPair, err := h.tokenService.GenerateTokenPair(ctx, user.ID)
	if err != nil {
		h.logger.Error(ctx, "Failed to generate token pair", "error", err, "userID", user.ID)
		return NewAPIError(http.StatusInternalServerError, ErrCodeTokenGeneration, "Failed to generate token")
	}

	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		User:         user,
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
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	// Check if user already exists
	ctx := c.Request().Context()
	_, err := h.store.GetUserByEmail(ctx, req.Email)
	if err == nil {
		return NewAPIError(http.StatusConflict, ErrCodeConflict, "User already exists with this email")
	} else if err != sql.ErrNoRows {
		h.logger.Error(ctx, "Error checking if user exists", "error", err, "email", req.Email)
		return NewAPIError(http.StatusInternalServerError, ErrCodeDatabase, "Error checking user existence")
	}

	// Hash the password
	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to hash password")
	}

	// Create the user
	userModel := store.NewUser(req.Email, hashedPassword, req.FirstName, req.LastName)
	createdUser, err := h.store.CreateUser(ctx, userModel)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" {
				if strings.Contains(pqErr.Constraint, "users_username_key") || strings.Contains(pqErr.Constraint, "users_email_key") {
					return NewAPIError(http.StatusConflict, ErrCodeConflict, "User already exists with this email or username.")
				}
				return NewAPIError(http.StatusConflict, ErrCodeConflict, fmt.Sprintf("A user with some unique attribute already exists: %s", pqErr.Detail))
			}
			h.logger.Error(ctx, "Database error during user creation", "pq_code", pqErr.Code, "pq_message", pqErr.Message, "pq_detail", pqErr.Detail, "error", err)
			return NewAPIError(http.StatusInternalServerError, ErrCodeDatabase, "Failed to create user due to database error")
		}
		h.logger.Error(ctx, "Failed to create user", "error", err, "email", req.Email)
		return NewAPIError(http.StatusInternalServerError, ErrCodeDatabase, "Failed to create user")
	}

	// Generate token pair
	tokenPair, err := h.tokenService.GenerateTokenPair(ctx, createdUser.ID)
	if err != nil {
		h.logger.Error(ctx, "Failed to generate token pair for new user", "error", err, "userID", createdUser.ID)
		return NewAPIError(http.StatusInternalServerError, ErrCodeTokenGeneration, "Failed to generate token")
	}

	return c.JSON(http.StatusCreated, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		User:         createdUser,
	})
}

// RefreshToken handles token refresh
func (h *AuthHandler) RefreshToken(c echo.Context) error {
	req := new(RefreshRequest)
	if err := c.Bind(req); err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	// Validate and refresh the token
	requestCtx := c.Request().Context()
	tokenPair, userID, err := h.tokenService.RefreshTokens(requestCtx, req.RefreshToken)
	if err != nil {
		h.logger.Error(requestCtx, "Failed to connect to token store (Redis) in RefreshToken", "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to connect to token store")
	}

	// Fetch the full user details using the userID returned by RefreshTokens
	refreshedUser, err := h.store.GetUserByID(requestCtx, userID)
	if err != nil {
		h.logger.Error(requestCtx, "Failed to fetch user details after token refresh", "error", err, "userID", userID)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Could not retrieve user details after refresh")
	}

	return c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.AccessTokenExpiresAt,
		User:         refreshedUser,
	})
}
