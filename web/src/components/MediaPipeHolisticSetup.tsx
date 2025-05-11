import React, { useEffect, useRef, useState } from 'react';
import { Holistic } from '@mediapipe/holistic';
import { Camera } from '@mediapipe/camera_utils';
import { drawConnectors, drawLandmarks } from '@mediapipe/drawing_utils';
import { POSE_CONNECTIONS, HAND_CONNECTIONS, FACEMESH_TESSELATION } from '@mediapipe/holistic';

interface MediaPipeHolisticSetupProps {
  onResults?: (results: any) => void;
  onCalibrationComplete?: (calibrationData: any) => void;
}

const MediaPipeHolisticSetup: React.FC<MediaPipeHolisticSetupProps> = ({
  onResults,
  onCalibrationComplete
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const holisticRef = useRef<Holistic | null>(null);
  const cameraRef = useRef<Camera | null>(null);
  
  const [isCalibrating, setIsCalibrating] = useState(false);
  const [calibrationData, setCalibrationData] = useState<any>(null);
  const [isCameraReady, setIsCameraReady] = useState(false);
  const [isModelLoading, setIsModelLoading] = useState(true);

  // Initialize MediaPipe Holistic
  useEffect(() => {
    if (!videoRef.current) return;

    // Create holistic instance
    // Try to use local models first, fallback to CDN
    setIsModelLoading(true);
    
    const holistic = new Holistic({
      locateFile: (file: string) => {
        // Try to use local models first, fallback to CDN
        // Note: In a real implementation, you'd need to download the model files
        // and place them in the public/models/holistic directory
        const localModelPath = `/models/holistic/${file}`;
        const cdnModelPath = `https://cdn.jsdelivr.net/npm/@mediapipe/holistic@0.5/${file}`;
        
        // Check if local model exists
        return new Promise<string>((resolve) => {
          fetch(localModelPath, { method: 'HEAD' })
            .then(response => {
              if (response.ok) {
                // Use local model
                console.log(`Using local model: ${localModelPath}`);
                resolve(localModelPath);
              } else {
                // Fallback to CDN
                console.log(`Local model not found, using CDN: ${cdnModelPath}`);
                resolve(cdnModelPath);
              }
            })
            .catch(() => {
              // Network error or other issue, use CDN
              console.log(`Error checking local model, using CDN: ${cdnModelPath}`);
              resolve(cdnModelPath);
            });
        });
      }
    });

    holistic.setOptions({
      modelComplexity: 1, // 0, 1, or 2, with 2 being the most complex/accurate
      smoothLandmarks: true, // Filter jitter in landmark positions
      enableSegmentation: false, // No need for segmentation for exercise tracking
      smoothSegmentation: false,
      refineFaceLandmarks: false, // Face details not needed for exercise grading
      minDetectionConfidence: 0.5,
      minTrackingConfidence: 0.5
    });

    holistic.onResults(handleResults);
    
    // Wait for model to initialize
    holistic.initialize()
      .then(() => {
        console.log('Holistic model initialized successfully');
        setIsModelLoading(false);
        holisticRef.current = holistic;
        
        // Initialize camera after model is loaded
        if (videoRef.current) {
          const camera = new Camera(videoRef.current, {
            onFrame: async () => {
              if (videoRef.current && holisticRef.current) {
                await holisticRef.current.send({ image: videoRef.current });
              }
            },
            width: 1280,
            height: 720
          });
          
          camera.start()
            .then(() => {
              console.log('Camera started successfully');
              setIsCameraReady(true);
            })
            .catch((error: Error) => {
              console.error('Error starting camera:', error);
            });
            
          cameraRef.current = camera;
        }
      })
      .catch((error: Error) => {
        console.error('Error initializing Holistic model:', error);
        setIsModelLoading(false);
      });

    return () => {
      if (cameraRef.current) {
        cameraRef.current.stop();
      }
      if (holisticRef.current) {
        holisticRef.current.close();
      }
    };
  }, []);

  // Handle results from MediaPipe Holistic
  const handleResults = (results: any) => {
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

    // Optional: Draw video frame on canvas (comment this out if you have the video visible behind the canvas)
    // canvasCtx.drawImage(videoRef.current, 0, 0, canvasElement.width, canvasElement.height);

    // Draw the pose landmarks
    if (results.poseLandmarks) {
      drawConnectors(canvasCtx, results.poseLandmarks, POSE_CONNECTIONS, { color: '#00FF00', lineWidth: 4 });
      drawLandmarks(canvasCtx, results.poseLandmarks, { color: '#FF0000', lineWidth: 2 });
    }

    // Draw hands if needed for exercises like pull-ups
    if (results.leftHandLandmarks) {
      drawConnectors(canvasCtx, results.leftHandLandmarks, HAND_CONNECTIONS, { color: '#CC0000', lineWidth: 5 });
      drawLandmarks(canvasCtx, results.leftHandLandmarks, { color: '#00FF00', lineWidth: 2 });
    }
    if (results.rightHandLandmarks) {
      drawConnectors(canvasCtx, results.rightHandLandmarks, HAND_CONNECTIONS, { color: '#00CC00', lineWidth: 5 });
      drawLandmarks(canvasCtx, results.rightHandLandmarks, { color: '#FF0000', lineWidth: 2 });
    }

    // Optional: Draw face mesh if needed (uncomment if needed for specific exercise grading)
    // if (results.faceLandmarks) {
    //   drawConnectors(canvasCtx, results.faceLandmarks, FACEMESH_TESSELATION, { color: '#C0C0C070', lineWidth: 1 });
    // }

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

  // Start calibration process for initial exercise position
  const startCalibration = () => {
    setIsCalibrating(true);
  };

  return (
    <div className="relative">
      {/* Hidden video element to capture camera feed */}
      <video
        ref={videoRef}
        className="absolute w-full h-full object-cover opacity-0"
        playsInline
      />
      
      {/* Canvas for drawing landmarks and visual feedback */}
      <canvas
        ref={canvasRef}
        className="absolute w-full h-full object-cover"
      />
      
      {/* Overlay UI */}
      <div className="absolute inset-0 flex flex-col items-center justify-between p-4">
        <div className="bg-black/50 text-white p-2 rounded">
          {isModelLoading ? (
            <p>Loading MediaPipe Holistic model...</p>
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
            className="bg-blue-600 text-white px-4 py-2 rounded mb-4"
          >
            Calibrate Starting Position
          </button>
        )}
      </div>
    </div>
  );
};

export default MediaPipeHolisticSetup; 