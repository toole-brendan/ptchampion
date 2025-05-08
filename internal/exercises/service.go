package exercises

import (
	"context"
	"fmt"

	"ptchampion/internal/grading"
	"ptchampion/internal/logging"
	"ptchampion/internal/store"
)

// LogExerciseRequestData defines the data needed to log an exercise at the service layer.
// This is similar to handlers.LogExerciseRequest but specific to the service.
type LogExerciseRequestData struct {
	ExerciseID int32
	Reps       *int32
	Duration   *int32 // in seconds
	Distance   *int32 // in meters
	Notes      *string
}

// Service defines the interface for exercise-related business logic.
type Service interface {
	LogExercise(ctx context.Context, userID int32, reqData *LogExerciseRequestData) (*store.UserExerciseRecord, error)
	GetUserExerciseHistory(ctx context.Context, userID int32, page, pageSize int) (*store.PaginatedUserExerciseRecords, error)
	ListAvailableExercises(ctx context.Context) ([]*store.Exercise, error)
}

type service struct {
	exerciseStore store.ExerciseStore
	logger        logging.Logger
}

// NewService creates a new exercise service instance.
func NewService(exerciseStore store.ExerciseStore, logger logging.Logger) Service {
	return &service{
		exerciseStore: exerciseStore,
		logger:        logger,
	}
}

// LogExercise handles the business logic for logging an exercise.
func (s *service) LogExercise(ctx context.Context, userID int32, reqData *LogExerciseRequestData) (*store.UserExerciseRecord, error) {
	s.logger.Debug(ctx, "ExerciseService: LogExercise called", "userID", userID, "exerciseID", reqData.ExerciseID)

	// 1. Fetch the Exercise definition by ID to get its type and name
	exerciseDef, err := s.exerciseStore.GetExerciseDefinition(ctx, reqData.ExerciseID)
	if err != nil {
		if err == store.ErrExerciseNotFound {
			s.logger.Warn(ctx, "Attempt to log exercise with invalid ID", "exerciseID", reqData.ExerciseID)
			return nil, fmt.Errorf("invalid exercise ID: %d: %w", reqData.ExerciseID, err)
		}
		s.logger.Error(ctx, "Failed to get exercise definition", "exerciseID", reqData.ExerciseID, "error", err)
		return nil, fmt.Errorf("failed to retrieve exercise details: %w", err)
	}

	// 2. Calculate Grade based on exercise type and performance value
	var performanceValue float64
	metricMissing := false

	switch exerciseDef.Type {
	case grading.ExerciseTypeRun:
		if reqData.Duration != nil {
			performanceValue = float64(*reqData.Duration)
		} else {
			metricMissing = true
		}
	case grading.ExerciseTypePushup, grading.ExerciseTypeSitup, grading.ExerciseTypePullup:
		if reqData.Reps != nil {
			performanceValue = float64(*reqData.Reps)
		} else {
			metricMissing = true
		}
	// Add other cases as necessary, e.g., for distance-based
	default:
		s.logger.Warn(ctx, "Attempting to grade unknown or unhandled exercise type", "exerciseType", exerciseDef.Type)
		// Potentially return an error or a default grade (e.g., 0 or ungradable status)
		// For now, let's assume an error if type is not gradeable by current logic
		return nil, fmt.Errorf("cannot calculate grade for unhandled exercise type: %s", exerciseDef.Type)
	}

	if metricMissing {
		s.logger.Warn(ctx, "Missing required performance metric for grading", "userID", userID, "exerciseType", exerciseDef.Type)
		return nil, fmt.Errorf("missing required performance metric (duration, reps, or distance) for exercise type %s", exerciseDef.Type)
	}

	calculatedGrade, err := grading.CalculateScore(exerciseDef.Type, performanceValue)
	if err != nil {
		s.logger.Error(ctx, "Failed to calculate grade", "userID", userID, "exerciseType", exerciseDef.Type, "error", err)
		return nil, fmt.Errorf("failed to calculate exercise grade: %w", err)
	}

	// 3. Prepare the record for the store
	recordToStore := &store.UserExerciseRecord{
		UserID:        userID,
		ExerciseID:    exerciseDef.ID,
		ExerciseName:  exerciseDef.Name, // Denormalized
		ExerciseType:  exerciseDef.Type, // Denormalized
		Reps:          reqData.Reps,
		TimeInSeconds: reqData.Duration,
		Distance:      reqData.Distance,
		Notes:         reqData.Notes,
		Grade:         int32(calculatedGrade),
		// CreatedAt will be set by the database or store layer implicitly
	}

	// 4. Save to store
	loggedRecord, err := s.exerciseStore.LogUserExercise(ctx, recordToStore)
	if err != nil {
		s.logger.Error(ctx, "Failed to log user exercise in store", "userID", userID, "exerciseID", exerciseDef.ID, "error", err)
		return nil, fmt.Errorf("failed to save exercise log: %w", err)
	}

	s.logger.Info(ctx, "Exercise logged successfully", "userID", userID, "logID", loggedRecord.ID)
	return loggedRecord, nil
}

// GetUserExerciseHistory retrieves paginated exercise history for a user.
func (s *service) GetUserExerciseHistory(ctx context.Context, userID int32, page, pageSize int) (*store.PaginatedUserExerciseRecords, error) {
	s.logger.Debug(ctx, "ExerciseService: GetUserExerciseHistory called", "userID", userID, "page", page, "pageSize", pageSize)

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 { // Max page size constraint
		pageSize = 20 // Default page size
	}
	limit := int32(pageSize)
	offset := int32((page - 1) * pageSize)

	paginatedRecords, err := s.exerciseStore.GetUserExerciseLogs(ctx, userID, limit, offset)
	if err != nil {
		s.logger.Error(ctx, "Failed to get user exercise logs from store", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to retrieve user exercise history: %w", err)
	}

	s.logger.Info(ctx, "User exercise history retrieved", "userID", userID, "count", paginatedRecords.TotalCount)
	return paginatedRecords, nil
}

// ListAvailableExercises retrieves all available exercise definitions.
func (s *service) ListAvailableExercises(ctx context.Context) ([]*store.Exercise, error) {
	s.logger.Debug(ctx, "ExerciseService: ListAvailableExercises called")
	exercises, err := s.exerciseStore.ListExerciseDefinitions(ctx)
	if err != nil {
		s.logger.Error(ctx, "Failed to list exercise definitions from store", "error", err)
		return nil, fmt.Errorf("failed to retrieve available exercises: %w", err)
	}
	s.logger.Info(ctx, "Available exercises listed", "count", len(exercises))
	return exercises, nil
}
