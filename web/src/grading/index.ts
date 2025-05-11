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

// Export rep counting functionality
export * from './RepCounter';
export * from './RepCounterAdapter';

// Export APFT scoring functionality
export * from './APFTScoring';

// Import concrete grader implementations for the factory
import PushupGrader from './PushupGrader';
import PullupGrader from './PullupGrader';
import SitupGrader from './SitupGrader';
import RunningGrader from './RunningGrader';
import { ExerciseGrader } from './ExerciseGrader';
import { createRepCounterAdapter, RepCounterAdapter } from './RepCounterAdapter';

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
  private repCounters: Map<ExerciseType, RepCounterAdapter<any>>;
  
  constructor() {
    this.graders = new Map();
    // Initialize with all supported exercise types
    this.graders.set(ExerciseType.PUSHUP, new PushupGrader());
    this.graders.set(ExerciseType.PULLUP, new PullupGrader());
    this.graders.set(ExerciseType.SITUP, new SitupGrader());
    this.graders.set(ExerciseType.RUNNING, new RunningGrader());
    
    // Initialize rep counters
    this.repCounters = new Map();
    this.repCounters.set(ExerciseType.PUSHUP, createRepCounterAdapter(ExerciseType.PUSHUP));
    this.repCounters.set(ExerciseType.PULLUP, createRepCounterAdapter(ExerciseType.PULLUP));
    this.repCounters.set(ExerciseType.SITUP, createRepCounterAdapter(ExerciseType.SITUP));
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
   * Get a rep counter adapter for the specified exercise type
   * @param exerciseType Type of exercise
   * @returns RepCounterAdapter instance
   */
  getRepCounter(exerciseType: ExerciseType): RepCounterAdapter<any> {
    const counter = this.repCounters.get(exerciseType);
    if (!counter) {
      throw new Error(`Rep counter for ${exerciseType} not initialized`);
    }
    return counter;
  }
  
  /**
   * Reset all graders to their initial state
   */
  resetAll(): void {
    this.graders.forEach(grader => grader.reset());
    this.repCounters.forEach(counter => counter.reset());
  }
}

// Export default as the factory function for convenient imports
export default createGrader; 