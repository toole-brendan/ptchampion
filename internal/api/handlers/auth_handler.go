package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"ptchampion/internal/auth"
	dbStore "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"

	"github.com/labstack/echo/v4"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// Define request/response structs within handlers package if needed,
// mirroring the structure of the generated api types but without depending on api package.

type RegisterUserPayload struct {
	Username          string  `json:"username"`
	Password          string  `json:"password"`
	DisplayName       *string `json:"displayName"`
	ProfilePictureUrl *string `json:"profilePictureUrl"`
	Location          *string `json:"location"`
	Latitude          *string `json:"latitude"`
	Longitude         *string `json:"longitude"`
}

type LoginPayload struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type UserResponsePayload struct { // Renamed to avoid conflict if api types were used
	Id                int     `json:"id"`
	Username          string  `json:"username"`
	DisplayName       *string `json:"displayName"`
	ProfilePictureUrl *string `json:"profilePictureUrl"`
	Location          *string `json:"location"`
	Latitude          *string `json:"latitude"`
	Longitude         *string `json:"longitude"`
	LastSyncedAt      *string `json:"lastSyncedAt"` // RFC3339 string
	CreatedAt         *string `json:"createdAt"`    // RFC3339 string
	UpdatedAt         *string `json:"updatedAt"`    // RFC3339 string
}

type LoginResponsePayload struct {
	AccessToken  string              `json:"access_token"`
	RefreshToken string              `json:"refresh_token"`
	ExpiresIn    int                 `json:"expires_in"`
	User         UserResponsePayload `json:"user"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// PostAuthRegister is a method on handlers.Handler
func (h *Handler) PostAuthRegister(c echo.Context) error {
	r := c.Request()

	var req RegisterUserPayload
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode registration request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// Add validation
	if req.Username == "" || req.Password == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Username and password are required")
	}

	// Check if h.Queries is nil
	if h.Queries == nil {
		log.Printf("ERROR: Database queries not initialized")
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("ERROR: Failed to hash password: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}

	// Prepare user data for database insertion - ONLY fields defined in CreateUserParams
	params := dbStore.CreateUserParams{
		Username:     req.Username,
		PasswordHash: string(hashedPassword), // Make sure field name matches DB schema
		DisplayName: sql.NullString{
			String: DerefString(req.DisplayName),
			Valid:  req.DisplayName != nil,
		},
	}

	// Wrap database call in a transaction for better error handling
	user, err := h.Queries.CreateUser(r.Context(), params)
	if err != nil {
		log.Printf("ERROR: Failed to create user: %v", err)
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" && strings.Contains(pqErr.Constraint, "users_username_key") {
				return echo.NewHTTPError(http.StatusConflict, "Username already exists")
			} else if pqErr.Code == "23502" { // not-null constraint violation
				return echo.NewHTTPError(http.StatusBadRequest, "Required field missing")
			} else if pqErr.Code == "42P01" { // undefined_table
				return echo.NewHTTPError(http.StatusInternalServerError, "Database setup incomplete")
			}
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to register user")
	}

	// Convert dbStore.User to internal response payload
	resp := UserResponsePayload{
		Id:                int(user.ID),
		Username:          user.Username,
		DisplayName:       NullStringToStringPtr(user.DisplayName), // Use helper from this package
		ProfilePictureUrl: NullStringToStringPtr(user.ProfilePictureUrl),
		Location:          NullStringToStringPtr(user.Location),
		Latitude:          NullStringToStringPtr(user.Latitude),
		Longitude:         NullStringToStringPtr(user.Longitude),
		LastSyncedAt:      NullTimeToRFC3339StringPtr(user.LastSyncedAt), // Use helper from this package
		CreatedAt:         NullTimeToRFC3339StringPtr(user.CreatedAt),
		UpdatedAt:         NullTimeToRFC3339StringPtr(user.UpdatedAt),
	}

	return c.JSON(http.StatusCreated, resp)
}

// PostAuthLogin is a method on handlers.Handler
func (h *Handler) PostAuthLogin(c echo.Context) error {
	// w := c.Response().Writer // Keep w for potential future use
	r := c.Request()

	var req LoginPayload // Use internal payload struct
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode login request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// TODO: Re-implement validation

	user, err := h.Queries.GetUserByUsername(r.Context(), req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			return echo.NewHTTPError(http.StatusUnauthorized, "Invalid username or password")
		} else {
			log.Printf("ERROR: Failed to get user by username '%s': %v", req.Username, err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
		}
	}

	// Compare the provided password with the stored hash
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		log.Printf("WARN: Password comparison failed for user %s: %v", req.Username, err)
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid username or password")
	}

	// Create token service with Redis store
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = h.Config.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		log.Printf("ERROR: Failed to connect to Redis: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}
	refreshStore := redis.NewRedisRefreshStore(redisClient)
	tokenService := auth.NewTokenService(h.Config.JWTSecret, h.Config.RefreshTokenSecret, refreshStore)

	// Generate token pair
	userIDString := fmt.Sprintf("%d", user.ID)
	log.Printf("DEBUG: Login - Generated user ID string: '%s' for user: %s (ID: %d)", userIDString, user.Username, user.ID)

	tokenPair, err := tokenService.GenerateTokenPair(c.Request().Context(), userIDString)
	if err != nil {
		log.Printf("ERROR: Failed to generate token pair: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}

	log.Printf("DEBUG: Login - Token pair generated successfully: access_token length=%d, refresh_token length=%d",
		len(tokenPair.AccessToken), len(tokenPair.RefreshToken))
	log.Printf("DEBUG: Login - Access token preview: %s...", tokenPair.AccessToken[:20])

	// For debugging purposes, parse the token we just created
	claims, err := tokenService.ValidateAccessToken(tokenPair.AccessToken)
	if err != nil {
		log.Printf("ERROR: Generated token failed self-validation: %v", err)
	} else {
		log.Printf("DEBUG: Generated token validation SUCCESS - claims: user_id=%s, token_type=%s",
			claims.UserID, claims.TokenType)
	}

	// Convert dbStore.User to internal response payload
	userResp := UserResponsePayload{
		Id:                int(user.ID),
		Username:          user.Username,
		DisplayName:       NullStringToStringPtr(user.DisplayName),
		ProfilePictureUrl: NullStringToStringPtr(user.ProfilePictureUrl),
		Location:          NullStringToStringPtr(user.Location),
		Latitude:          NullStringToStringPtr(user.Latitude),
		Longitude:         NullStringToStringPtr(user.Longitude),
		LastSyncedAt:      NullTimeToRFC3339StringPtr(user.LastSyncedAt),
		CreatedAt:         NullTimeToRFC3339StringPtr(user.CreatedAt),
		UpdatedAt:         NullTimeToRFC3339StringPtr(user.UpdatedAt),
	}

	// Use internal response payload
	loginResp := LoginResponsePayload{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    int(tokenPair.AccessTokenExpiresAt.Sub(time.Now()).Seconds()),
		User:         userResp,
	}

	return c.JSON(http.StatusOK, loginResp)
}

// PostAuthRefresh handles token refresh requests
func (h *Handler) PostAuthRefresh(c echo.Context) error {
	r := c.Request()

	var req RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode refresh token request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	if req.RefreshToken == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Refresh token is required")
	}

	// Create token service with Redis store
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = h.Config.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		log.Printf("ERROR: Failed to connect to Redis: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}
	refreshStore := redis.NewRedisRefreshStore(redisClient)
	tokenService := auth.NewTokenService(h.Config.JWTSecret, h.Config.RefreshTokenSecret, refreshStore)

	// Refresh the token
	tokenPair, err := tokenService.RefreshTokens(c.Request().Context(), req.RefreshToken)
	if err != nil {
		log.Printf("ERROR: Failed to refresh token: %v", err)
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired refresh token")
	}

	// Return the new tokens
	refreshResp := struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresIn    int    `json:"expires_in"`
	}{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    int(tokenPair.AccessTokenExpiresAt.Sub(time.Now()).Seconds()),
	}

	return c.JSON(http.StatusOK, refreshResp)
}

// REMOVED Stubs
/*
func (h *Handler) GetExercises(...) error { ... }
func (h *Handler) PostExercises(...) error { ... }
func (h *Handler) GetLeaderboardExerciseType(...) error { ... }
func (h *Handler) PostSync(...) error { ... }
func (h *Handler) PatchUsersMe(...) error { ... }
*/
