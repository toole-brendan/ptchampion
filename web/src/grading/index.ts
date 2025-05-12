/**
 * Grading module index
 * 
 * Exports all exercise graders and utilities.
 */

// Export base types and interfaces
export * from './ExerciseGrader';

// Export rep counting functionality
export * from './RepCounter';
export * from './RepCounterAdapter';

// Export APFT scoring functionality
export * from './APFTScoring';

// Export ExerciseType enum
export { ExerciseType } from './ExerciseType';

// Selectively export analyzer types
export type { PushupFormAnalysis } from './PushupAnalyzer';
export type { PullupFormAnalysis } from './PullupAnalyzer';
export type { SitupFormAnalysis } from './SitupAnalyzer';

// Import concrete implementations
import RunningGrader from './RunningGrader';
import { ExerciseGrader } from './ExerciseGrader';
import { createRepCounterAdapter, RepCounterAdapter } from './RepCounterAdapter';
import { PushupFormAnalysis } from './PushupAnalyzer';
import { PullupFormAnalysis } from './PullupAnalyzer';
import { SitupFormAnalysis } from './SitupAnalyzer';
import { ExerciseType } from './ExerciseType';

/**
 * Simple concrete implementation of ExerciseGrader for types without specific implementations
 */
class SimpleExerciseGrader implements ExerciseGrader {
  private exerciseType: string;
  private currentState: 'start' | 'down' | 'up' | 'unknown' = 'start';
  
  constructor(exerciseType: string) {
    this.exerciseType = exerciseType;
  }
  
  processPose() {
    return {
      state: this.currentState,
      repIncrement: 0,
      hasFormFault: false
    };
  }
  
  reset() {
    this.currentState = 'start';
  }
  
  getState() {
    return this.currentState;
  }
  
  getExerciseType() {
    return this.exerciseType;
  }
}

/**
 * Factory function to create the appropriate grader for an exercise type
 * @param exerciseType Type of exercise to create a grader for
 * @returns Appropriate grader instance for the specified exercise
 */
export function createGrader(exerciseType: string | ExerciseType): ExerciseGrader {
  switch (exerciseType) {
    case ExerciseType.RUNNING:
      return new RunningGrader();
      
    default:
      // Create a simple implementation for other types
      return new SimpleExerciseGrader(exerciseType.toString());
  }
}

/**
 * Create a class to wrap all available graders
 * This is useful for situations where you need to switch between different graders
 */
export class ExerciseGraderManager {
  private graders: Map<ExerciseType, ExerciseGrader>;
  private repCounters: Map<ExerciseType, RepCounterAdapter<PushupFormAnalysis | PullupFormAnalysis | SitupFormAnalysis>>;
  
  constructor() {
    this.graders = new Map();
    // Initialize with all supported exercise types
    this.graders.set(ExerciseType.PUSHUP, new SimpleExerciseGrader(ExerciseType.PUSHUP));
    this.graders.set(ExerciseType.PULLUP, new SimpleExerciseGrader(ExerciseType.PULLUP));
    this.graders.set(ExerciseType.SITUP, new SimpleExerciseGrader(ExerciseType.SITUP));
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
  getRepCounter(exerciseType: ExerciseType): RepCounterAdapter<PushupFormAnalysis | PullupFormAnalysis | SitupFormAnalysis> {
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