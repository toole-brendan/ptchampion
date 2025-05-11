import React, { useEffect, useRef, useState } from 'react';
import {
  PoseLandmarker,
  PoseLandmarkerResult,
  FaceLandmarker,
  FaceLandmarkerResult,
  HandLandmarker,
  HandLandmarkerResult,
  DrawingUtils,
  FilesetResolver
} from '@mediapipe/tasks-vision';

interface MediaPipeHolisticSetupProps {
  onResults?: (results: HolisticResults) => void;
  onCalibrationComplete?: (calibrationData: HolisticResults) => void;
}

// Create a combined results interface to simulate the Holistic results
interface HolisticResults {
  poseLandmarks?: unknown[];
  faceLandmarks?: unknown[];
  leftHandLandmarks?: unknown[];
  rightHandLandmarks?: unknown[];
  image?: HTMLVideoElement;
}

const MediaPipeHolisticSetup: React.FC<MediaPipeHolisticSetupProps> = ({
  onResults,
  onCalibrationComplete
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const poseLandmarkerRef = useRef<PoseLandmarker | null>(null);
  const faceLandmarkerRef = useRef<FaceLandmarker | null>(null);
  const handLandmarkerRef = useRef<HandLandmarker | null>(null);
  
  const [isCalibrating, setIsCalibrating] = useState(false);
  const [calibrationData, setCalibrationData] = useState<HolisticResults | null>(null);
  const [isCameraReady, setIsCameraReady] = useState(false);
  const [isModelLoading, setIsModelLoading] = useState(true);
  const requestRef = useRef<number>();
  const lastVideoTimeRef = useRef<number>(-1);
  const streamRef = useRef<MediaStream | null>(null);

  // Initialize Camera
  useEffect(() => {
    let currentStream: MediaStream | null = null;

    const getCameraStream = async () => {
      try {
        const constraints: MediaStreamConstraints = {
          video: {
            facingMode: 'user',
            width: { ideal: 1280 },
            height: { ideal: 720 }
          },
          audio: false
        };
        currentStream = await navigator.mediaDevices.getUserMedia(constraints);
        streamRef.current = currentStream;
        
        if (videoRef.current) {
          videoRef.current.srcObject = currentStream;
          videoRef.current.onloadedmetadata = () => {
            setIsCameraReady(true);
          };
        }
      } catch (err) {
        console.error("Error accessing camera:", err);
      }
    };

    getCameraStream();

    return () => {
      if (currentStream) {
        currentStream.getTracks().forEach(track => track.stop());
      }
      if (requestRef.current) {
        cancelAnimationFrame(requestRef.current);
      }
    };
  }, []);

  // Initialize MediaPipe models
  useEffect(() => {
    // Create a local handle results function inside this effect to avoid dependency issues
    const handleResults = (results: HolisticResults) => {
      if (!canvasRef.current || !videoRef.current) return;

      const canvasElement = canvasRef.current;
      const canvasCtx = canvasElement.getContext('2d');
      
      if (!canvasCtx) return;

      // Update canvas dimensions to match video
      canvasElement.width = videoRef.current.videoWidth;
      canvasElement.height = videoRef.current.videoHeight;

      // Clear canvas
      canvasCtx.save();
      canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);

      // Create drawing utils
      const drawingUtils = new DrawingUtils(canvasCtx);

      // Draw the pose landmarks
      if (results.poseLandmarks) {
        drawingUtils.drawLandmarks(results.poseLandmarks, {
          radius: landmarks => DrawingUtils.lerp(landmarks.z, -0.15, 0.1, 5, 1),
          color: '#FF0000'
        });
        drawingUtils.drawConnectors(results.poseLandmarks, PoseLandmarker.POSE_CONNECTIONS, {
          color: '#00FF00',
          lineWidth: 4
        });
      }

      // Draw hands if needed for exercises like pull-ups
      if (results.leftHandLandmarks) {
        drawingUtils.drawLandmarks(results.leftHandLandmarks, {
          color: '#00FF00',
          radius: 2
        });
        drawingUtils.drawConnectors(results.leftHandLandmarks, HandLandmarker.HAND_CONNECTIONS, {
          color: '#CC0000',
          lineWidth: 5
        });
      }
      if (results.rightHandLandmarks) {
        drawingUtils.drawLandmarks(results.rightHandLandmarks, {
          color: '#FF0000',
          radius: 2
        });
        drawingUtils.drawConnectors(results.rightHandLandmarks, HandLandmarker.HAND_CONNECTIONS, {
          color: '#00CC00',
          lineWidth: 5
        });
      }

      // Draw face mesh if needed
      if (results.faceLandmarks) {
        drawingUtils.drawLandmarks(results.faceLandmarks, {
          color: '#C0C0C0',
          radius: 1
        });
        // Face connections not used for exercise tracking
      }

      canvasCtx.restore();

      // If in calibration mode, capture the calibration data
      if (isCalibrating && results.poseLandmarks) {
        setCalibrationData(results);
        setIsCalibrating(false);
        
        if (onCalibrationComplete) {
          onCalibrationComplete(results);
        }
      }

      // Call the results callback if provided
      if (onResults) {
        onResults(results);
      }
    };

    const initializeModels = async () => {
      try {
        setIsModelLoading(true);
        
        // Load vision wasm files
        const vision = await FilesetResolver.forVisionTasks(
          "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
        );
        
        // Helper function to check if model file exists
        const checkModelFile = async (path: string): Promise<boolean> => {
          try {
            const response = await fetch(path, { method: 'HEAD' });
            return response.ok;
          } catch (e) {
            console.error(`Failed to check if model exists at ${path}:`, e);
            return false;
          }
        };
        
        // Check if model files exist before attempting to load them
        const poseModelPath = `/models/pose_landmarker_lite.task`;
        const faceModelPath = `/models/face_landmarker.task`;
        const handModelPath = `/models/hand_landmarker.task`;
        
        const [poseExists, faceExists, handExists] = await Promise.all([
          checkModelFile(poseModelPath),
          checkModelFile(faceModelPath),
          checkModelFile(handModelPath)
        ]);
        
        if (!poseExists || !faceExists || !handExists) {
          throw new Error(
            `Missing model files: ${!poseExists ? 'pose_landmarker_lite.task ' : ''}` +
            `${!faceExists ? 'face_landmarker.task ' : ''}` +
            `${!handExists ? 'hand_landmarker.task' : ''}`
          );
        }
        
        // Initialize Pose Landmarker
        const poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: poseModelPath,
            delegate: "GPU" 
          },
          runningMode: "VIDEO",
          numPoses: 1
        });
        poseLandmarkerRef.current = poseLandmarker;
        
        // Initialize Face Landmarker
        const faceLandmarker = await FaceLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: faceModelPath,
            delegate: "GPU"
          },
          runningMode: "VIDEO",
          numFaces: 1
        });
        faceLandmarkerRef.current = faceLandmarker;
        
        // Initialize Hand Landmarker
        const handLandmarker = await HandLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: handModelPath,
            delegate: "GPU"
          },
          runningMode: "VIDEO",
          numHands: 2
        });
        handLandmarkerRef.current = handLandmarker;
        
        setIsModelLoading(false);
        
        // Define startLandmarkDetection inside the useEffect to avoid dependency issues
        const startDetection = () => {
          if (!videoRef.current || !canvasRef.current) return;
          
          const video = videoRef.current;
          
          const detectFrame = () => {
            if (!video || !poseLandmarkerRef.current || !faceLandmarkerRef.current || !handLandmarkerRef.current) {
              requestRef.current = requestAnimationFrame(detectFrame);
              return;
            }
            
            if (video.currentTime !== lastVideoTimeRef.current) {
              lastVideoTimeRef.current = video.currentTime;
              const startTimeMs = performance.now();
              
              // Combined results to match the Holistic API structure
              const holisticResults: HolisticResults = {
                image: video
              };
              
              // Detect pose landmarks
              const poseResults = poseLandmarkerRef.current.detectForVideo(video, startTimeMs) as PoseLandmarkerResult;
              if (poseResults.landmarks && poseResults.landmarks.length > 0) {
                holisticResults.poseLandmarks = poseResults.landmarks[0];
              }
              
              // Detect face landmarks
              const faceResults = faceLandmarkerRef.current.detectForVideo(video, startTimeMs) as FaceLandmarkerResult;
              if (faceResults.faceLandmarks && faceResults.faceLandmarks.length > 0) {
                holisticResults.faceLandmarks = faceResults.faceLandmarks[0];
              }
              
              // Detect hand landmarks
              const handResults = handLandmarkerRef.current.detectForVideo(video, startTimeMs) as HandLandmarkerResult;
              if (handResults.landmarks && handResults.landmarks.length > 0) {
                // Determine left and right hand based on position
                if (handResults.handedness && handResults.landmarks.length >= 2) {
                  const leftHandIndex = handResults.handedness.findIndex(hand => hand[0].categoryName === 'Left');
                  const rightHandIndex = handResults.handedness.findIndex(hand => hand[0].categoryName === 'Right');
                  
                  if (leftHandIndex !== -1) {
                    holisticResults.leftHandLandmarks = handResults.landmarks[leftHandIndex];
                  }
                  
                  if (rightHandIndex !== -1) {
                    holisticResults.rightHandLandmarks = handResults.landmarks[rightHandIndex];
                  }
                } else if (handResults.landmarks.length === 1 && handResults.handedness) {
                  // Only one hand detected
                  if (handResults.handedness[0][0].categoryName === 'Left') {
                    holisticResults.leftHandLandmarks = handResults.landmarks[0];
                  } else {
                    holisticResults.rightHandLandmarks = handResults.landmarks[0];
                  }
                }
              }
              
              // Process the combined results
              handleResults(holisticResults);
            }
            
            requestRef.current = requestAnimationFrame(detectFrame);
          };
          
          detectFrame();
        };

        startDetection();
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error("Error initializing MediaPipe models:", errorMessage);
        setIsModelLoading(false);
        
        // Show a specific error message in the UI
        const errorDiv = document.createElement('div');
        errorDiv.className = 'bg-red-500 text-white p-4 fixed top-0 left-0 right-0 z-50';
        errorDiv.textContent = `MediaPipe initialization error: ${errorMessage}. Make sure all model files are in the public/models directory.`;
        document.body.appendChild(errorDiv);
        
        // Suggest running the download script
        console.info("Try running the download-models.sh script to download the required model files.");
      }
    };
    
    if (isCameraReady) {
      initializeModels();
    }
    
    return () => {
      if (requestRef.current) {
        cancelAnimationFrame(requestRef.current);
      }
    };
  }, [isCameraReady, isCalibrating, onCalibrationComplete, onResults]);

  // Start calibration process for initial exercise position
  const startCalibration = () => {
    setIsCalibrating(true);
  };

  return (
    <div className="relative">
      {/* Video element to capture camera feed */}
      <video
        ref={videoRef}
        className="absolute size-full object-cover opacity-0"
        playsInline
        autoPlay
      />
      
      {/* Canvas for drawing landmarks and visual feedback */}
      <canvas
        ref={canvasRef}
        className="absolute size-full object-cover"
      />
      
      {/* Overlay UI */}
      <div className="absolute inset-0 flex flex-col items-center justify-between p-4">
        <div className="rounded bg-black/50 p-2 text-white">
          {isModelLoading ? (
            <p>Loading MediaPipe models...</p>
          ) : !isCameraReady ? (
            <p>Initializing camera...</p>
          ) : isCalibrating ? (
            <p>Calibrating... Please hold the starting position</p>
          ) : (
            <p>Camera ready</p>
          )}
        </div>
        
        {isCameraReady && !isCalibrating && !calibrationData && !isModelLoading && (
          <button
            onClick={startCalibration}
            className="mb-4 rounded bg-blue-600 px-4 py-2 text-white"
          >
            Calibrate Starting Position
          </button>
        )}
      </div>
    </div>
  );
};

export default MediaPipeHolisticSetup; 