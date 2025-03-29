package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	customMiddleware "ptchampion/internal/api/middleware"
	"ptchampion/internal/api/utils"
	dbStore "ptchampion/internal/store/postgres"

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
func (h *Handler) UpdateCurrentUser(w http.ResponseWriter, r *http.Request) {
	// 1. Get User ID from context
	userID, ok := r.Context().Value(customMiddleware.UserIDContextKey).(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		http.Error(w, "Authentication error", http.StatusInternalServerError)
		return
	}

	// 2. Decode request body
	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode update user request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request struct using the shared validator
	if err := utils.Validate.Struct(req); err != nil {
		log.Printf("INFO: Invalid update user request: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		if encodeErr := json.NewEncoder(w).Encode(utils.ValidationErrorResponse(err)); encodeErr != nil {
			log.Printf("ERROR: Failed to encode validation error response: %v", encodeErr)
		}
		return
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
		currentUser, err := h.Queries.GetUser(r.Context(), userID)
		if err != nil {
			log.Printf("ERROR: Failed to get current user %d for update: %v", userID, err)
			http.Error(w, "Failed to update profile", http.StatusInternalServerError)
			return
		}
		params.Username = currentUser.Username // Use current username
	}

	// 4. Update user in database
	updatedUser, err := h.Queries.UpdateUser(r.Context(), params)
	if err != nil {
		// Check for unique constraint violation (duplicate username if username was updated)
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			log.Printf("INFO: Attempt to update to duplicate username: %s by user ID %d", params.Username, userID)
			// Check if the constraint is specifically on the username column
			if strings.Contains(pqErr.Constraint, "users_username_key") { // Adjust constraint name if different
				http.Error(w, "Username already taken", http.StatusConflict) // 409 Conflict
				return
			}
		}
		// Handle other errors
		log.Printf("ERROR: Failed to update user %d: %v", userID, err)
		http.Error(w, "Failed to update profile", http.StatusInternalServerError)
		return
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
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("ERROR: Failed to encode update user response: %v", err)
	}
}
