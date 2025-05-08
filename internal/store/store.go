package store

import (
	"context"
	"errors"
	"time"
)

// ErrUserNotFound is returned when a user is not found in the store.
var ErrUserNotFound = errors.New("user not found")

// ErrExerciseNotFound is returned when an exercise definition is not found.
var ErrExerciseNotFound = errors.New("exercise not found")

// ErrExerciseLogNotFound is returned when a specific exercise log is not found.
var ErrExerciseLogNotFound = errors.New("exercise log not found")

// "ptchampion/internal/models" // Import your domain models here later

// Exercise defines the structure for an exercise definition in the domain.
type Exercise struct {
	ID          int32
	Name        string
	Description *string // Nullable
	Type        string  // e.g., "run", "pushup" - could be an enum/const later
	// Potentially add other fields like default unit, muscle groups etc.
}

// UserExerciseRecord defines the structure for a logged exercise by a user.
type UserExerciseRecord struct {
	ID            int32
	UserID        int32
	ExerciseID    int32
	ExerciseName  string  // Denormalized for convenience
	ExerciseType  string  // Denormalized for convenience
	Reps          *int32  // Nullable
	TimeInSeconds *int32  // Nullable
	Distance      *int32  // Nullable
	Notes         *string // Nullable
	Grade         int32   // Grade calculated for this instance
	CreatedAt     time.Time
}

// PaginatedUserExerciseRecords holds a page of exercise records and total count.
type PaginatedUserExerciseRecords struct {
	Records    []*UserExerciseRecord
	TotalCount int64
}

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
	GetExerciseDefinition(ctx context.Context, exerciseID int32) (*Exercise, error)
	LogUserExercise(ctx context.Context, record *UserExerciseRecord) (*UserExerciseRecord, error) // Takes and returns the domain model
	GetUserExerciseLogs(ctx context.Context, userID int32, limit, offset int32) (*PaginatedUserExerciseRecords, error)
	ListExerciseDefinitions(ctx context.Context) ([]*Exercise, error)
	// GetUserExerciseLogsCount is handled by GetUserExerciseLogs returning PaginatedUserExerciseRecords
}

// LeaderboardStore defines methods for leaderboard data access
type LeaderboardStore interface {
	// GetGlobalLeaderboard(ctx context.Context, exerciseType string) ([]*models.LeaderboardEntry, error)
	// ... other leaderboard methods
}
