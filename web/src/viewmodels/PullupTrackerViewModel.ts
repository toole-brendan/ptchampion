/**
 * PullupTrackerViewModel.ts
 * 
 * ViewModel for pullup tracking session. 
 * Coordinates between PoseDetectorService, PullupAnalyzer, and UI components.
 * Now updated to support both legacy PoseDetectorService and new BlazePose Full model.
 */

import { PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { ExerciseType } from '../grading';
import { PullupAnalyzer, PullupFormAnalysis } from '../grading/PullupAnalyzer';
import { poseDetectorService } from '@/services/PoseDetectorService';
import { logExerciseResult } from '../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../lib/types';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';
import { useState, useCallback, useRef, useEffect } from 'react';
// Import the PullupGrader
import { createGrader } from '../grading';
import { ExerciseId } from '../constants/exercises';
import { PoseDetector } from '../services/poseDetector';
import cameraManager from '@/services/CameraManager';

/**
 * Class implementation of PullupTrackerViewModel
 */
export class PullupTrackerViewModel extends BaseTrackerViewModel {
  private videoRef: React.RefObject<HTMLVideoElement> | null = null;
  private canvasRef: React.RefObject<HTMLCanvasElement> | null = null;
  private analyzer: PullupAnalyzer;
  private grader: ReturnType<typeof createGrader>; // Using any temporarily until we have proper typing
  private submitting: boolean = false;
  
  // New BlazePose detector properties
  private useNewPoseDetector: boolean = false;
  private poseDetector: PoseDetector | null = null;
  private animationFrameId: number | null = null;
  private facingMode: 'user' | 'environment' = 'environment';

  constructor(useNewPoseDetector = false) {
    super(ExerciseType.PULLUP);
    this.analyzer = new PullupAnalyzer();
    this.grader = createGrader(ExerciseType.PULLUP);
    this.useNewPoseDetector = useNewPoseDetector;
  }

  /**
   * Initialize the pullup tracker
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
      if (this.useNewPoseDetector) {
        // Initialize the new BlazePose detector
        this.poseDetector = new PoseDetector();
        await this.poseDetector.init('/models/pose_landmarker_full.task');
        // Start rear camera by default
        if (!this.videoRef?.current) {
          this.setError(TrackerErrorType.UNKNOWN, 'Video element not available');
          return;
        }

        const camOk = await cameraManager.startCamera(this.videoRef.current, { facingMode: 'environment' });
        if (!camOk) {
          const errMsg = cameraManager.getError()?.message || 'Failed to start camera';
          this.setError(TrackerErrorType.CAMERA_PERMISSION, errMsg);
          return;
        }

        this._status = SessionStatus.READY;
        this._error = null;
      } else {
        // Initialize pose detector with the provided video element
        await poseDetectorService.initialize();
        this._status = SessionStatus.READY;
        this._error = null;
      }
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

    if (this.useNewPoseDetector) {
      // Start the animation frame loop for the new detector
      if (this.canvasRef?.current && this.videoRef?.current) {
        this.canvasRef.current.width = this.videoRef.current.videoWidth;
        this.canvasRef.current.height = this.videoRef.current.videoHeight;
      }
      this.animationFrameId = requestAnimationFrame(this.processPoseFrame);
    } else {
      // Start pose detection with callback to handle results
      poseDetectorService.start(
        this.videoRef.current,
        this.canvasRef?.current || undefined,
        this.handlePoseResults
      );
    }

    // Start timer
    this.startTimer();

    this._status = SessionStatus.ACTIVE;
  }

  /**
   * Process frame from new BlazePose detector
   */
  private processPoseFrame = (): void => {
    if (!this.poseDetector || !this.videoRef?.current || this._status !== SessionStatus.ACTIVE) {
      this.animationFrameId = null;
      return;
    }
    
    const result = this.poseDetector.detect(this.videoRef.current);
    
    if (result && result.landmarks) {
      // Process the landmarks through the grader instead of analyzer
      const gradingResult = this.grader.processPose(result.landmarks);
      
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
      
      // Optional drawing on canvas if available
      if (this.canvasRef?.current && result.landmarks) {
        PoseDetector.draw(
          this.canvasRef.current,
          this.videoRef.current,
          result.landmarks
        );
      }
    }
    
    this.animationFrameId = requestAnimationFrame(this.processPoseFrame);
  };

  /**
   * Handle pose detection results from legacy PoseDetectorService
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
  private lastAnalysis: PullupFormAnalysis | null = null;

  /**
   * Clean up resources when component unmounts
   */
  cleanup(): void {
    if (this.useNewPoseDetector) {
      // Cancel any pending animation frames
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
      cameraManager.removeConsumer();
    } else {
      poseDetectorService.stop();
      poseDetectorService.releaseConsumer();
    }
    this.stopTimer();
  }

  /**
   * Pause the tracking session
   */
  pauseSession(): void {
    if (this._status !== SessionStatus.ACTIVE) {
      return; // Not active
    }

    if (this.useNewPoseDetector) {
      // Cancel the animation frame loop
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
    } else {
      // Stop pose detection
      poseDetectorService.stop();
    }

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
      if (this.useNewPoseDetector) {
        // Cancel the animation frame loop
        if (this.animationFrameId !== null) {
          cancelAnimationFrame(this.animationFrameId);
          this.animationFrameId = null;
        }
      } else {
        poseDetectorService.stop();
      }
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
        exercise_id: ExerciseId.PULLUP,
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
      console.error("Failed to save pullup results:", error);
      
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
      const queued = await syncManager.queueWorkout(this._result!, ExerciseId.PULLUP);
      
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
      console.error("Failed to save pullup results offline:", error);
      
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

  /** Flip camera */
  async flipCamera(): Promise<void> {
    if (!this.videoRef?.current) return;
    try {
      const ok = await cameraManager.switchFacing();
      if (ok) this.facingMode = cameraManager.getFacingMode();
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Unknown error';
      this.setError(TrackerErrorType.CAMERA_PERMISSION, msg);
    }
  }
}

/**
 * React hook that provides the PullupTrackerViewModel
 */
export function usePullupTrackerViewModel(useNewPoseDetector = true) {
  // State to hold the ViewModel and trigger re-renders on changes
  const [viewModel] = useState<PullupTrackerViewModel>(() => new PullupTrackerViewModel(useNewPoseDetector));
  
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
  
  const flipCamera = useCallback(async () => {
    await viewModel.flipCamera();
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
    saveResults,
    flipCamera
  };
}

export default usePullupTrackerViewModel; 