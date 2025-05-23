package validation

import (
	"context"
	"errors"
	"fmt"

	"ptchampion/internal/store"
)

type ExerciseValidator struct {
	exerciseStore store.ExerciseStore
}

func NewExerciseValidator(store store.ExerciseStore) *ExerciseValidator {
	return &ExerciseValidator{exerciseStore: store}
}

func (v *ExerciseValidator) ValidateWorkoutData(
	ctx context.Context,
	exerciseID int32,
	reps *int32,
	duration *int32,
	formScore *int32,
) error {
	exercise, err := v.exerciseStore.GetExerciseDefinition(ctx, exerciseID)
	if err != nil {
		return fmt.Errorf("invalid exercise ID: %w", err)
	}

	// Validate based on exercise type
	switch exercise.Type {
	case "pushup", "situp", "pullup", "push_ups", "sit_ups", "pull_ups":
		if reps == nil || *reps < 0 {
			return errors.New("reps required for this exercise type")
		}
		if duration != nil && *duration > 300 { // 5 minute max
			return errors.New("duration exceeds maximum allowed")
		}
	case "run", "running":
		if duration == nil || *duration < 60 { // 1 minute minimum
			return errors.New("valid duration required for running")
		}
	default:
		return fmt.Errorf("unsupported exercise type: %s", exercise.Type)
	}

	// Validate form score
	if formScore != nil && (*formScore < 0 || *formScore > 100) {
		return errors.New("form score must be between 0 and 100")
	}

	return nil
}

// ValidateExercisePerformance validates performance metrics are reasonable
func (v *ExerciseValidator) ValidateExercisePerformance(
	ctx context.Context,
	exerciseID int32,
	reps *int32,
	duration *int32,
) error {
	exercise, err := v.exerciseStore.GetExerciseDefinition(ctx, exerciseID)
	if err != nil {
		return fmt.Errorf("invalid exercise ID: %w", err)
	}

	switch exercise.Type {
	case "pushup", "push_ups":
		if reps != nil && *reps > 300 { // Reasonable max for pushups
			return errors.New("pushup count exceeds reasonable maximum")
		}
	case "situp", "sit_ups":
		if reps != nil && *reps > 400 { // Reasonable max for situps
			return errors.New("situp count exceeds reasonable maximum")
		}
	case "pullup", "pull_ups":
		if reps != nil && *reps > 100 { // Reasonable max for pullups
			return errors.New("pullup count exceeds reasonable maximum")
		}
	case "run", "running":
		if duration != nil && *duration > 7200 { // 2 hour max
			return errors.New("run duration exceeds reasonable maximum")
		}
		if duration != nil && *duration < 30 { // 30 second minimum
			return errors.New("run duration below reasonable minimum")
		}
	}

	return nil
}
