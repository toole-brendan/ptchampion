import { ExerciseResult } from '../viewmodels/TrackerViewModel';
import { WorkoutRequest } from '../lib/types';
import { ExerciseType } from '../grading';

/**
 * Convert ExerciseResult from ViewModels to WorkoutRequest for API submission
 */
export function convertToWorkoutRequest(result: ExerciseResult): WorkoutRequest {
  // Map ExerciseType enum to lowercase strings expected by API
  const exerciseTypeMap: Record<ExerciseType, 'pushup' | 'situp' | 'pullup' | 'run'> = {
    [ExerciseType.PUSHUP]: 'pushup',
    [ExerciseType.SITUP]: 'situp',
    [ExerciseType.PULLUP]: 'pullup',
    [ExerciseType.RUNNING]: 'run'
  };

  const workoutRequest: WorkoutRequest = {
    exercise_type: exerciseTypeMap[result.exerciseType],
    completed_at: result.date.toISOString(),
    grade: typeof result.grade === 'number' ? result.grade : parseInt(result.grade || '0'),
    is_public: true // Default to public for leaderboard, can be made configurable later
  };

  // Add exercise-specific fields
  if (result.exerciseType === ExerciseType.RUNNING) {
    // For running, duration is the time to complete the run
    workoutRequest.duration_seconds = Math.floor(result.duration);
  } else {
    // For rep-based exercises
    workoutRequest.repetitions = result.repCount || 0;
  }

  // Add form score if available
  if (result.formScore !== undefined && result.formScore !== null) {
    workoutRequest.form_score = Math.round(result.formScore);
  }

  return workoutRequest;
}