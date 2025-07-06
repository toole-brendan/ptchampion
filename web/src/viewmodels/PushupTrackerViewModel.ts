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
import { createGrader } from '../grading';
import { createExerciseGrader } from '../grading/graders';
import { BaseGrader } from '../grading/graders/BaseGrader';
// Remove eager import - will load lazily
// import { poseDetectorService } from '@/services/PoseDetectorService';
import { workoutSyncService } from '../services/WorkoutSyncService';
import { convertToWorkoutRequest } from '../services/workoutHelpers';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';
import { Subscription } from 'rxjs';
import { ExerciseId } from '../constants/exercises';
import { PoseDetector } from '../services/poseDetector';
import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import cameraManager, { CameraOptions } from '@/services/CameraManager';
import { logger } from '@/lib/logger';

/**
 * Class implementation of PushupTrackerViewModel
 */
export class PushupTrackerViewModel extends BaseTrackerViewModel {
  private videoRef: React.RefObject<HTMLVideoElement> | null = null;
  private canvasRef: React.RefObject<HTMLCanvasElement> | null = null;
  private analyzer: PushupAnalyzer;
  private grader: BaseGrader;
  private submitting: boolean = false;
  private poseSubscription: Subscription | null = null;
  
  // New BlazePose detector properties
  private useNewPoseDetector: boolean = false;
  private poseDetector: PoseDetector | null = null;
  private animationFrameId: number | null = null;
  private facingMode: 'user' | 'environment' = 'environment';
  
  // Lazy-loaded pose detector service
  private poseDetectorService: typeof import('@/services/PoseDetectorService').default | null = null;

  constructor(useNewPoseDetector = false) {
    super(ExerciseType.PUSHUP);
    this.analyzer = new PushupAnalyzer();
    this.grader = createExerciseGrader(ExerciseType.PUSHUP) as BaseGrader;
    this.useNewPoseDetector = useNewPoseDetector;
    
    // Enable countdown timer for pushups
    this._useCountdown = true;
    this._countdownDuration = 120; // 2 minutes
    this._timer = this._countdownDuration; // Initialize timer to countdown value
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
        // Legacy initialization - Lazy load and use MediaPipe pose detection
        if (!this.poseDetectorService) {
          const { default: poseDetectorService } = await import('@/services/PoseDetectorService');
          this.poseDetectorService = poseDetectorService;
        }
        
        await this.poseDetectorService.initialize({
          minPoseDetectionConfidence: 0.7,
          minPosePresenceConfidence: 0.7
        });

        // Start camera
        if (this.videoRef?.current) {
          const cameraStarted = await this.poseDetectorService.startCamera(this.videoRef.current);
          
          if (!cameraStarted) {
            const errorMessage = this.poseDetectorService.getModelError() || "Failed to start camera";
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
      logger.error("Error initializing pushup tracker:", error);
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
          result.landmarks,
          this._problemJoints
        );
      }
    }
    
    this.animationFrameId = requestAnimationFrame(this.processPoseFrame);
  };

  /**
   * Common processing of pose data from either source
   */
  private processPoseData(landmarks: NormalizedLandmark[], timestamp: number): void {
    // Process the landmarks through the grader
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
    
    // Update problem joints
    this._problemJoints = this.grader.getProblemJoints();
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

    // Reset the analyzer and grader to ensure clean state
    this.analyzer.reset();
    this.grader.reset();
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
      // Ensure pose detector service is loaded
      if (!this.poseDetectorService) {
        this.setError(TrackerErrorType.MODEL_LOAD_FAILED, "Pose detector service not loaded");
        return;
      }
      
      // Subscribe to the pose$ stream for continuous updates with legacy detector
      this.poseSubscription = this.poseDetectorService.pose$.subscribe(this.handlePoseResults);

      // Start pose detection
      const detectionStarted = this.poseDetectorService.start(
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
      // Stop pose detection if service is loaded
      if (this.poseDetectorService) {
        this.poseDetectorService.stop();
      }

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
        // Stop pose detection if service is loaded
        if (this.poseDetectorService) {
          this.poseDetectorService.stop();
        }
        
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
      duration: this.getElapsedDuration(), // Use actual elapsed time
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
      // Convert exercise result to workout request format
      const workoutRequest = convertToWorkoutRequest(this._result);
      
      // Submit workout through sync service (handles online/offline automatically)
      await workoutSyncService.submitWorkout(workoutRequest);
      
      // Update result to indicate it was saved
      this._result.saved = true;
      
      // Show appropriate toast notification
      if (typeof window !== 'undefined' && window.showToast) {
        if (navigator.onLine) {
          window.showToast({ 
            title: 'Workout Saved', 
            description: 'Your pushup workout has been saved successfully.', 
            variant: 'success' 
          });
        } else {
          window.showToast({
            title: 'Workout Saved Offline',
            description: 'Your workout has been saved and will sync when you\'re back online.',
            variant: 'success'
          });
        }
      }
      
      return true;
    } catch (error) {
      logger.error("Failed to save pushup results:", error);
      
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
   * @deprecated Use workoutSyncService.submitWorkout instead
   */
  private async saveOffline(): Promise<boolean> {
    // This method is now deprecated as workoutSyncService handles offline saving automatically
    logger.warn('saveOffline is deprecated, use workoutSyncService.submitWorkout instead');
    return false;
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
    this.grader.reset();
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

      // Stop detection if running and service is loaded
      if (this.poseDetectorService) {
        this.poseDetectorService.stop();
        
        // Stop camera stream
        this.poseDetectorService.stopCamera();
        
        // Release consumer reference
        this.poseDetectorService.releaseConsumer();
      }
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
      logger.error('Failed to switch camera', err);
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
  const problemJointsRef = useRef(viewModel.problemJoints);
  const errorRef = useRef(viewModel.error);
  const resultRef = useRef(viewModel.result);
  
  // State for UI updates
  const [repCount, setRepCount] = useState(viewModel.repCount);
  const [timer, setTimer] = useState(viewModel.timer);
  const [status, setStatus] = useState(viewModel.status);
  const [formScore, setFormScore] = useState(viewModel.formScore);
  const [formFeedback, setFormFeedback] = useState(viewModel.formFeedback);
  const [problemJoints, setProblemJoints] = useState(viewModel.problemJoints);
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
      
      if (JSON.stringify(viewModel.problemJoints) !== JSON.stringify(problemJointsRef.current)) {
        problemJointsRef.current = viewModel.problemJoints;
        setProblemJoints(viewModel.problemJoints);
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
  
  const setTimerExpiredCallback = useCallback((callback: () => void) => {
    viewModel.setTimerExpiredCallback(callback);
  }, [viewModel]);
  
  // Return the state and methods
  return {
    // State
    repCount,
    timer,
    status,
    formScore,
    formFeedback,
    problemJoints,
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
    flipCamera,
    setTimerExpiredCallback
  };
}

export default usePushupTrackerViewModel; 