package handlers

import (
	"errors" // For checking store.ErrUserNotFound
	"fmt"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/logging"
	"ptchampion/internal/store" // For store.User and store.ErrUserNotFound
	"ptchampion/internal/users" // Import the new users service package
)

// UserResponse defines the user data returned (excluding password)
// Kept similar to before, mapping from store.User
type UserResponse struct {
	ID          string    `json:"id"`            // Changed to string to match store.User.ID
	Email       string    `json:"email"`         // Changed from Username
	Username    string    `json:"username"`      // Add username field
	FirstName   string    `json:"first_name"`    // Added
	LastName    string    `json:"last_name"`     // Added
	Gender      string    `json:"gender"`        // 'male' or 'female'
	DateOfBirth time.Time `json:"date_of_birth"` // For age calculation
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// UpdateCurrentUserRequest defines the allowed fields for updating a user profile via the API
// This remains the handler's input validation structure.
type UpdateCurrentUserRequest struct {
	Email       *string `json:"email,omitempty" validate:"omitempty,email"`
	FirstName   *string `json:"first_name,omitempty" validate:"omitempty,required"`
	LastName    *string `json:"last_name,omitempty" validate:"omitempty,required"`
	Gender      *string `json:"gender,omitempty" validate:"omitempty,oneof=male female"`
	DateOfBirth *string `json:"date_of_birth,omitempty" validate:"omitempty"` // Format: YYYY-MM-DD
	// Note: DisplayName is not directly settable via store.User, derived from First/Last Name
	// Note: Password changes handled separately
}

// UpdateLocationRequest defines the request structure for updating user location
type UpdateLocationRequest struct {
	Latitude  float64 `json:"latitude" validate:"required,min=-90,max=90"`
	Longitude float64 `json:"longitude" validate:"required,min=-180,max=180"`
}

// mapStoreUserToUserResponse converts the service/store user model to the API response model.
func mapStoreUserToUserResponse(user *store.User) UserResponse {
	return UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		Username:    user.Username,
		FirstName:   user.FirstName,
		LastName:    user.LastName,
		Gender:      user.Gender,
		DateOfBirth: user.DateOfBirth,
		CreatedAt:   user.CreatedAt,
		UpdatedAt:   user.UpdatedAt,
	}
}

// --- New User Handler ---

// UserHandler handles user-related API requests.
type UserHandler struct {
	service         users.Service
	locationService *users.LocationService
	logger          logging.Logger
}

// NewUserHandler creates a new UserHandler instance.
func NewUserHandler(service users.Service, locationService *users.LocationService, logger logging.Logger) *UserHandler {
	return &UserHandler{
		service:         service,
		locationService: locationService,
		logger:          logger,
	}
}

// GetCurrentUser handles requests to get the authenticated user's profile
// Method is now on *UserHandler
func (h *UserHandler) GetCurrentUser(c echo.Context) error {
	ctx := c.Request().Context()
	h.logger.Debug(ctx, "GetCurrentUser handler called")

	// 1. Get User ID from context (using the helper)
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user_id from context in GetCurrentUser", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication required: User ID not found")
	}

	// Convert int32 userID from context to string for service layer (if needed - check service method)
	// Assuming service layer GetUserProfile expects the string ID consistent with store.User.ID
	// NOTE: This relies on GetUserIDFromContext returning the ID compatible with store.User.ID format.
	// The previous implementation used int32 from context. Need to reconcile this.
	// For now, assume GetUserIDFromContext still returns int32 and service expects string.
	// Let's assume GetUserIDFromContext still returns int32 and service expects string.
	userIDStr := fmt.Sprintf("%d", userID)
	h.logger.Debug(ctx, "Found user_id", "userID", userIDStr)

	// 2. Call the user service to get the profile
	user, err := h.service.GetUserProfile(ctx, userIDStr)
	if err != nil {
		if errors.Is(err, store.ErrUserNotFound) {
			return NewAPIError(http.StatusNotFound, ErrCodeNotFound, "User not found")
		}
		// Log already happened in service layer
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve user profile")
	}

	h.logger.Debug(ctx, "Successfully retrieved user profile from service", "userID", user.ID)

	// 3. Map to response format
	resp := mapStoreUserToUserResponse(user)

	// 4. Send response
	return c.JSON(http.StatusOK, resp)
}

// UpdateCurrentUser handles requests to update the authenticated user's profile
// Method is now on *UserHandler
func (h *UserHandler) UpdateCurrentUser(c echo.Context) error {
	ctx := c.Request().Context()
	// 1. Get User ID from context
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication error: User ID not found")
	}
	userIDStr := fmt.Sprintf("%d", userID) // Convert to string for service

	// 2. Decode and validate request body
	var req UpdateCurrentUserRequest
	if err := c.Bind(&req); err != nil {
		h.logger.Error(ctx, "Failed to decode update user request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}
	if err := c.Validate(&req); err != nil { // Use pointer for validation
		h.logger.Warn(ctx, "Invalid update user request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	// 3. Map handler request to service request
	serviceReq := &users.UpdateUserProfileRequest{
		Email:       req.Email,
		FirstName:   req.FirstName,
		LastName:    req.LastName,
		Gender:      req.Gender,
		DateOfBirth: req.DateOfBirth,
	}

	// 4. Call the user service to update the profile
	updatedUser, err := h.service.UpdateUserProfile(ctx, userIDStr, serviceReq)
	if err != nil {
		if errors.Is(err, store.ErrUserNotFound) {
			return NewAPIError(http.StatusNotFound, ErrCodeNotFound, "User not found")
		}
		if errors.Is(err, store.ErrEmailTaken) { // Check for the specific email taken/validation error
			h.logger.Warn(ctx, "Failed to update user profile due to email issue", "userID", userIDStr, "error", err)
			// Use HTTP 409 Conflict for email already in use, or HTTP 400 for general validation if preferred.
			return NewAPIError(http.StatusConflict, ErrCodeConflict, err.Error()) // Pass service error message directly
		}
		// Log already happened in service layer for other generic errors
		h.logger.Error(ctx, "Unhandled error from UpdateUserProfile service", "userID", userIDStr, "error", err) // Log it here too for handler context
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to update user profile")
	}

	// 5. Map result to response
	resp := mapStoreUserToUserResponse(updatedUser)

	// 6. Send response
	return c.JSON(http.StatusOK, resp)
}

// UpdateLocation handles requests to update the authenticated user's location
func (h *UserHandler) UpdateLocation(c echo.Context) error {
	ctx := c.Request().Context()
	h.logger.Debug(ctx, "UpdateLocation handler called")

	// 1. Get User ID from context
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context in UpdateLocation", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication required: User ID not found")
	}

	h.logger.Debug(ctx, "Found user_id for location update", "userID", userID)

	// 2. Decode and validate request body
	var req UpdateLocationRequest
	if err := c.Bind(&req); err != nil {
		h.logger.Error(ctx, "Failed to decode update location request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	if err := c.Validate(&req); err != nil {
		h.logger.Warn(ctx, "Invalid update location request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	h.logger.Debug(ctx, "Updating user location", "userID", userID, "lat", req.Latitude, "lng", req.Longitude)

	// 3. Call the location service to update the user's location
	if err := h.locationService.UpdateUserLocation(
		ctx,
		userID,
		req.Latitude,
		req.Longitude,
	); err != nil {
		h.logger.Error(ctx, "Failed to update user location", "userID", userID, "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, err.Error())
	}

	h.logger.Info(ctx, "User location updated successfully", "userID", userID)

	// 4. Return success response
	return c.JSON(http.StatusOK, map[string]string{
		"message": "Location updated successfully",
	})
}
