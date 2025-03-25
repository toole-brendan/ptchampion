import { useEffect, useRef, useState } from "react";
import { calculatePoseLines, calculateRelativePositions, PushupState, PullupState, SitupState } from "@/lib/tensorflow";
import * as posenet from "@tensorflow-models/posenet";

interface CameraViewProps {
  videoRef: React.RefObject<HTMLVideoElement>;
  exerciseState: PushupState | PullupState | SitupState;
  isStarted: boolean;
}

export default function CameraView({ videoRef, exerciseState, isStarted }: CameraViewProps) {
  const [pose, setPose] = useState<posenet.Pose | null>(null);
  const [viewportDimensions, setViewportDimensions] = useState({ width: 0, height: 0 });
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  // Set up the canvas dimensions to match the video
  useEffect(() => {
    const updateDimensions = () => {
      if (videoRef.current) {
        const { videoWidth, videoHeight } = videoRef.current;
        setViewportDimensions({ width: videoWidth, height: videoHeight });
      }
    };

    const video = videoRef.current;
    
    if (video) {
      video.addEventListener('loadedmetadata', updateDimensions);
      updateDimensions();
    }
    
    return () => {
      if (video) {
        video.removeEventListener('loadedmetadata', updateDimensions);
      }
    };
  }, [videoRef]);
  
  // Update pose state based on the latest detection
  useEffect(() => {
    if (!isStarted) return;
    
    const updatePose = (newPose: posenet.Pose) => {
      setPose(newPose);
    };
    
    // If we have new pose data from the parent component, update it
    return () => {
      // Cleanup
    };
  }, [isStarted]);
  
  // Draw the pose on the canvas
  useEffect(() => {
    if (!canvasRef.current || !pose || !videoRef.current) return;
    
    const ctx = canvasRef.current.getContext('2d');
    if (!ctx) return;
    
    const { width, height } = viewportDimensions;
    
    // Clear the canvas
    ctx.clearRect(0, 0, width, height);
    
    const keypoints = pose.keypoints;
    
    // Get points with relative coordinates
    const relativeKeypoints = calculateRelativePositions(keypoints, width, height);
    
    // Draw points
    relativeKeypoints.forEach(point => {
      if (point.score > 0.3) {
        ctx.beginPath();
        ctx.arc(
          point.position.x * width / 100, 
          point.position.y * height / 100, 
          4, 
          0, 
          2 * Math.PI
        );
        ctx.fillStyle = '#3B82F6';
        ctx.fill();
      }
    });
    
    // Get and draw lines
    const lines = calculatePoseLines(keypoints);
    lines.forEach(line => {
      const fromX = line.from.position.x;
      const fromY = line.from.position.y;
      const toX = line.to.position.x;
      const toY = line.to.position.y;
      
      ctx.beginPath();
      ctx.moveTo(fromX, fromY);
      ctx.lineTo(toX, toY);
      ctx.lineWidth = 2;
      ctx.strokeStyle = '#3B82F6';
      ctx.stroke();
    });
    
  }, [pose, viewportDimensions, videoRef]);

  return (
    <div className="camera-container bg-slate-900 relative">
      <video 
        ref={videoRef}
        autoPlay
        playsInline
        muted
        className="w-full h-full object-cover opacity-90"
      />
      
      <canvas 
        ref={canvasRef}
        width={viewportDimensions.width}
        height={viewportDimensions.height}
        className="absolute top-0 left-0 w-full h-full"
      />
      
      {/* Exercise counting overlay */}
      <div className="absolute top-4 left-4 right-4 flex justify-between items-start">
        <div className="bg-black/70 text-white px-3 py-2 rounded-lg">
          <div className="text-xs text-slate-300">REPS</div>
          <div className="text-2xl font-bold">{exerciseState.count}</div>
        </div>
        <div className="bg-black/70 text-white px-3 py-2 rounded-lg">
          <div className="text-xs text-slate-300">FORM</div>
          <div className="text-2xl font-bold">{exerciseState.formScore}%</div>
        </div>
      </div>
      
      {/* Form feedback */}
      <div className="absolute bottom-4 left-4 right-4">
        <div className="bg-black/70 text-white px-3 py-2 rounded-lg">
          <div className="text-xs text-slate-300">FEEDBACK</div>
          <div className="text-sm">{exerciseState.feedback}</div>
        </div>
      </div>
      
      {/* Camera disabled message - shown when exercise not started */}
      {!isStarted && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/80 text-white">
          <div className="text-center p-6">
            <div className="text-xl font-bold mb-2">Camera Ready</div>
            <p className="text-sm">Press Start to begin exercise tracking</p>
          </div>
        </div>
      )}
    </div>
  );
}
