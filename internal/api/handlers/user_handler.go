package handlers

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	dbStore "ptchampion/internal/store/postgres"

	"github.com/labstack/echo/v4"
	"github.com/lib/pq"
)

// UserResponse defines the user data returned (excluding password)
type UserResponse struct {
	ID                int32     `json:"id"`
	Username          string    `json:"username"`
	DisplayName       string    `json:"display_name,omitempty"`
	ProfilePictureURL string    `json:"profile_picture_url,omitempty"`
	Location          string    `json:"location,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// UpdateUserRequest defines the allowed fields for updating a user profile
type UpdateUserRequest struct {
	Username          *string  `json:"username,omitempty" validate:"omitempty,alphanum,min=3,max=30"` // Validate if present
	DisplayName       *string  `json:"display_name,omitempty" validate:"omitempty,max=100"`           // Validate if present (max length)
	ProfilePictureURL *string  `json:"profile_picture_url,omitempty" validate:"omitempty,url"`        // Validate if present (is URL)
	Location          *string  `json:"location,omitempty" validate:"omitempty,max=100"`               // Validate if present (max length)
	Latitude          *float64 `json:"latitude,omitempty" validate:"omitempty,latitude"`              // Validate if present (latitude format)
	Longitude         *float64 `json:"longitude,omitempty" validate:"omitempty,longitude"`            // Validate if present (longitude format)
	// Password changes should likely be handled via a separate endpoint
}

// UpdateCurrentUser handles requests to update the authenticated user's profile
func (h *Handler) UpdateCurrentUser(c echo.Context) error {
	// 1. Get User ID from context
	userID, ok := c.Get("user_id").(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		return echo.NewHTTPError(http.StatusInternalServerError, "Authentication error")
	}

	// 2. Decode request body
	var req UpdateUserRequest
	if err := c.Bind(&req); err != nil {
		log.Printf("ERROR: Failed to decode update user request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// Validate the request struct
	if err := c.Validate(req); err != nil {
		log.Printf("INFO: Invalid update user request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// 3. Prepare parameters for DB update
	// Need to convert *float64 to sql.NullString for latitude/longitude if they are provided
	var latStr, lonStr sql.NullString
	if req.Latitude != nil {
		latStr = sql.NullString{String: fmt.Sprintf("%f", *req.Latitude), Valid: true}
	}
	if req.Longitude != nil {
		lonStr = sql.NullString{String: fmt.Sprintf("%f", *req.Longitude), Valid: true}
	}

	params := dbStore.UpdateUserParams{
		ID: userID,
		// Username is handled below
		DisplayName:       stringPtrToNullString(req.DisplayName),
		ProfilePictureUrl: stringPtrToNullString(req.ProfilePictureURL),
		Location:          stringPtrToNullString(req.Location),
		Latitude:          latStr,
		Longitude:         lonStr,
	}
	// Only include Username in params if it's provided in the request
	if req.Username != nil {
		params.Username = *req.Username
	} else {
		// We need to pass the existing username for COALESCE to work correctly if not updating.
		// Fetch current user data first, or adjust query/params handling.
		// For simplicity now, let's fetch the current user data first.
		currentUser, err := h.Queries.GetUser(c.Request().Context(), userID)
		if err != nil {
			log.Printf("ERROR: Failed to get current user %d for update: %v", userID, err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update profile")
		}
		params.Username = currentUser.Username // Use current username
	}

	// 4. Update user in database
	updatedUser, err := h.Queries.UpdateUser(c.Request().Context(), params)
	if err != nil {
		// Check for unique constraint violation (duplicate username if username was updated)
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			log.Printf("INFO: Attempt to update to duplicate username: %s by user ID %d", params.Username, userID)
			// Check if the constraint is specifically on the username column
			if strings.Contains(pqErr.Constraint, "users_username_key") { // Adjust constraint name if different
				return echo.NewHTTPError(http.StatusConflict, "Username already taken") // 409 Conflict
			}
		}
		// Handle other errors
		log.Printf("ERROR: Failed to update user %d: %v", userID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to update profile")
	}

	// 5. Prepare response (similar to RegisterUser response)
	resp := UserResponse{
		ID:                updatedUser.ID,
		Username:          updatedUser.Username,
		DisplayName:       getNullString(updatedUser.DisplayName),
		ProfilePictureURL: getNullString(updatedUser.ProfilePictureUrl),
		Location:          getNullString(updatedUser.Location),
		CreatedAt:         getNullTime(updatedUser.CreatedAt),
		UpdatedAt:         getNullTime(updatedUser.UpdatedAt),
	}

	// 6. Send response
	return c.JSON(http.StatusOK, resp)
}
