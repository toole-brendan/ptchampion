/**
 * PushupTrackerViewModel.ts
 * 
 * ViewModel for pushup tracking session. 
 * Coordinates between PoseDetectorService, PushupAnalyzer, and UI components.
 * Now updated to support both legacy PoseDetectorService and new BlazePose Full model.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { ExerciseType } from '../grading';
import { PushupAnalyzer, PushupFormAnalysis } from '../grading/PushupAnalyzer';
import { poseDetectorService } from '@/services/PoseDetectorService';
import { logExerciseResult } from '../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../lib/types';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';
import { Subscription } from 'rxjs';
import { ExerciseId } from '../constants/exercises';
import { PoseDetector } from '../services/poseDetector';
import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import cameraManager, { CameraOptions } from '@/services/CameraManager';

/**
 * Class implementation of PushupTrackerViewModel
 */
export class PushupTrackerViewModel extends BaseTrackerViewModel {
  private videoRef: React.RefObject<HTMLVideoElement> | null = null;
  private canvasRef: React.RefObject<HTMLCanvasElement> | null = null;
  private analyzer: PushupAnalyzer;
  private submitting: boolean = false;
  private poseSubscription: Subscription | null = null;
  
  // New BlazePose detector properties
  private useNewPoseDetector: boolean = false;
  private poseDetector: PoseDetector | null = null;
  private animationFrameId: number | null = null;
  private facingMode: 'user' | 'environment' = 'environment';

  constructor(useNewPoseDetector = false) {
    super(ExerciseType.PUSHUP);
    this.analyzer = new PushupAnalyzer();
    this.useNewPoseDetector = useNewPoseDetector;
  }

  /**
   * Initialize the ViewModel with video and canvas elements
   */
  async initialize(
    videoRef: React.RefObject<HTMLVideoElement>, 
    canvasRef?: React.RefObject<HTMLCanvasElement>
  ): Promise<void> {
    if (this._isInitialized) {
      return;
    }

    this._status = SessionStatus.INITIALIZING;
    this.videoRef = videoRef;
    this.canvasRef = canvasRef || null;

    try {
      if (this.useNewPoseDetector) {
        // Initialize the new BlazePose detector
        this.poseDetector = new PoseDetector();
        await this.poseDetector.init('/models/pose_landmarker_full.task');
        
        // Start camera using CameraManager for new detector approach
        if (!this.videoRef?.current) {
          this.setError(TrackerErrorType.UNKNOWN, "Video element not available");
          return;
        }
        
        // Start the camera with appropriate configuration
        const cameraStarted = await cameraManager.startCamera(this.videoRef.current, { 
          facingMode: 'environment' // Use back camera for better pose tracking
        });
        
        if (!cameraStarted) {
          // Get error reason from camera manager
          const errorMessage = cameraManager.getError()?.message || "Failed to start camera";
          this.setError(TrackerErrorType.CAMERA_PERMISSION, errorMessage);
          return;
        }
      } else {
        // Legacy initialization - Use MediaPipe pose detection
        await poseDetectorService.initialize({
          minPoseDetectionConfidence: 0.7,
          minPosePresenceConfidence: 0.7
        });

        // Start camera
        if (this.videoRef?.current) {
          const cameraStarted = await poseDetectorService.startCamera(this.videoRef.current);
          
          if (!cameraStarted) {
            const errorMessage = poseDetectorService.getModelError() || "Failed to start camera";
            this.setError(TrackerErrorType.CAMERA_PERMISSION, errorMessage);
            return;
          }
        } else {
          this.setError(TrackerErrorType.UNKNOWN, "Video element not available");
          return;
        }
      }

      this._status = SessionStatus.READY;
      this._isInitialized = true;

    } catch (error) {
      console.error("Error initializing pushup tracker:", error);
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      this.setError(TrackerErrorType.MODEL_LOAD_FAILED, errorMessage);
    }
  }

  /**
   * Handle pose detection results from legacy PoseDetectorService
   */
  private handlePoseResults = (result: PoseLandmarkerResult): void => {
    if (result.landmarks && result.landmarks.length > 0) {
      const landmarks = result.landmarks[0];
      const timestamp = Date.now();
      this.processPoseData(landmarks, timestamp);
    }
  };

  /**
   * Process frame from new BlazePose detector
   */
  private processPoseFrame = (): void => {
    if (!this.poseDetector || !this.videoRef?.current || this._status !== SessionStatus.ACTIVE) {
      this.animationFrameId = null;
      return;
    }
    
    const video = this.videoRef.current;
    
    // Guard against uninitialized video or zero-dimension frames
    if (video.readyState < 2 || video.videoWidth === 0 || video.videoHeight === 0) {
      // Schedule next frame but don't process this one
      this.animationFrameId = requestAnimationFrame(this.processPoseFrame);
      return;
    }
    
    const result = this.poseDetector.detect(this.videoRef.current);
    
    if (result && result.landmarks) {
      this.processPoseData(result.landmarks, result.timestamp);
      
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
   * Common processing of pose data from either source
   */
  private processPoseData(landmarks: NormalizedLandmark[], timestamp: number): void {
    // Process the landmarks through the analyzer
    const analysis = this.analyzer.analyzePushupForm(landmarks, timestamp);

    // Check if this is a completed rep
    if (this.lastAnalysis && !this.lastAnalysis.isUpPosition && analysis.isUpPosition) {
      // A rep is completed when transitioning from down to up position
      if (analysis.isValidRep) {
        this._repCount += 1;
      }
    }

    // Update form feedback if there are issues
    if (analysis.isBodySagging) {
      this._formFeedback = "Body sagging";
    } else if (analysis.isBodyPiking) {
      this._formFeedback = "Body piking";
    } else if (analysis.isWorming) {
      this._formFeedback = "Worming detected";
    } else if (analysis.handsLiftedOff) {
      this._formFeedback = "Hands lifted off ground";
    } else if (analysis.feetLiftedOff) {
      this._formFeedback = "Feet lifted off ground";
    } else if (analysis.kneesTouchingGround) {
      this._formFeedback = "Knees touching ground";
    } else if (analysis.bodyTouchingGround) {
      this._formFeedback = "Body touching ground";
    } else if (analysis.isPaused) {
      this._formFeedback = "Paused too long";
    } else {
      this._formFeedback = null;
    }

    const formScore = analysis.isValidRep ? 100 : 70;
    this._formScore = formScore;

    // Store the last analysis for next comparison
    this.lastAnalysis = analysis;
  }

  // Store the last analysis for rep counting
  private lastAnalysis: PushupFormAnalysis | null = null;

  /**
   * Start or resume the tracking session
   */
  startSession(): void {
    if (this._status === SessionStatus.ACTIVE) {
      return; // Already active
    }

    if (!this._isInitialized || !this.videoRef?.current) {
      this.setError(TrackerErrorType.UNKNOWN, "Tracker not properly initialized");
      return;
    }

    // Reset the analyzer to ensure clean state
    this.analyzer.reset();
    this.lastAnalysis = null;

    if (this.useNewPoseDetector) {
      // Ensure canvas dimensions match video before starting detection
      if (this.canvasRef?.current && this.videoRef.current) {
        this.canvasRef.current.width = this.videoRef.current.videoWidth;
        this.canvasRef.current.height = this.videoRef.current.videoHeight;
      }
      
      // Start the animation frame loop for the new detector
      this.animationFrameId = requestAnimationFrame(this.processPoseFrame);
    } else {
      // Subscribe to the pose$ stream for continuous updates with legacy detector
      this.poseSubscription = poseDetectorService.pose$.subscribe(this.handlePoseResults);

      // Start pose detection
      const detectionStarted = poseDetectorService.start(
        this.videoRef.current,
        this.canvasRef?.current || null
      );

      if (!detectionStarted) {
        if (this.poseSubscription) {
          this.poseSubscription.unsubscribe();
          this.poseSubscription = null;
        }
        this.setError(TrackerErrorType.UNKNOWN, "Failed to start pose detection");
        return;
      }
    }

    // Start timer to track duration
    this.startTimer();

    this._status = SessionStatus.ACTIVE;
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

      // Unsubscribe from pose events
      if (this.poseSubscription) {
        this.poseSubscription.unsubscribe();
        this.poseSubscription = null;
      }
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
        
        // Unsubscribe from pose events
        if (this.poseSubscription) {
          this.poseSubscription.unsubscribe();
          this.poseSubscription = null;
        }
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
        exercise_id: ExerciseId.PUSHUP,
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
      console.error("Failed to save pushup results:", error);
      
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
      const queued = await syncManager.queueWorkout(this._result!, ExerciseId.PUSHUP);
      
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
      console.error("Failed to save pushup results offline:", error);
      
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
  }

  /**
   * Clean up resources when unmounting
   */
  cleanup(): void {
    super.cleanup();

    if (this.useNewPoseDetector) {
      // Cancel any pending animation frames
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
      
      // Release camera resources for the new detector approach
      cameraManager.removeConsumer();
    } else {
      // Unsubscribe from pose events
      if (this.poseSubscription) {
        this.poseSubscription.unsubscribe();
        this.poseSubscription = null;
      }

      // Stop detection if running
      poseDetectorService.stop();
      
      // Stop camera stream
      poseDetectorService.stopCamera();
      
      // Release consumer reference
      poseDetectorService.releaseConsumer();
    }
  }

  /**
   * Flip between front and rear cameras (mobile only)
   */
  async flipCamera(): Promise<void> {
    if (!this.videoRef?.current) return;
    try {
      const success = await cameraManager.switchFacing();
      if (success) {
        this.facingMode = cameraManager.getFacingMode();
      }
    } catch (err) {
      console.error('Failed to switch camera', err);
      const msg = err instanceof Error ? err.message : 'Unknown error';
      this.setError(TrackerErrorType.CAMERA_PERMISSION, msg);
    }
  }
}

/**
 * React hook that provides the PushupTrackerViewModel
 */
export function usePushupTrackerViewModel(useNewPoseDetector = true) {
  // State to hold the ViewModel and trigger re-renders on changes
  const [viewModel] = useState<PushupTrackerViewModel>(() => new PushupTrackerViewModel(useNewPoseDetector));
  
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
  
  // Polling effect to update React state from ViewModel
  useEffect(() => {
    const intervalId = setInterval(() => {
      // Only update states that have changed to avoid unnecessary renders
      if (viewModel.repCount !== repCountRef.current) {
        repCountRef.current = viewModel.repCount;
        setRepCount(viewModel.repCount);
      }
      
      if (viewModel.timer !== timerRef.current) {
        timerRef.current = viewModel.timer;
        setTimer(viewModel.timer);
      }
      
      if (viewModel.status !== statusRef.current) {
        statusRef.current = viewModel.status;
        setStatus(viewModel.status);
      }
      
      if (viewModel.formScore !== formScoreRef.current) {
        formScoreRef.current = viewModel.formScore;
        setFormScore(viewModel.formScore);
      }
      
      if (viewModel.formFeedback !== formFeedbackRef.current) {
        formFeedbackRef.current = viewModel.formFeedback;
        setFormFeedback(viewModel.formFeedback);
      }
      
      if (viewModel.error !== errorRef.current) {
        errorRef.current = viewModel.error;
        setError(viewModel.error);
      }
      
      if (viewModel.result !== resultRef.current) {
        resultRef.current = viewModel.result;
        setResult(viewModel.result);
      }
    }, 100); // Poll 10 times per second
    
    return () => clearInterval(intervalId);
  }, [viewModel]);
  
  // Cleanup when component unmounts
  useEffect(() => {
    return () => viewModel.cleanup();
  }, [viewModel]);
  
  // Wrap ViewModel methods to keep React state in sync
  const initialize = useCallback(async (
    videoRef: React.RefObject<HTMLVideoElement>,
    canvasRef?: React.RefObject<HTMLCanvasElement>
  ) => {
    await viewModel.initialize(videoRef, canvasRef);
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

export default usePushupTrackerViewModel; 