/**
 * PushupTrackerViewModel.ts
 * 
 * ViewModel for pushup tracking session. 
 * Coordinates between PoseDetectorService, PushupAnalyzer, and UI components.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { NormalizedLandmark, PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { ExerciseType } from '../grading';
import { PushupAnalyzer, PushupFormAnalysis } from '../grading/PushupAnalyzer';
import { poseDetectorService } from '../services/PoseDetectorService';
import { logExercise } from '../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../lib/types';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';

/**
 * Class implementation of PushupTrackerViewModel
 */
export class PushupTrackerViewModel extends BaseTrackerViewModel {
  private videoRef: React.RefObject<HTMLVideoElement> | null = null;
  private canvasRef: React.RefObject<HTMLCanvasElement> | null = null;
  private analyzer: PushupAnalyzer;
  private submitting: boolean = false;

  constructor() {
    super(ExerciseType.PUSHUP);
    this.analyzer = new PushupAnalyzer();
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
      // Initialize MediaPipe pose detection
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

      this._status = SessionStatus.READY;
      this._isInitialized = true;

    } catch (error) {
      console.error("Error initializing pushup tracker:", error);
      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      this.setError(TrackerErrorType.MODEL_LOAD_FAILED, errorMessage);
    }
  }

  /**
   * Handle pose detection results
   */
  private handlePoseResults = (result: PoseLandmarkerResult): void => {
    if (result.landmarks && result.landmarks.length > 0) {
      const landmarks = result.landmarks[0];
      const timestamp = Date.now();
      
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
      
      // Update form score based on angles and position
      const elbowAngle = Math.min(analysis.leftElbowAngle, analysis.rightElbowAngle);
      const formScore = analysis.isValidRep ? 100 : 70;
      this._formScore = formScore;
      
      // Store the last analysis for next comparison
      this.lastAnalysis = analysis;
    }
  };

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

    // Start pose detection with callback to process results
    const detectionStarted = poseDetectorService.startDetection(
      this.videoRef.current,
      this.canvasRef?.current || null,
      this.handlePoseResults
    );

    if (!detectionStarted) {
      this.setError(TrackerErrorType.UNKNOWN, "Failed to start pose detection");
      return;
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
        exercise_id: 1, // ID for pushups
        reps: this._result.repCount || 0,
        duration: this._result.duration,
        notes: `Form Score: ${this._result.formScore?.toFixed(0)}`
      };

      // Call the API
      const response: ExerciseResponse = await logExercise(exerciseData);
      
      // Update result with grade and saved status
      this._result.grade = response.grade;
      this._result.saved = true;
      
      return true;
    } catch (error) {
      console.error("Failed to save pushup results:", error);
      return false;
    } finally {
      this.submitting = false;
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

    // Stop detection if running
    poseDetectorService.stopDetection();
    
    // Stop camera stream
    poseDetectorService.stopCamera();
    
    // Close pose landmarker
    poseDetectorService.destroy();
  }
}

/**
 * React hook that provides the PushupTrackerViewModel
 */
export function usePushupTrackerViewModel() {
  // State to hold the ViewModel and trigger re-renders on changes
  const [viewModel] = useState<PushupTrackerViewModel>(() => new PushupTrackerViewModel());
  
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

export default usePushupTrackerViewModel; 