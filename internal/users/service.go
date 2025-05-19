package users

import (
	"context"
	"fmt"
	"regexp" // Added for email validation

	"ptchampion/internal/logging"
	"ptchampion/internal/store" // Using the store interface and model

	"github.com/lib/pq" // Added for pq.Error type assertion
)

// UpdateUserProfileRequest defines the data needed to update a user profile in the service layer.
// We define this here to decouple the service from the handler's request struct.
type UpdateUserProfileRequest struct {
	// Using pointers to distinguish between empty string and not provided
	Email     *string
	FirstName *string
	LastName  *string
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
	updated := false
	if req.Email != nil && *req.Email != currentUser.Email {
		// Validate email format
		// A more comprehensive regex could be used, but this is a basic check.
		// Consider a dedicated validation package/library for more robust validation.
		if !isValidEmailFormat(*req.Email) {
			s.logger.Warn(ctx, "Invalid email format provided for update", "userID", userID, "email", *req.Email)
			return nil, fmt.Errorf("invalid email format: %w", store.ErrEmailTaken) // Or a more specific validation error
		}

		// Check for email uniqueness before attempting update
		existingUserWithNewEmail, err := s.userStore.GetUserByEmail(ctx, *req.Email)
		if err != nil && err != store.ErrUserNotFound {
			s.logger.Error(ctx, "Failed to check email uniqueness", "userID", userID, "email", *req.Email, "error", err)
			return nil, fmt.Errorf("could not verify email uniqueness: %w", err)
		}
		if err == nil && existingUserWithNewEmail != nil && existingUserWithNewEmail.ID != currentUser.ID {
			s.logger.Warn(ctx, "Email address already in use by another user", "userID", userID, "email", *req.Email)
			return nil, store.ErrEmailTaken
		}

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

	if !updated {
		s.logger.Info(ctx, "No changes detected for user profile update", "userID", userID)
		return currentUser, nil // No changes, return current user
	}

	// 3. Save the updated user model
	updatedUser, err := s.userStore.UpdateUser(ctx, currentUser)
	if err != nil {
		// Check for pq specific error for unique constraint violation
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" { // unique_violation
				s.logger.Warn(ctx, "Database unique constraint violation on user update", "userID", userID, "pgErrCode", pqErr.Code, "pgErrDetail", pqErr.Detail)
				// Determine if it's an email/username conflict if possible from Detail or ConstraintName
				// For now, assume it's email related if we got this far after our proactive check
				return nil, store.ErrEmailTaken
			}
		}
		s.logger.Error(ctx, "Failed to update user profile in store", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to save updated user profile: %w", err)
	}

	s.logger.Info(ctx, "User profile updated successfully", "userID", userID)
	return updatedUser, nil
}

// isValidEmailFormat performs a basic validation of email format.
// Note: This is a simplified regex. For production, consider a more robust library.
var emailRegex = regexp.MustCompile(`^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,4}$`)

func isValidEmailFormat(email string) bool {
	return emailRegex.MatchString(email)
}
