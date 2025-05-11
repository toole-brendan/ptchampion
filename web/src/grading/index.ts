/**
 * Grading module index
 * 
 * Exports all exercise graders and utilities.
 */

// Export base types and interfaces
export * from './ExerciseGrader';

// Export each grader implementation
export * from './PushupGrader';
export * from './PullupGrader';
export * from './SitupGrader';
export * from './RunningGrader';

// Import concrete grader implementations for the factory
import PushupGrader from './PushupGrader';
import PullupGrader from './PullupGrader';
import SitupGrader from './SitupGrader';
import RunningGrader from './RunningGrader';
import { ExerciseGrader } from './ExerciseGrader';

/**
 * Exercise types enum for use with the grader factory
 */
export enum ExerciseType {
  PUSHUP = 'PUSHUP',
  PULLUP = 'PULLUP',
  SITUP = 'SITUP',
  RUNNING = 'RUNNING'
}

/**
 * Factory function to create the appropriate grader for an exercise type
 * @param exerciseType Type of exercise to create a grader for
 * @returns Appropriate grader instance for the specified exercise
 */
export function createGrader(exerciseType: string | ExerciseType): ExerciseGrader {
  switch (exerciseType) {
    case ExerciseType.PUSHUP:
      return new PushupGrader();
      
    case ExerciseType.PULLUP:
      return new PullupGrader();
      
    case ExerciseType.SITUP:
      return new SitupGrader();
      
    case ExerciseType.RUNNING:
      return new RunningGrader();
      
    default:
      throw new Error(`Grader for ${exerciseType} not implemented yet`);
  }
}

/**
 * Create a class to wrap all available graders
 * This is useful for situations where you need to switch between different graders
 */
export class ExerciseGraderManager {
  private graders: Map<ExerciseType, ExerciseGrader>;
  
  constructor() {
    this.graders = new Map();
    // Initialize with all supported exercise types
    this.graders.set(ExerciseType.PUSHUP, new PushupGrader());
    this.graders.set(ExerciseType.PULLUP, new PullupGrader());
    this.graders.set(ExerciseType.SITUP, new SitupGrader());
    this.graders.set(ExerciseType.RUNNING, new RunningGrader());
  }
  
  /**
   * Get a grader for the specified exercise type
   * @param exerciseType Type of exercise
   * @returns Grader instance
   */
  getGrader(exerciseType: ExerciseType): ExerciseGrader {
    const grader = this.graders.get(exerciseType);
    if (!grader) {
      throw new Error(`Grader for ${exerciseType} not initialized`);
    }
    return grader;
  }
  
  /**
   * Reset all graders to their initial state
   */
  resetAll(): void {
    this.graders.forEach(grader => grader.reset());
  }
}

// Export default as the factory function for convenient imports
export default createGrader; 