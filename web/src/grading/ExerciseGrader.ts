/**
 * ExerciseGrader.ts
 * 
 * Defines interfaces and types for exercise grading logic.
 * This mirrors the iOS ExerciseGraderProtocol approach.
 */

import { NormalizedLandmark } from '@mediapipe/tasks-vision';

/**
 * Common exercise states used across different exercises.
 * Each specific exercise may extend this with additional states.
 */
export type ExerciseState = 'start' | 'down' | 'up' | 'unknown';

/**
 * Result of grading a single frame of pose data
 */
export interface GradingResult {
  /** Current state of the exercise movement */
  state: ExerciseState;
  
  /** Number of reps to increment (typically 0 or 1) */
  repIncrement: number;
  
  /** Optional form fault message to display */
  formFault?: string;
  
  /** Form score (0-100) or undefined if not applicable */
  formScore?: number;
  
  /** Whether the current rep has a form fault that should invalidate counting */
  hasFormFault: boolean;
}

/**
 * Visibility threshold for landmark detection quality
 */
export const DEFAULT_LANDMARK_VISIBILITY_THRESHOLD = 0.6;

/**
 * Base interface for all exercise graders
 */
export interface ExerciseGrader {
  /**
   * Process a new frame of pose landmarks and update the exercise state
   * @param landmarks Array of pose landmarks from MediaPipe
   * @returns GradingResult with updated state and rep information
   */
  processPose(landmarks: NormalizedLandmark[]): GradingResult;
  
  /**
   * Reset the grader to its initial state
   */
  reset(): void;
  
  /**
   * Get the current state of the exercise
   */
  getState(): ExerciseState;
  
  /**
   * Get the exercise type
   */
  getExerciseType(): string;
}

/**
 * Base abstract class that implements common functionality for graders
 */
export abstract class BaseExerciseGrader implements ExerciseGrader {
  protected state: ExerciseState = 'start';
  protected exerciseType: string;
  
  constructor(exerciseType: string) {
    this.exerciseType = exerciseType;
  }
  
  /**
   * Implementation required by derived classes
   */
  abstract processPose(landmarks: NormalizedLandmark[]): GradingResult;
  
  /**
   * Reset the grader state
   */
  reset(): void {
    this.state = 'start';
  }
  
  /**
   * Get the current exercise state
   */
  getState(): ExerciseState {
    return this.state;
  }
  
  /**
   * Get the exercise type
   */
  getExerciseType(): string {
    return this.exerciseType;
  }
  
  /**
   * Helper method to check if all required landmarks are visible
   * @param landmarks All pose landmarks
   * @param requiredIndices Indices of landmarks that must be visible
   * @param visibilityThreshold Minimum visibility value (0-1)
   * @returns Whether all required landmarks are visible enough
   */
  protected areLandmarksVisible(
    landmarks: NormalizedLandmark[], 
    requiredIndices: number[], 
    visibilityThreshold: number = DEFAULT_LANDMARK_VISIBILITY_THRESHOLD
  ): boolean {
    return requiredIndices.every(index => {
      const landmark = landmarks[index];
      return landmark && landmark.visibility && landmark.visibility > visibilityThreshold;
    });
  }
  
  /**
   * Calculate angle between three points (in degrees, 0-180)
   */
  protected calculateAngle(
    a: NormalizedLandmark, 
    b: NormalizedLandmark, 
    c: NormalizedLandmark
  ): number {
    try {
      const v1 = { x: a.x - b.x, y: a.y - b.y };
      const v2 = { x: c.x - b.x, y: c.y - b.y };
      
      const dot = v1.x * v2.x + v1.y * v2.y;
      const det = v1.x * v2.y - v1.y * v2.x;
      
      const angleRad = Math.atan2(Math.abs(det), dot);
      let angleDeg = angleRad * (180 / Math.PI);
      
      // Ensure angle is between 0 and 180
      angleDeg = Math.max(0, Math.min(180, angleDeg));
      
      return angleDeg;
    } catch (error) {
      console.error("Error calculating angle:", error);
      return 180; // Return neutral angle on error
    }
  }
  
  /**
   * Calculate distance between two points
   */
  protected calculateDistance(a: NormalizedLandmark, b: NormalizedLandmark): number {
    return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
  }
}

/**
 * Factory function to create the appropriate grader for an exercise type
 * This is useful for runtime determination of which grader to use
 */
export function createGrader(exerciseType: string): ExerciseGrader {
  // This will be implemented in the index.ts file after all graders are defined
  throw new Error(`Grader for ${exerciseType} not implemented in factory yet`);
} 