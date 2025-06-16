package users

import (
	"context"
	"fmt"
	"regexp" // Added for email validation
	"time"

	"ptchampion/internal/logging"
	"ptchampion/internal/store" // Using the store interface and model
	redis_cache "ptchampion/internal/store/redis"

	"github.com/lib/pq" // Added for pq.Error type assertion
)

// UpdateUserProfileRequest defines the data needed to update a user profile in the service layer.
// We define this here to decouple the service from the handler's request struct.
type UpdateUserProfileRequest struct {
	// Using pointers to distinguish between empty string and not provided
	Email       *string
	FirstName   *string
	LastName    *string
	Gender      *string // 'male' or 'female' for USMC PFT scoring
	DateOfBirth *string // Format: YYYY-MM-DD
	// Password updates should be handled by a separate dedicated method/service if needed
}

// Service defines the interface for user-related business logic.
type Service interface {
	GetUserProfile(ctx context.Context, userID string) (*store.User, error)
	UpdateUserProfile(ctx context.Context, userID string, req *UpdateUserProfileRequest) (*store.User, error)
	UpdatePrivacySettings(ctx context.Context, userID int32, isPublic bool) error
}

// service implements the Service interface.
type service struct {
	userStore        store.UserStore // Depend on the UserStore part of the store interface
	leaderboardCache *redis_cache.LeaderboardCache
	logger           logging.Logger
}

// NewUserService creates a new UserService with the given dependencies.
// It uses a concrete *db.Store assuming it fulfills the store.UserStore interface.
func NewUserService(userStore store.UserStore, leaderboardCache *redis_cache.LeaderboardCache, logger logging.Logger) Service {
	return &service{
		userStore:        userStore,
		leaderboardCache: leaderboardCache,
		logger:           logger,
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
	if req.Gender != nil && *req.Gender != currentUser.Gender {
		// Validate gender value
		if *req.Gender != "male" && *req.Gender != "female" {
			s.logger.Warn(ctx, "Invalid gender value provided for update", "userID", userID, "gender", *req.Gender)
			return nil, fmt.Errorf("invalid gender value: must be 'male' or 'female'")
		}
		currentUser.Gender = *req.Gender
		updated = true
		s.logger.Debug(ctx, "Updating user gender", "userID", userID)
	}
	if req.DateOfBirth != nil {
		// Parse and validate date of birth
		dob, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			s.logger.Warn(ctx, "Invalid date of birth format provided for update", "userID", userID, "dob", *req.DateOfBirth)
			return nil, fmt.Errorf("invalid date of birth format: expected YYYY-MM-DD")
		}

		// Validate date is not in the future
		if dob.After(time.Now()) {
			s.logger.Warn(ctx, "Date of birth is in the future", "userID", userID, "dob", *req.DateOfBirth)
			return nil, fmt.Errorf("date of birth cannot be in the future")
		}

		// Validate user is at least 17 years old
		age := calculateAge(dob)
		if age < 17 {
			s.logger.Warn(ctx, "User is too young", "userID", userID, "age", age)
			return nil, fmt.Errorf("user must be at least 17 years old")
		}

		if !dob.Equal(currentUser.DateOfBirth) {
			currentUser.DateOfBirth = dob
			updated = true
			s.logger.Debug(ctx, "Updating user date of birth", "userID", userID)
		}
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

// calculateAge calculates age from date of birth
func calculateAge(dob time.Time) int {
	now := time.Now()
	age := now.Year() - dob.Year()

	// Adjust if birthday hasn't occurred this year
	if now.Month() < dob.Month() || (now.Month() == dob.Month() && now.Day() < dob.Day()) {
		age--
	}

	return age
}

// UpdatePrivacySettings updates user privacy settings and invalidates leaderboard cache
func (s *service) UpdatePrivacySettings(ctx context.Context, userID int32, isPublic bool) error {
	// TODO: Add UpdateUserPrivacy method to store interface and implementation
	// For now, we'll return an error indicating the method needs to be implemented
	// if err := s.userStore.UpdateUserPrivacy(ctx, userID, isPublic); err != nil {
	//     return fmt.Errorf("failed to update user privacy: %w", err)
	// }

	// Invalidate leaderboard cache when privacy settings change
	if err := s.leaderboardCache.InvalidateUserLeaderboards(ctx, int(userID)); err != nil {
		s.logger.Error(ctx, "Failed to invalidate leaderboard cache after privacy update", "userID", userID, "error", err)
		// Don't fail the whole operation if cache invalidation fails, just log it
	}

	s.logger.Info(ctx, "User privacy settings updated", "userID", userID, "isPublic", isPublic)
	return fmt.Errorf("UpdateUserPrivacy store method not yet implemented")
}
