/**
 * Constants for exercise types and IDs
 */

export enum ExerciseId {
  PUSHUP = 1,
  SITUP = 2,
  PULLUP = 3,
  RUNNING = 4,
}

export const EXERCISE_TYPE_LABELS: Record<ExerciseId, string> = {
  [ExerciseId.PUSHUP]: 'Push-up',
  [ExerciseId.SITUP]: 'Sit-up',
  [ExerciseId.PULLUP]: 'Pull-up',
  [ExerciseId.RUNNING]: 'Running',
}; 