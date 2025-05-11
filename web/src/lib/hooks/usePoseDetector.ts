import { useCallback, useEffect, useRef, useState } from 'react';
import poseDetectorService from '../../services/PoseDetectorService';
import { PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { PoseLandmarkIndex } from '../../services/PoseLandmarkIndex';

// Re-export the landmark index enum for backward compatibility
export { PoseLandmarkIndex };

// Pose landmark indices based on MediaPipe's pose landmark model
// https://developers.google.com/mediapipe/solutions/vision/pose_landmarker#pose_landmarker_model
export enum PoseLandmarkIndex {
  NOSE = 0,
  // Eyes
  LEFT_EYE_INNER = 1,
  LEFT_EYE = 2,
  LEFT_EYE_OUTER = 3,
  RIGHT_EYE_INNER = 4,
  RIGHT_EYE = 5,
  RIGHT_EYE_OUTER = 6,
  // Ears
  LEFT_EAR = 7,
  RIGHT_EAR = 8,
  // Mouth
  MOUTH_LEFT = 9,
  MOUTH_RIGHT = 10,
  // Shoulders
  LEFT_SHOULDER = 11,
  RIGHT_SHOULDER = 12,
  // Elbows
  LEFT_ELBOW = 13,
  RIGHT_ELBOW = 14,
  // Wrists
  LEFT_WRIST = 15,
  RIGHT_WRIST = 16,
  // Thumbs
  LEFT_PINKY = 17,
  RIGHT_PINKY = 18,
  LEFT_INDEX = 19,
  RIGHT_INDEX = 20,
  LEFT_THUMB = 21,
  RIGHT_THUMB = 22,
  // Hips
  LEFT_HIP = 23,
  RIGHT_HIP = 24,
  // Knees
  LEFT_KNEE = 25,
  RIGHT_KNEE = 26,
  // Ankles
  LEFT_ANKLE = 27,
  RIGHT_ANKLE = 28,
  // Heels
  LEFT_HEEL = 29,
  RIGHT_HEEL = 30,
  // Foot index (toes)
  LEFT_FOOT_INDEX = 31,
  RIGHT_FOOT_INDEX = 32,
}

// Configuration options for the pose detector
export interface PoseDetectorOptions {
  minPoseDetectionConfidence?: number;
  minPosePresenceConfidence?: number;
  minTrackingConfidence?: number;
  enableSegmentation?: boolean;
  modelType?: 'LITE' | 'FULL' | 'HEAVY';
  smoothLandmarks?: boolean;
}

// Simple landmark type to match MediaPipe's NormalizedLandmark format
export interface Landmark {
  x: number;
  y: number;
  z: number;
  visibility?: number;
}

// Type for the Pose Detection result
export interface PoseDetectionResult {
  landmarks: Landmark[][] | undefined;
  worldLandmarks: Landmark[][] | undefined;
  isLoading: boolean;
  error: Error | null;
}

/**
 * @deprecated Use the poseDetectorService directly instead
 * 
 * Hook for detecting poses in video frames using MediaPipe
 * This is maintained for backward compatibility and is a thin wrapper
 * around the PoseDetectorService.
 * 
 * @param videoRef - React ref to the video element
 * @param canvasRef - React ref to the canvas element for visualization
 * @param options - Configuration options for the pose detector
 */
export function usePoseDetector(
  videoRef: React.RefObject<HTMLVideoElement>,
  canvasRef?: React.RefObject<HTMLCanvasElement>,
  options?: PoseDetectorOptions
) {
  // State to track the pose detection result
  const [result, setResult] = useState<PoseDetectionResult>({
    landmarks: undefined,
    worldLandmarks: undefined,
    isLoading: true,
    error: null,
  });

  // State for tracking service status
  const [isDetectorReady, setIsDetectorReady] = useState(false);
  const [isRunning, setIsRunning] = useState(false);
  
  // Subscription reference for cleanup
  const subscriptionRef = useRef<{ unsubscribe: () => void } | null>(null);
  
  // Initialize the service when component mounts
  useEffect(() => {
    async function initializeDetector() {
      try {
        setResult(prev => ({ ...prev, isLoading: true, error: null }));
        
        // Convert from old options format to new format
        const detectorOptions = {
          minPoseDetectionConfidence: options?.minPoseDetectionConfidence,
          minPosePresenceConfidence: options?.minPosePresenceConfidence,
          minTrackingConfidence: options?.minTrackingConfidence,
          // Model path selection based on modelType
          modelPath: options?.modelType ? 
            `/models/pose_landmarker_${options.modelType.toLowerCase()}.task` : 
            undefined
        };
        
        await poseDetectorService.initialize(detectorOptions);
        setIsDetectorReady(true);
        setResult(prev => ({ ...prev, isLoading: false }));
        
      } catch (error) {
        console.error("Error initializing pose detector:", error);
        setResult(prev => ({ 
          ...prev, 
          isLoading: false, 
          error: error instanceof Error ? error : new Error(String(error)) 
        }));
      }
    }
    
    initializeDetector();
    
    // Cleanup on unmount
    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
      
      if (isRunning) {
        poseDetectorService.stop();
        setIsRunning(false);
      }
      
      // Don't destroy the service as it may be used by other components
      poseDetectorService.releaseConsumer();
    };
  }, [options]);
  
  // Subscribe to pose events
  useEffect(() => {
    if (isDetectorReady) {
      // Subscribe to pose events
      subscriptionRef.current = poseDetectorService.pose$.subscribe(
        (poseResult: PoseLandmarkerResult) => {
          setResult(prev => ({
            ...prev,
            landmarks: poseResult.landmarks,
            worldLandmarks: poseResult.worldLandmarks,
          }));
        }
      );
    }
    
    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
        subscriptionRef.current = null;
      }
    };
  }, [isDetectorReady]);
  
  // Function to start pose detection
  const startDetection = useCallback(() => {
    if (isDetectorReady && !isRunning && videoRef.current) {
      const started = poseDetectorService.start(
        videoRef.current,
        canvasRef?.current || null
      );
      
      if (started) {
        setIsRunning(true);
      }
    }
  }, [canvasRef, isDetectorReady, isRunning, videoRef]);
  
  // Function to stop pose detection
  const stopDetection = useCallback(() => {
    if (isRunning) {
      poseDetectorService.stop();
      setIsRunning(false);
    }
  }, [isRunning]);
  
  return {
    ...result,
    isDetectorReady,
    isRunning,
    startDetection,
    stopDetection,
  };
}

export default usePoseDetector; 