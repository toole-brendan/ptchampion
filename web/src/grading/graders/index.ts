export { BaseGrader, POSE_LANDMARKS } from './BaseGrader';
export { PushupGrader } from './PushupGrader';
export { SitupGrader } from './SitupGrader';
export { PullupGrader } from './PullupGrader';
export { RunningGrader } from './RunningGrader';

export type { CalibrationData, FormIssue, GraderConfig } from './BaseGrader';

import { ExerciseGrader } from '../ExerciseGrader';
import { PushupGrader } from './PushupGrader';
import { SitupGrader } from './SitupGrader';
import { PullupGrader } from './PullupGrader';
import { RunningGrader } from './RunningGrader';

/**
 * Factory function to create the appropriate grader for an exercise type
 * @param exerciseType The type of exercise to grade
 * @param config Optional configuration for the grader
 * @returns An instance of the appropriate grader
 */
export function createExerciseGrader(
  exerciseType: string,
  config?: Record<string, any>
): ExerciseGrader {
  switch (exerciseType.toLowerCase()) {
    case 'pushup':
    case 'push-up':
    case 'pushups':
      return new PushupGrader(config);
      
    case 'situp':
    case 'sit-up':
    case 'situps':
      return new SitupGrader(config);
      
    case 'pullup':
    case 'pull-up':
    case 'pullups':
      return new PullupGrader(config);
      
    case 'run':
    case 'running':
    case '2-mile-run':
      return new RunningGrader(config);
      
    default:
      throw new Error(`Unknown exercise type: ${exerciseType}`);
  }
}