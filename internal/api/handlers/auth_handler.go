package handlers

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	dbStore "ptchampion/internal/store/postgres"

	"github.com/golang-jwt/jwt/v5"
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
	Token string              `json:"token"`
	User  UserResponsePayload `json:"user"`
}

// PostAuthRegister is a method on handlers.Handler
func (h *Handler) PostAuthRegister(c echo.Context) error {
	// w := c.Response().Writer // Keep w for potential future use
	r := c.Request()

	var req RegisterUserPayload // Use internal payload struct
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode registration request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// TODO: Re-implement validation using the payload struct

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("ERROR: Failed to hash password: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
	}

	// Prepare user data for database insertion - ONLY fields defined in CreateUserParams
	params := dbStore.CreateUserParams{
		Username: req.Username,
		Password: string(hashedPassword),
		DisplayName: sql.NullString{
			String: DerefString(req.DisplayName), // Use helper from this package
			Valid:  req.DisplayName != nil,
		},
	}

	user, err := h.Queries.CreateUser(r.Context(), params)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			if strings.Contains(pqErr.Constraint, "users_username_key") {
				return echo.NewHTTPError(http.StatusConflict, "Username already exists")
			}
		}
		log.Printf("ERROR: Failed to create user: %v", err)
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

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Invalid username or password")
	}

	claims := jwt.MapClaims{
		"sub": user.ID,
		"usr": user.Username,
		"exp": time.Now().Add(time.Hour * 24).Unix(),
		"iat": time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.Config.JWTSecret))
	if err != nil {
		log.Printf("ERROR: Failed to sign JWT token: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Internal server error")
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
		Token: tokenString,
		User:  userResp,
	}

	return c.JSON(http.StatusOK, loginResp)
}

// REMOVED Stubs
/*
func (h *Handler) GetExercises(...) error { ... }
func (h *Handler) PostExercises(...) error { ... }
func (h *Handler) GetLeaderboardExerciseType(...) error { ... }
func (h *Handler) PostSync(...) error { ... }
func (h *Handler) PatchUsersMe(...) error { ... }
*/
