/**
 * SitupTrackerViewModel.ts
 * 
 * ViewModel for situp tracking session. 
 * Coordinates between PoseDetectorService, SitupAnalyzer, and UI components.
 */

import { PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { ExerciseType } from '../grading';
import { SitupAnalyzer, SitupFormAnalysis } from '../grading/SitupAnalyzer';
import { poseDetectorService } from '../services/PoseDetectorService';
import { logExerciseResult } from '../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../lib/types';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';
import { useState, useCallback, useRef, useEffect } from 'react';
// Import the SitupGrader
import { createGrader } from '../grading';
import { ExerciseId } from '../constants/exercises';

/**
 * Class implementation of SitupTrackerViewModel
 */
export class SitupTrackerViewModel extends BaseTrackerViewModel {
  private videoRef: React.RefObject<HTMLVideoElement> | null = null;
  private canvasRef: React.RefObject<HTMLCanvasElement> | null = null;
  private analyzer: SitupAnalyzer;
  private grader: ReturnType<typeof createGrader>; // Using any temporarily until we have proper typing
  private submitting: boolean = false;

  constructor() {
    super(ExerciseType.SITUP);
    this.analyzer = new SitupAnalyzer();
    this.grader = createGrader(ExerciseType.SITUP);
  }

  /**
   * Initialize the situp tracker
   * @param videoRef Reference to the video element
   * @param canvasRef Optional reference to canvas for drawing
   */
  async initialize(
    videoRef: React.RefObject<HTMLVideoElement>,
    canvasRef?: React.RefObject<HTMLCanvasElement>
  ): Promise<void> {
    if (this._status !== SessionStatus.INITIALIZING) {
      this.resetSession();
    }

    this.videoRef = videoRef;
    this.canvasRef = canvasRef || null;

    try {
      // Initialize pose detector with the provided video element
      await poseDetectorService.initialize();
      this._status = SessionStatus.READY;
      this._error = null;
    } catch (error) {
      console.error("Failed to initialize pose detector:", error);
      this.setError(
        TrackerErrorType.MODEL_LOAD_FAILED,
        error instanceof Error ? error.message : "Unknown error initializing pose detector"
      );
    }
  }

  /**
   * Start or resume the tracking session
   */
  startSession(): void {
    if (this._status === SessionStatus.ACTIVE) {
      return; // Already active
    }

    if (!this.videoRef || !this.videoRef.current) {
      this.setError(
        TrackerErrorType.CAMERA_NOT_FOUND,
        "Camera not initialized"
      );
      return;
    }

    // Start pose detection with callback to handle results
    poseDetectorService.startDetection(
      this.videoRef.current,
      this.canvasRef?.current || undefined,
      this.handlePoseResults
    );

    // Start timer
    this.startTimer();

    this._status = SessionStatus.ACTIVE;
  }

  /**
   * Handle pose detection results
   */
  private handlePoseResults = (result: PoseLandmarkerResult): void => {
    if (result.landmarks && result.landmarks.length > 0) {
      const landmarks = result.landmarks[0];
      
      // Process the landmarks through the grader instead of analyzer
      const gradingResult = this.grader.processPose(landmarks);
      
      // Update state based on grading result
      if (gradingResult.repIncrement > 0) {
        this._repCount += gradingResult.repIncrement;
      }
      
      // Update form feedback
      this._formFeedback = gradingResult.formFault || null;
      
      // Update form score
      if (gradingResult.formScore !== undefined) {
        this._formScore = gradingResult.formScore;
      }
      
      // Update state (can be mapped to UI state if needed)
      // The state field in gradingResult will be 'up', 'down', etc.
    }
  };

  // Store the last analysis for rep counting
  private lastAnalysis: SitupFormAnalysis | null = null;

  /**
   * Clean up resources when component unmounts
   */
  cleanup(): void {
    poseDetectorService.stopDetection();
    this.stopTimer();
  }

  /**
   * Pause the tracking session
   */
  pauseSession(): void {
    if (this._status !== SessionStatus.ACTIVE) {
      return; // Not active
    }

    // Stop pose detection
    poseDetectorService.stopDetection();

    // Pause timer
    this.stopTimer();

    this._status = SessionStatus.PAUSED;
  }

  /**
   * Finish the tracking session and prepare results
   */
  async finishSession(): Promise<ExerciseResult> {
    if (this._status === SessionStatus.COMPLETED) {
      return this._result!;
    }

    // Stop tracking if active
    if (this._status === SessionStatus.ACTIVE) {
      poseDetectorService.stopDetection();
      this.stopTimer();
    }

    // Create the result object
    const result: ExerciseResult = {
      exerciseType: this._exerciseType,
      repCount: this._repCount,
      duration: this._timer,
      formScore: this._formScore,
      date: new Date(),
      saved: false
    };

    this._result = result;
    this._status = SessionStatus.COMPLETED;

    return result;
  }

  /**
   * Save results to backend
   */
  async saveResults(): Promise<boolean> {
    if (!this._result || this.submitting) {
      return false;
    }

    if (this._result.saved) {
      return true; // Already saved
    }

    this.submitting = true;

    try {
      // Prepare API request data
      const exerciseData: LogExerciseRequest = {
        exercise_id: ExerciseId.SITUP,
        reps: this._result.repCount || 0,
        duration: this._result.duration,
        notes: `Form Score: ${this._result.formScore?.toFixed(0)}`
      };

      // Check if we're online
      const isOnline = navigator.onLine;
      
      if (isOnline) {
        try {
          // Call the API with retry capability
          const response: ExerciseResponse = await logExerciseResult(exerciseData);
          
          // Update result with grade and saved status
          this._result.grade = response.grade;
          this._result.saved = true;
          
          return true;
        } catch (error) {
          // If API call fails, fall back to offline queue
          console.log("API call failed, falling back to offline queue", error);
          return await this.saveOffline();
        }
      } else {
        // We're offline, save to queue immediately
        return await this.saveOffline();
      }
    } catch (error) {
      console.error("Failed to save situp results:", error);
      
      // Show toast notification to user 
      if (typeof window !== 'undefined' && window.showToast) {
        window.showToast({ 
          title: 'Save Failed', 
          description: 'Could not save exercise results. Will retry when online.', 
          variant: 'destructive' 
        });
      }
      
      // Log to error monitoring service if available
      if (typeof window !== 'undefined' && window.captureException) {
        window.captureException(error);
      }
      
      return false;
    } finally {
      this.submitting = false;
    }
  }
  
  /**
   * Save results to offline queue for later sync
   */
  private async saveOffline(): Promise<boolean> {
    try {
      // Import syncManager dynamically to avoid circular dependencies
      const { syncManager } = await import('../lib/syncManager');
      
      // Queue the workout for background sync
      const queued = await syncManager.queueWorkout(this._result!, ExerciseId.SITUP);
      
      if (queued) {
        // Update local state to reflect that it's "saved" (but not yet synced to server)
        this._result!.saved = true;
        
        // Show toast notification to user
        if (typeof window !== 'undefined' && window.showToast) {
          window.showToast({
            title: 'Workout Saved Offline',
            description: 'Your workout has been saved and will sync when you\'re back online.',
            variant: 'success'
          });
        }
        
        return true;
      }
      
      return false;
    } catch (error) {
      console.error("Failed to save situp results offline:", error);
      
      // Log to error monitoring service if available
      if (typeof window !== 'undefined' && window.captureException) {
        window.captureException(error);
      }
      
      return false;
    }
  }

  /**
   * Public method to format time in seconds to mm:ss format
   */
  formatTime(seconds: number): string {
    return super.formatTime(seconds);
  }

  /**
   * Reset the session to its initial state
   */
  resetSession(): void {
    super.resetSession();
    this.analyzer.reset();
    this.grader.reset(); // Reset the grader as well
  }
}

/**
 * React hook that provides the SitupTrackerViewModel
 */
export function useSitupTrackerViewModel() {
  // State to hold the ViewModel and trigger re-renders on changes
  const [viewModel] = useState<SitupTrackerViewModel>(() => new SitupTrackerViewModel());
  
  // Refs to hold latest values for use in callbacks
  const repCountRef = useRef(viewModel.repCount);
  const timerRef = useRef(viewModel.timer);
  const statusRef = useRef(viewModel.status);
  const formScoreRef = useRef(viewModel.formScore);
  const formFeedbackRef = useRef(viewModel.formFeedback);
  const errorRef = useRef(viewModel.error);
  const resultRef = useRef(viewModel.result);
  
  // State for UI updates
  const [repCount, setRepCount] = useState(viewModel.repCount);
  const [timer, setTimer] = useState(viewModel.timer);
  const [status, setStatus] = useState(viewModel.status);
  const [formScore, setFormScore] = useState(viewModel.formScore);
  const [formFeedback, setFormFeedback] = useState(viewModel.formFeedback);
  const [error, setError] = useState(viewModel.error);
  const [result, setResult] = useState(viewModel.result);
  
  // Update state on interval
  useEffect(() => {
    const updateInterval = setInterval(() => {
      // Check if any values have changed and update state if needed
      if (repCountRef.current !== viewModel.repCount) {
        repCountRef.current = viewModel.repCount;
        setRepCount(viewModel.repCount);
      }
      
      if (timerRef.current !== viewModel.timer) {
        timerRef.current = viewModel.timer;
        setTimer(viewModel.timer);
      }
      
      if (statusRef.current !== viewModel.status) {
        statusRef.current = viewModel.status;
        setStatus(viewModel.status);
      }
      
      if (formScoreRef.current !== viewModel.formScore) {
        formScoreRef.current = viewModel.formScore;
        setFormScore(viewModel.formScore);
      }
      
      if (formFeedbackRef.current !== viewModel.formFeedback) {
        formFeedbackRef.current = viewModel.formFeedback;
        setFormFeedback(viewModel.formFeedback);
      }
      
      if (errorRef.current !== viewModel.error) {
        errorRef.current = viewModel.error;
        setError(viewModel.error);
      }
      
      if (resultRef.current !== viewModel.result) {
        resultRef.current = viewModel.result;
        setResult(viewModel.result);
      }
    }, 250); // Update 4 times per second
    
    return () => {
      clearInterval(updateInterval);
      viewModel.cleanup();
    };
  }, [viewModel]);
  
  // Initialize method
  const initialize = useCallback(async (
    videoRef: React.RefObject<HTMLVideoElement>,
    canvasRef?: React.RefObject<HTMLCanvasElement>
  ) => {
    return await viewModel.initialize(videoRef, canvasRef);
  }, [viewModel]);
  
  const startSession = useCallback(() => {
    viewModel.startSession();
  }, [viewModel]);
  
  const pauseSession = useCallback(() => {
    viewModel.pauseSession();
  }, [viewModel]);
  
  const finishSession = useCallback(async () => {
    return await viewModel.finishSession();
  }, [viewModel]);
  
  const resetSession = useCallback(() => {
    viewModel.resetSession();
  }, [viewModel]);
  
  const saveResults = useCallback(async () => {
    return await viewModel.saveResults();
  }, [viewModel]);
  
  // Return the state and methods
  return {
    // State
    repCount,
    timer,
    status,
    formScore,
    formFeedback,
    error,
    result,
    
    // Formatted time
    formattedTime: viewModel.formatTime(timer),
    
    // Methods
    initialize,
    startSession,
    pauseSession,
    finishSession,
    resetSession,
    saveResults
  };
}

export default useSitupTrackerViewModel; 