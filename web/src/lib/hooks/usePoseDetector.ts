import { useCallback, useEffect, useRef, useState } from 'react';

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

// Default configuration values
const DEFAULT_OPTIONS: PoseDetectorOptions = {
  minPoseDetectionConfidence: 0.5,
  minPosePresenceConfidence: 0.5,
  minTrackingConfidence: 0.5,
  enableSegmentation: false,
  modelType: 'LITE',
  smoothLandmarks: true,
};

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

// MediaPipe model URLs based on model type
const MODEL_URLS = {
  'LITE': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
  'FULL': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task',
  'HEAVY': 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task',
};

/**
 * Hook for detecting poses in video frames using MediaPipe
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
  const [result, setResult] = useState<PoseDetectionResult>({
    landmarks: undefined,
    worldLandmarks: undefined,
    isLoading: true,
    error: null,
  });

  // Keep track of whether the detector is ready
  const [isDetectorReady, setIsDetectorReady] = useState(false);
  
  // Detector is processing frames
  const [isRunning, setIsRunning] = useState(false);
  
  // Last processed video time to avoid processing the same frame
  const lastVideoTimeRef = useRef<number>(-1);
  
  // Merge default options with provided options
  const detectorOptions = { ...DEFAULT_OPTIONS, ...options };

  // Reference to store the MediaPipe PoseLandmarker instance
  const poseLandmarkerRef = useRef<any>(null);
  
  // Reference to store the animation frame ID for cleanup
  const animationFrameRef = useRef<number | null>(null);
  
  // Function to initialize the pose landmarker with MediaPipe
  const createPoseLandmarker = useCallback(async () => {
    try {
      setResult(prev => ({ ...prev, isLoading: true, error: null }));
      
      // Dynamically import MediaPipe to avoid bloating the initial bundle
      const { FilesetResolver, PoseLandmarker } = await import('@mediapipe/tasks-vision');
      
      // Initialize the vision task resolver
      const vision = await FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm'
      );
      
      // Get the model URL based on the selected model type
      const modelType = detectorOptions.modelType || 'LITE';
      const modelUrl = MODEL_URLS[modelType];
      
      // Create the pose landmarker
      poseLandmarkerRef.current = await PoseLandmarker.createFromOptions(vision, {
        baseOptions: {
          modelAssetPath: modelUrl,
          delegate: 'GPU'
        },
        runningMode: 'VIDEO',
        numPoses: 1,
        minPoseDetectionConfidence: detectorOptions.minPoseDetectionConfidence,
        minPosePresenceConfidence: detectorOptions.minPosePresenceConfidence,
        minTrackingConfidence: detectorOptions.minTrackingConfidence,
        enableSegmentation: detectorOptions.enableSegmentation,
        smoothLandmarks: detectorOptions.smoothLandmarks
      });
      
      setIsDetectorReady(true);
      setResult(prev => ({ ...prev, isLoading: false }));
      
    } catch (error) {
      console.error("Error creating pose landmarker:", error);
      setResult(prev => ({ 
        ...prev, 
        isLoading: false, 
        error: error instanceof Error ? error : new Error(String(error)) 
      }));
    }
  }, [detectorOptions]);
  
  // Initialize pose landmarker when the component mounts
  useEffect(() => {
    createPoseLandmarker();
    
    // Cleanup function to close the landmarker when component unmounts
    return () => {
      if (poseLandmarkerRef.current) {
        poseLandmarkerRef.current.close();
        poseLandmarkerRef.current = null;
      }
      
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
        animationFrameRef.current = null;
      }
    };
  }, [createPoseLandmarker]);
  
  // Function to detect poses in a single frame
  const detectFrame = useCallback(async () => {
    if (!poseLandmarkerRef.current || !videoRef.current || !isDetectorReady || !isRunning) {
      return;
    }
    
    const video = videoRef.current;
    
    // Skip if video is not ready or time hasn't changed (paused)
    if (video.currentTime === lastVideoTimeRef.current || video.paused || video.ended) {
      // Schedule next frame detection
      animationFrameRef.current = requestAnimationFrame(detectFrame);
      return;
    }
    
    lastVideoTimeRef.current = video.currentTime;
    
    try {
      // Perform the actual pose detection using MediaPipe
      const landmarkerResult = poseLandmarkerRef.current.detectForVideo(video, performance.now());
      
      // Update result state with real landmarks
      setResult(prev => ({
        ...prev,
        landmarks: landmarkerResult.landmarks,
        worldLandmarks: landmarkerResult.worldLandmarks,
      }));
      
      // Draw landmarks on canvas if available
      if (canvasRef?.current && landmarkerResult.landmarks?.length) {
        drawLandmarks(
          canvasRef.current, 
          landmarkerResult.landmarks[0], 
          video.videoWidth, 
          video.videoHeight
        );
      }
    } catch (error) {
      console.error("Error during pose detection:", error);
    }
    
    // Continue detection loop
    if (isRunning) {
      animationFrameRef.current = requestAnimationFrame(detectFrame);
    }
  }, [videoRef, canvasRef, isDetectorReady, isRunning]);
  
  // Function to draw landmarks on canvas
  const drawLandmarks = (
    canvas: HTMLCanvasElement, 
    landmarks: Landmark[], 
    videoWidth: number, 
    videoHeight: number
  ) => {
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // Set canvas size to match video dimensions
    if (canvas.width !== videoWidth || canvas.height !== videoHeight) {
      canvas.width = videoWidth;
      canvas.height = videoHeight;
    }
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Define connections between landmarks to draw skeleton
    const connections = [
      // Torso
      [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.RIGHT_SHOULDER],
      [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.LEFT_HIP],
      [PoseLandmarkIndex.RIGHT_SHOULDER, PoseLandmarkIndex.RIGHT_HIP],
      [PoseLandmarkIndex.LEFT_HIP, PoseLandmarkIndex.RIGHT_HIP],
      // Arms
      [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.LEFT_ELBOW],
      [PoseLandmarkIndex.LEFT_ELBOW, PoseLandmarkIndex.LEFT_WRIST],
      [PoseLandmarkIndex.RIGHT_SHOULDER, PoseLandmarkIndex.RIGHT_ELBOW],
      [PoseLandmarkIndex.RIGHT_ELBOW, PoseLandmarkIndex.RIGHT_WRIST],
      // Legs
      [PoseLandmarkIndex.LEFT_HIP, PoseLandmarkIndex.LEFT_KNEE],
      [PoseLandmarkIndex.LEFT_KNEE, PoseLandmarkIndex.LEFT_ANKLE],
      [PoseLandmarkIndex.RIGHT_HIP, PoseLandmarkIndex.RIGHT_KNEE],
      [PoseLandmarkIndex.RIGHT_KNEE, PoseLandmarkIndex.RIGHT_ANKLE],
    ];
    
    // Draw skeleton connections
    ctx.strokeStyle = '#BFA24D'; // Brass Gold from style guide
    ctx.lineWidth = 4;
    
    connections.forEach(([startIdx, endIdx]) => {
      const startLandmark = landmarks[startIdx];
      const endLandmark = landmarks[endIdx];
      
      if (
        startLandmark && 
        endLandmark && 
        (startLandmark.visibility === undefined || startLandmark.visibility > 0.5) && 
        (endLandmark.visibility === undefined || endLandmark.visibility > 0.5)
      ) {
        ctx.beginPath();
        ctx.moveTo(startLandmark.x * canvas.width, startLandmark.y * canvas.height);
        ctx.lineTo(endLandmark.x * canvas.width, endLandmark.y * canvas.height);
        ctx.stroke();
      }
    });
    
    // Draw landmarks as circles
    landmarks.forEach((landmark, index) => {
      if (landmark.visibility === undefined || landmark.visibility > 0.5) {
        // Use different colors for different body parts
        if (index >= PoseLandmarkIndex.LEFT_SHOULDER && index <= PoseLandmarkIndex.RIGHT_WRIST) {
          ctx.fillStyle = '#C9CCA6'; // Olive Mist from style guide - for arms/torso
        } else if (index >= PoseLandmarkIndex.LEFT_HIP && index <= PoseLandmarkIndex.RIGHT_FOOT_INDEX) {
          ctx.fillStyle = '#4E5A48'; // Tactical Gray from style guide - for legs
        } else {
          ctx.fillStyle = '#1E1E1E'; // Command Black from style guide - for face
        }
        
        ctx.beginPath();
        ctx.arc(
          landmark.x * canvas.width, 
          landmark.y * canvas.height, 
          index === PoseLandmarkIndex.NOSE ? 6 : 4, // Larger circle for nose
          0, 
          2 * Math.PI
        );
        ctx.fill();
      }
    });
  };
  
  // Function to start pose detection
  const startDetection = useCallback(() => {
    if (isDetectorReady && !isRunning) {
      setIsRunning(true);
      animationFrameRef.current = requestAnimationFrame(detectFrame);
    }
  }, [isDetectorReady, isRunning, detectFrame]);
  
  // Function to stop pose detection
  const stopDetection = useCallback(() => {
    setIsRunning(false);
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current);
      animationFrameRef.current = null;
    }
  }, []);
  
  // Start/stop detection when the running state changes
  useEffect(() => {
    if (isRunning && isDetectorReady) {
      animationFrameRef.current = requestAnimationFrame(detectFrame);
    }
    
    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
        animationFrameRef.current = null;
      }
    };
  }, [isRunning, isDetectorReady, detectFrame]);
  
  return {
    ...result,
    isDetectorReady,
    isRunning,
    startDetection,
    stopDetection,
  };
} 