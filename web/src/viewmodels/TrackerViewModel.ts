/**
 * TrackerViewModel.ts
 * 
 * Defines the base interface and types for tracker ViewModels.
 * This serves as the contract between UI components and the underlying services.
 */

import { ExerciseType } from '../grading';

/**
 * Common status states for exercise tracking sessions
 */
export enum SessionStatus {
  INITIALIZING = 'initializing', // Camera/sensors initializing
  READY = 'ready',               // Ready to start, but not active
  ACTIVE = 'active',             // Currently tracking exercise
  PAUSED = 'paused',             // Tracking paused
  COMPLETED = 'completed',       // Exercise session completed
  ERROR = 'error'                // Error state
}

/**
 * Error types that can occur during tracking
 */
export enum TrackerErrorType {
  CAMERA_PERMISSION = 'camera_permission',
  CAMERA_NOT_FOUND = 'camera_not_found',
  MODEL_LOAD_FAILED = 'model_load_failed',
  LOCATION_PERMISSION = 'location_permission',
  NETWORK_ERROR = 'network_error',
  UNKNOWN = 'unknown'
}

/**
 * Error information
 */
export interface TrackerError {
  type: TrackerErrorType;
  message: string;
}

/**
 * Exercise result information after a completed session
 */
export interface ExerciseResult {
  exerciseType: ExerciseType;
  repCount?: number;         // Number of reps (if applicable)
  duration: number;          // Duration in seconds
  distance?: number;         // Distance in meters (for running)
  formScore?: number;        // Form score (0-100)
  grade?: string | number;   // Grade (if available)
  date: Date;                // Timestamp
  saved: boolean;            // Whether results were saved to backend
}

/**
 * Base interface for all tracker ViewModels
 */
export interface TrackerViewModel {
  /**
   * Current state information
   */
  readonly status: SessionStatus;
  readonly exerciseType: ExerciseType;
  readonly repCount: number;
  readonly timer: number;
  readonly formScore: number;
  readonly formFeedback: string | null;
  readonly error: TrackerError | null;
  readonly result: ExerciseResult | null;

  /**
   * Initialize the tracker and its dependencies
   * (camera, pose detection, etc.)
   */
  initialize(videoRef: React.RefObject<HTMLVideoElement>, canvasRef?: React.RefObject<HTMLCanvasElement>): Promise<void>;

  /**
   * Start or resume tracking
   */
  startSession(): void;

  /**
   * Pause tracking
   */
  pauseSession(): void;

  /**
   * Complete the exercise session and process results
   */
  finishSession(): Promise<ExerciseResult>;

  /**
   * Reset the session to its initial state
   */
  resetSession(): void;

  /**
   * Save results to backend
   */
  saveResults(): Promise<boolean>;

  /**
   * Clean up resources when unmounting
   */
  cleanup(): void;
}

/**
 * Base abstract class for tracker ViewModels implementing common functionality
 */
export abstract class BaseTrackerViewModel implements TrackerViewModel {
  // State properties
  protected _status: SessionStatus = SessionStatus.INITIALIZING;
  protected _repCount: number = 0;
  protected _timer: number = 0;
  protected _formScore: number = 100;
  protected _formFeedback: string | null = null;
  protected _error: TrackerError | null = null;
  protected _result: ExerciseResult | null = null;
  protected timerInterval: NodeJS.Timeout | null = null;
  protected _isInitialized: boolean = false;

  constructor(protected _exerciseType: ExerciseType) {}

  // Getters for read-only access to state
  get status(): SessionStatus { return this._status; }
  get exerciseType(): ExerciseType { return this._exerciseType; }
  get repCount(): number { return this._repCount; }
  get timer(): number { return this._timer; }
  get formScore(): number { return this._formScore; }
  get formFeedback(): string | null { return this._formFeedback; }
  get error(): TrackerError | null { return this._error; }
  get result(): ExerciseResult | null { return this._result; }

  // Abstract methods that must be implemented by subclasses
  abstract initialize(videoRef: React.RefObject<HTMLVideoElement>, canvasRef?: React.RefObject<HTMLCanvasElement>): Promise<void>;
  abstract startSession(): void;
  abstract pauseSession(): void;
  abstract finishSession(): Promise<ExerciseResult>;
  abstract saveResults(): Promise<boolean>;

  /**
   * Reset the session to its initial state
   */
  resetSession(): void {
    this._repCount = 0;
    this._timer = 0;
    this._formScore = 100;
    this._formFeedback = null;
    this._error = null;
    this._result = null;
    this._status = SessionStatus.READY;
    
    this.stopTimer();
  }

  /**
   * Clean up resources when unmounting
   */
  cleanup(): void {
    this.stopTimer();
  }

  /**
   * Start timer to track exercise duration
   */
  protected startTimer(): void {
    if (this.timerInterval) {
      this.stopTimer();
    }

    this.timerInterval = setInterval(() => {
      this._timer += 1;
    }, 1000);
  }

  /**
   * Stop the timer
   */
  protected stopTimer(): void {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  }

  /**
   * Set error information
   */
  protected setError(type: TrackerErrorType, message: string): void {
    this._error = { type, message };
    this._status = SessionStatus.ERROR;
  }

  /**
   * Clear error information
   */
  protected clearError(): void {
    this._error = null;
  }

  /**
   * Format time in seconds to mm:ss format
   */
  protected formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
}

/**
 * Factory function to create appropriate ViewModel for an exercise type
 * Will be implemented after creating all specific ViewModels
 */
export function createTrackerViewModel(exerciseType: ExerciseType): TrackerViewModel {
  // This will be implemented in the index.ts after defining all ViewModels
  throw new Error(`ViewModel for ${exerciseType} not implemented in factory yet`);
} 