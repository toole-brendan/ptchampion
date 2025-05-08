package users

import (
	"context"
	"fmt"

	"ptchampion/internal/logging"
	"ptchampion/internal/store" // Using the store interface and model
)

// UpdateUserProfileRequest defines the data needed to update a user profile in the service layer.
// We define this here to decouple the service from the handler's request struct.
type UpdateUserProfileRequest struct {
	// Using pointers to distinguish between empty string and not provided
	Email       *string
	FirstName   *string
	LastName    *string
	DisplayName *string // Explicit display name if provided
	AvatarURL   *string
	// Password updates should be handled by a separate dedicated method/service if needed
}

// Service defines the interface for user-related business logic.
type Service interface {
	GetUserProfile(ctx context.Context, userID string) (*store.User, error)
	UpdateUserProfile(ctx context.Context, userID string, req *UpdateUserProfileRequest) (*store.User, error)
}

// service implements the Service interface.
type service struct {
	userStore store.UserStore // Depend on the UserStore part of the store interface
	logger    logging.Logger
}

// NewUserService creates a new UserService with the given dependencies.
// It uses a concrete *db.Store assuming it fulfills the store.UserStore interface.
func NewUserService(userStore store.UserStore, logger logging.Logger) Service {
	return &service{
		userStore: userStore,
		logger:    logger,
	}
}

// GetUserProfile retrieves a user's profile by their ID.
func (s *service) GetUserProfile(ctx context.Context, userID string) (*store.User, error) {
	user, err := s.userStore.GetUserByID(ctx, userID)
	if err != nil {
		if err == store.ErrUserNotFound {
			// Log and return the specific error type
			s.logger.Warn(ctx, "User profile not found", "userID", userID)
			return nil, err // Return the sentinel error
		}
		s.logger.Error(ctx, "Failed to get user profile from store", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to retrieve user profile") // Return generic error
	}
	return user, nil
}

// UpdateUserProfile updates a user's profile.
func (s *service) UpdateUserProfile(ctx context.Context, userID string, req *UpdateUserProfileRequest) (*store.User, error) {
	// 1. Get the existing user
	currentUser, err := s.userStore.GetUserByID(ctx, userID)
	if err != nil {
		if err == store.ErrUserNotFound {
			s.logger.Warn(ctx, "Attempted to update non-existent user", "userID", userID)
			return nil, err // User not found
		}
		s.logger.Error(ctx, "Failed to get user for update", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to retrieve user for update")
	}

	// 2. Apply changes from the request to the user model
	// Note: store.User uses Email, FirstName, LastName, AvatarURL
	// The underlying postgres store uses Username, DisplayName, ProfilePictureUrl
	// The store implementation handles the mapping. We update the store.User model here.

	updated := false
	if req.Email != nil && *req.Email != currentUser.Email {
		// TODO: Validate email format? Check for uniqueness? (May belong in handler or deeper validation)
		// For now, assume store handles unique constraints on save.
		currentUser.Email = *req.Email
		updated = true
		s.logger.Debug(ctx, "Updating user email", "userID", userID)
	}
	if req.FirstName != nil && *req.FirstName != currentUser.FirstName {
		currentUser.FirstName = *req.FirstName
		updated = true
		s.logger.Debug(ctx, "Updating user first name", "userID", userID)
	}
	if req.LastName != nil && *req.LastName != currentUser.LastName {
		currentUser.LastName = *req.LastName
		updated = true
		s.logger.Debug(ctx, "Updating user last name", "userID", userID)
	}
	if req.AvatarURL != nil {
		// Handle pointer comparison correctly
		if currentUser.AvatarURL == nil || *req.AvatarURL != *currentUser.AvatarURL {
			currentUser.AvatarURL = req.AvatarURL // Assign the pointer directly
			updated = true
			s.logger.Debug(ctx, "Updating user avatar URL", "userID", userID)
		}
	}

	// Note: DisplayName is not directly on store.User, store implementation derives it.
	// If req.DisplayName was provided, the store implementation might need to handle it.
	// PasswordHash is also not updated here.

	if !updated {
		s.logger.Info(ctx, "No changes detected for user profile update", "userID", userID)
		return currentUser, nil // No changes, return current user
	}

	// 3. Save the updated user model
	updatedUser, err := s.userStore.UpdateUser(ctx, currentUser)
	if err != nil {
		// TODO: Handle potential unique constraint errors (e.g., duplicate email/username) more specifically
		// if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" { ... }
		s.logger.Error(ctx, "Failed to update user profile in store", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to save updated user profile")
	}

	s.logger.Info(ctx, "User profile updated successfully", "userID", userID)
	return updatedUser, nil
}
