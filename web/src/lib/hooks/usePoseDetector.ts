import { useCallback, useEffect, useRef, useState } from 'react';
import { PoseLandmarkerResult } from '@mediapipe/tasks-vision';
import { PoseLandmarkIndex as ImportedPoseLandmarkIndex } from '@/services/PoseLandmarkIndex';

// Re-export the imported landmark index
export { ImportedPoseLandmarkIndex as PoseLandmarkIndex };

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
  
  // Lazy-loaded pose detector service
  const poseDetectorServiceRef = useRef<typeof import('@/services/PoseDetectorService').default | null>(null);
  
  // Subscription reference for cleanup
  const subscriptionRef = useRef<{ unsubscribe: () => void } | null>(null);
  
  // Initialize the service when component mounts
  useEffect(() => {
    async function initializeDetector() {
      try {
        setResult(prev => ({ ...prev, isLoading: true, error: null }));
        
        // Lazy load the pose detector service
        if (!poseDetectorServiceRef.current) {
          const { default: poseDetectorService } = await import('@/services/PoseDetectorService');
          poseDetectorServiceRef.current = poseDetectorService;
        }
        
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
        
        await poseDetectorServiceRef.current.initialize(detectorOptions);
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
      
      if (isRunning && poseDetectorServiceRef.current) {
        poseDetectorServiceRef.current.stop();
        setIsRunning(false);
      }
      
      // Don't destroy the service as it may be used by other components
      if (poseDetectorServiceRef.current) {
        poseDetectorServiceRef.current.releaseConsumer();
      }
    };
  }, [options, isRunning]);
  
  // Subscribe to pose events
  useEffect(() => {
    if (isDetectorReady && poseDetectorServiceRef.current) {
      // Subscribe to pose events
      subscriptionRef.current = poseDetectorServiceRef.current.pose$.subscribe(
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
    if (isDetectorReady && !isRunning && videoRef.current && poseDetectorServiceRef.current) {
      const started = poseDetectorServiceRef.current.start(
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
    if (isRunning && poseDetectorServiceRef.current) {
      poseDetectorServiceRef.current.stop();
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