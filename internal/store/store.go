package store

import (
	"context"
)

// "ptchampion/internal/models" // Import your domain models here later

// Store defines the interface for data access operations
type Store interface {
	UserStore
	ExerciseStore
	LeaderboardStore
	// Add other store interfaces as needed
}

// UserStore defines methods for user data access
type UserStore interface {
	GetUserByID(ctx context.Context, id string) (*User, error)
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	CreateUser(ctx context.Context, user *User) (*User, error)
	UpdateUser(ctx context.Context, user *User) (*User, error)
	DeleteUser(ctx context.Context, id string) error
}

// ExerciseStore defines methods for exercise data access
type ExerciseStore interface {
	// GetExerciseByID(ctx context.Context, id int) (*models.Exercise, error)
	// LogExercise(ctx context.Context, log *models.ExerciseLog) error
	// ... other exercise methods
}

// LeaderboardStore defines methods for leaderboard data access
type LeaderboardStore interface {
	// GetGlobalLeaderboard(ctx context.Context, exerciseType string) ([]*models.LeaderboardEntry, error)
	// ... other leaderboard methods
}
