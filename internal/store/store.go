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

// ErrLeaderboardUnavailable is returned when leaderboard data cannot be fetched.
var ErrLeaderboardUnavailable = errors.New("leaderboard unavailable")

// ErrWorkoutRecordNotFound is returned when a workout record is not found.
var ErrWorkoutRecordNotFound = errors.New("workout record not found")

// ErrEmailTaken is returned when an email address is already in use by another user.
var ErrEmailTaken = errors.New("email address is already in use")

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

// LeaderboardEntry defines a single entry in a leaderboard.
// It's designed to be relatively generic for different types of leaderboards.
type LeaderboardEntry struct {
	UserID      string  // Corresponds to store.User.ID (UUID string)
	Username    string  // Denormalized from User
	DisplayName *string // Denormalized from User, nullable
	Score       int32   // Standardized score/grade for the leaderboard context
	Rank        int32   // Rank can be set by the service/handler after fetching sorted list
	// Potentially add LastSubmittedAt time.Time if relevant
}

// WorkoutRecord defines the structure for a logged workout instance in the domain.
// This is based on the existing db.Workout table, which seems to represent a single exercise performance.
type WorkoutRecord struct {
	ID              int32
	UserID          int32
	ExerciseID      int32
	ExerciseName    string // Denormalized, typically joined from exercises table
	ExerciseType    string // Denormalized from exercises table (present in db.Workout)
	Reps            *int32 // Nullable
	DurationSeconds *int32 // Nullable
	FormScore       *int32 // Nullable
	Grade           int32
	CompletedAt     time.Time
	CreatedAt       time.Time
}

// PaginatedWorkoutRecords holds a page of workout records and total count.
type PaginatedWorkoutRecords struct {
	Records    []*WorkoutRecord
	TotalCount int64
}

// Store defines the interface for data access operations
type Store interface {
	UserStore
	ExerciseStore
	LeaderboardStore
	WorkoutStore // Add WorkoutStore
	// Add other store interfaces as needed

	Ping(ctx context.Context) error // For health checks
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
	// GetExerciseTypeLeaderboard is effectively GetGlobalExerciseLeaderboard now
	GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int, startDate time.Time, endDate time.Time) ([]*LeaderboardEntry, error)
	GetGlobalAggregateLeaderboard(ctx context.Context, limit int, startDate time.Time, endDate time.Time) ([]*LeaderboardEntry, error)
	GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int, startDate time.Time, endDate time.Time) ([]*LeaderboardEntry, error)
	GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int, startDate time.Time, endDate time.Time) ([]*LeaderboardEntry, error)
	// Remove or comment out old/generic GetOverallLeaderboard, GetExerciseTypeLeaderboard, GetLocalLeaderboard if they are fully replaced
}

// WorkoutStore defines methods for workout data access
type WorkoutStore interface {
	CreateWorkoutRecord(ctx context.Context, record *WorkoutRecord) (*WorkoutRecord, error)
	GetUserWorkoutRecords(ctx context.Context, userID int32, limit int32, offset int32) (*PaginatedWorkoutRecords, error)
	UpdateWorkoutVisibility(ctx context.Context, userID int32, workoutID int32, isPublic bool) error
	GetWorkoutRecordByID(ctx context.Context, id int32) (*WorkoutRecord, error)
	// UpdateWorkoutRecord(ctx context.Context, record *WorkoutRecord) (*WorkoutRecord, error) // Optional: if needed
	// DeleteWorkoutRecord(ctx context.Context, id int32) error // Optional: if needed
}

// User represents a user in the system
/*
type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"password_hash,omitempty"`
	FirstName    string    `json:"first_name"`
	LastName     string    `json:"last_name"`
	// Removed AvatarURL field
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
*/
