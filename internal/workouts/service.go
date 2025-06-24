package workouts

import (
	"context"
	"errors"
	"fmt"
	"time"

	"ptchampion/internal/logging"
	"ptchampion/internal/store"
)

// LogWorkoutData defines the data needed to log a workout at the service layer.
// Updated to support client-side grading as per local grading implementation.
type LogWorkoutData struct {
	ExerciseID      int32
	ExerciseType    string // This might be redundant if ExerciseName is fetched from ExerciseID
	ExerciseName    string // Will be fetched if not provided, based on ExerciseID
	Reps            *int32
	DurationSeconds *int32
	Grade           int32     // Client-calculated APFT score (0-100)
	CompletedAt     time.Time
	FormScore       *int32 // Form quality score (0-100)
	IsPublic        bool   // Whether workout should appear on leaderboard
}

// Service defines the interface for workout-related business logic.
type Service interface {
	LogWorkout(ctx context.Context, userID int32, data *LogWorkoutData) (*store.WorkoutRecord, error)
	ListUserWorkouts(ctx context.Context, userID int32, page, pageSize int) (*store.PaginatedWorkoutRecords, error)
	UpdateWorkoutVisibility(ctx context.Context, userID int32, workoutID int32, isPublic bool) error
}

type service struct {
	workoutStore  store.WorkoutStore
	exerciseStore store.ExerciseStore // To fetch exercise details if needed
	logger        logging.Logger
}

// NewService creates a new workout service instance.
func NewService(workoutStore store.WorkoutStore, exerciseStore store.ExerciseStore, logger logging.Logger) Service {
	return &service{
		workoutStore:  workoutStore,
		exerciseStore: exerciseStore,
		logger:        logger,
	}
}

// LogWorkout handles the business logic for logging a new workout record.
// Updated to accept client-calculated grades as per local grading implementation.
func (s *service) LogWorkout(ctx context.Context, userID int32, data *LogWorkoutData) (*store.WorkoutRecord, error) {
	// Validate exercise exists
	exercise, err := s.exerciseStore.GetExerciseDefinition(ctx, data.ExerciseID)
	if err != nil {
		return nil, fmt.Errorf("failed to get exercise: %w", err)
	}

	// Validate required fields based on exercise type
	switch exercise.Type {
	case "pushup", "situp", "pullup":
		if data.Reps == nil {
			return nil, errors.New("reps required for this exercise type")
		}
	case "run":
		if data.DurationSeconds == nil {
			return nil, errors.New("duration required for running")
		}
	default:
		return nil, fmt.Errorf("unsupported exercise type: %s", exercise.Type)
	}

	// Validate grade is within acceptable range (0-100)
	if data.Grade < 0 || data.Grade > 100 {
		return nil, fmt.Errorf("grade must be between 0 and 100, got %d", data.Grade)
	}

	// Use client-provided grade directly
	recordToStore := &store.WorkoutRecord{
		UserID:          userID,
		ExerciseID:      data.ExerciseID,
		ExerciseName:    exercise.Name,      // Use name from definition
		ExerciseType:    exercise.Type,      // Use type from definition
		Reps:            data.Reps,
		DurationSeconds: data.DurationSeconds,
		Grade:           data.Grade,         // Client-calculated APFT score
		FormScore:       data.FormScore,     // Client-calculated form score
		CompletedAt:     data.CompletedAt,
		IsPublic:        data.IsPublic,      // For leaderboard visibility
		// CreatedAt will be set by the database
	}

	loggedRecord, err := s.workoutStore.CreateWorkoutRecord(ctx, recordToStore)
	if err != nil {
		s.logger.Error(ctx, "Failed to create workout record in store", "userID", userID, "exerciseID", data.ExerciseID, "error", err)
		return nil, fmt.Errorf("failed to save workout record: %w", err)
	}

	s.logger.Info(ctx, "Workout record logged successfully", "userID", userID, "workoutRecordID", loggedRecord.ID)
	return loggedRecord, nil
}

// ListUserWorkouts retrieves paginated workout records for a user.
func (s *service) ListUserWorkouts(ctx context.Context, userID int32, page, pageSize int) (*store.PaginatedWorkoutRecords, error) {
	s.logger.Debug(ctx, "WorkoutService: ListUserWorkouts called", "userID", userID, "page", page, "pageSize", pageSize)

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 { // Max page size constraint
		pageSize = 20 // Default page size
	}
	limit := int32(pageSize)
	offset := int32((page - 1) * pageSize)

	paginatedRecords, err := s.workoutStore.GetUserWorkoutRecords(ctx, userID, limit, offset)
	if err != nil {
		s.logger.Error(ctx, "Failed to get user workout records from store", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to retrieve user workout records: %w", err)
	}

	s.logger.Info(ctx, "User workout records retrieved", "userID", userID, "count", paginatedRecords.TotalCount)
	return paginatedRecords, nil
}

// UpdateWorkoutVisibility handles the business logic for updating a workout's public visibility.
func (s *service) UpdateWorkoutVisibility(ctx context.Context, userID int32, workoutID int32, isPublic bool) error {
	s.logger.Debug(ctx, "WorkoutService: UpdateWorkoutVisibility called", "userID", userID, "workoutID", workoutID, "isPublic", isPublic)

	// 1. Verify the user owns the workout record
	record, err := s.workoutStore.GetWorkoutRecordByID(ctx, workoutID)
	if err != nil {
		if err == store.ErrWorkoutRecordNotFound {
			s.logger.Warn(ctx, "Workout record not found for visibility update", "workoutID", workoutID)
			return err // Return specific not found error
		}
		s.logger.Error(ctx, "Failed to get workout record for visibility update check", "workoutID", workoutID, "error", err)
		return fmt.Errorf("failed to retrieve workout record: %w", err)
	}

	if record.UserID != userID {
		s.logger.Warn(ctx, "User attempted to update visibility for workout they don't own", "userID", userID, "workoutID", workoutID, "ownerID", record.UserID)
		return fmt.Errorf("user does not have permission to update this workout record") // Forbidden error
	}

	// 2. Call the store to update visibility
	err = s.workoutStore.UpdateWorkoutVisibility(ctx, userID, workoutID, isPublic)
	if err != nil {
		s.logger.Error(ctx, "Failed to update workout visibility in store", "userID", userID, "workoutID", workoutID, "error", err)
		return fmt.Errorf("failed to update workout visibility: %w", err)
	}

	s.logger.Info(ctx, "Workout visibility updated successfully", "userID", userID, "workoutID", workoutID, "isPublic", isPublic)
	return nil
}
