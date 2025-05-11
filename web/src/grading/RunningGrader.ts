/**
 * RunningGrader.ts
 * 
 * Implements running exercise grading logic.
 * Unlike other exercises, running focuses on distance/time rather than pose.
 */

import { BaseExerciseGrader, GradingResult } from './ExerciseGrader';

// Define a custom interface for running data
export interface RunningData {
  /** Distance in meters */
  distance: number;
  
  /** Duration in seconds */
  duration: number;
  
  /** Coordinates if available (for path tracking) */
  coordinates?: { lat: number; lng: number }[];
}

/**
 * Constants for running evaluation
 */
export const RUNNING_CONSTANTS = {
  // Conversion factors
  METERS_PER_MILE: 1609.34,
  
  // Standard military PT test distance (2 miles)
  STANDARD_DISTANCE_METERS: 3218.69, // 2 miles in meters
  
  // Target durations for different score levels (in seconds)
  MAX_SCORE_TIME_SECONDS: 780, // 13:00 for max score
  PASSING_SCORE_TIME_SECONDS: 1020, // 17:00 for passing score
};

/**
 * Calculate pace in minutes per mile
 * @param distanceMeters Distance in meters
 * @param durationSeconds Time in seconds
 * @returns Pace in minutes per mile (mm:ss format)
 */
export function calculatePace(distanceMeters: number, durationSeconds: number): string {
  if (distanceMeters <= 0 || durationSeconds <= 0) {
    return "00:00";
  }
  
  // Convert to pace (seconds per meter)
  const secondsPerMeter = durationSeconds / distanceMeters;
  
  // Convert to seconds per mile
  const secondsPerMile = secondsPerMeter * RUNNING_CONSTANTS.METERS_PER_MILE;
  
  // Format as mm:ss
  const minutes = Math.floor(secondsPerMile / 60);
  const seconds = Math.floor(secondsPerMile % 60);
  
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
}

/**
 * Calculate score (0-100) based on 2-mile run time
 * @param distanceMeters Distance in meters
 * @param durationSeconds Time in seconds
 * @returns Score from 0-100
 */
export function calculateRunScore(distanceMeters: number, durationSeconds: number): number {
  // If distance is not the standard distance, normalize the time
  const normalizedDuration = durationSeconds * (RUNNING_CONSTANTS.STANDARD_DISTANCE_METERS / distanceMeters);
  
  // If faster than max score time, give 100
  if (normalizedDuration <= RUNNING_CONSTANTS.MAX_SCORE_TIME_SECONDS) {
    return 100;
  }
  
  // If slower than passing time, score proportionally down to 60
  if (normalizedDuration >= RUNNING_CONSTANTS.PASSING_SCORE_TIME_SECONDS) {
    const overTime = normalizedDuration - RUNNING_CONSTANTS.PASSING_SCORE_TIME_SECONDS;
    const maxOverTime = 300; // 5 minutes over passing time = score of 0
    const penaltyFactor = Math.min(overTime / maxOverTime, 1);
    return Math.max(60 - (penaltyFactor * 60), 0);
  }
  
  // Between max and passing, score proportionally between 100 and 60
  const timeRange = RUNNING_CONSTANTS.PASSING_SCORE_TIME_SECONDS - RUNNING_CONSTANTS.MAX_SCORE_TIME_SECONDS;
  const timeOverMax = normalizedDuration - RUNNING_CONSTANTS.MAX_SCORE_TIME_SECONDS;
  const scoreReduction = (timeOverMax / timeRange) * 40;
  return Math.max(100 - scoreReduction, 60);
}

/**
 * Running grader that handles distance/time-based evaluation rather than poses
 */
export class RunningGrader extends BaseExerciseGrader {
  private distance: number = 0; // Meters
  private duration: number = 0; // Seconds
  private coordinates: { lat: number; lng: number }[] = [];
  private pace: string = "00:00";
  private score: number = 0;
  private isComplete: boolean = false;
  
  constructor() {
    super('RUNNING');
  }
  
  /**
   * Update running data with new metrics
   * This is used instead of processPose since running uses different inputs
   * @param data Updated running metrics
   * @returns GradingResult with updated state 
   */
  updateRunningData(data: RunningData): GradingResult {
    this.distance = data.distance;
    this.duration = data.duration;
    
    if (data.coordinates) {
      this.coordinates = data.coordinates;
    }
    
    // Calculate pace
    this.pace = calculatePace(this.distance, this.duration);
    
    // Calculate score (only relevant when complete)
    if (this.isComplete) {
      this.score = calculateRunScore(this.distance, this.duration);
    }
    
    return {
      state: this.isComplete ? 'up' : 'down', // Use 'up' to represent complete, 'down' for in progress
      repIncrement: 0, // Not applicable for running
      hasFormFault: false, // Not applicable for running
      formScore: this.isComplete ? this.score : undefined
    };
  }
  
  /**
   * Complete the running session and calculate the final score
   * @returns GradingResult with final state and score
   */
  completeRun(): GradingResult {
    this.isComplete = true;
    this.score = calculateRunScore(this.distance, this.duration);
    
    return {
      state: 'up', // Use 'up' to represent complete
      repIncrement: 0, // Not applicable for running
      hasFormFault: false,
      formScore: this.score
    };
  }
  
  /**
   * Get the current distance in meters
   */
  getDistance(): number {
    return this.distance;
  }
  
  /**
   * Get the current duration in seconds
   */
  getDuration(): number {
    return this.duration;
  }
  
  /**
   * Get the current pace (minutes per mile)
   */
  getPace(): string {
    return this.pace;
  }
  
  /**
   * Get the current score (0-100)
   */
  getScore(): number {
    return this.score;
  }
  
  /**
   * Check if the run is complete
   */
  isRunComplete(): boolean {
    return this.isComplete;
  }
  
  /**
   * Get the stored GPS coordinates
   */
  getCoordinates(): { lat: number; lng: number }[] {
    return this.coordinates;
  }
  
  /**
   * Placeholder implementation of required method
   * Running doesn't use pose landmarks, so this returns a default result
   */
  processPose(): GradingResult {
    return {
      state: this.isComplete ? 'up' : 'down',
      repIncrement: 0,
      hasFormFault: false,
      formScore: this.isComplete ? this.score : undefined
    };
  }
  
  /**
   * Reset the running grader to its initial state
   */
  reset(): void {
    super.reset();
    this.distance = 0;
    this.duration = 0;
    this.coordinates = [];
    this.pace = "00:00";
    this.score = 0;
    this.isComplete = false;
  }
}

export default RunningGrader; 