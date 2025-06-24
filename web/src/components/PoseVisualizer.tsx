import React, { useEffect, useRef } from 'react';
import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { POSE_LANDMARKS } from '@/grading/graders/BaseGrader';
import { PoseLandmarker } from '@mediapipe/tasks-vision';

interface PoseVisualizerProps {
  landmarks: NormalizedLandmark[];
  problemJoints?: number[];
  width: number;
  height: number;
  showConnections?: boolean;
  showJoints?: boolean;
  jointRadius?: number;
  exerciseType?: string;
}

/**
 * Component to visualize pose landmarks with problem joint highlighting
 */
const PoseVisualizer: React.FC<PoseVisualizerProps> = ({
  landmarks,
  problemJoints = [],
  width,
  height,
  showConnections = true,
  showJoints = true,
  jointRadius = 6,
  exerciseType = ''
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!canvasRef.current || !landmarks.length) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw connections first (so joints appear on top)
    if (showConnections) {
      drawConnections(ctx, landmarks, width, height, problemJoints);
    }

    // Draw joints
    if (showJoints) {
      drawJoints(ctx, landmarks, width, height, problemJoints, jointRadius);
    }

    // Draw exercise-specific overlays
    drawExerciseOverlays(ctx, landmarks, width, height, exerciseType);

  }, [landmarks, problemJoints, width, height, showConnections, showJoints, jointRadius, exerciseType]);

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      className="absolute inset-0 pointer-events-none"
    />
  );
};

/**
 * Draw connections between pose landmarks
 */
function drawConnections(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number,
  problemJoints: number[]
) {
  // Use MediaPipe's pose connections
  const connections = PoseLandmarker.POSE_CONNECTIONS;

  connections.forEach(({ start, end }) => {
    const startLandmark = landmarks[start];
    const endLandmark = landmarks[end];

    // Skip if either landmark has low visibility
    if (!startLandmark || !endLandmark ||
        (startLandmark.visibility && startLandmark.visibility < 0.5) ||
        (endLandmark.visibility && endLandmark.visibility < 0.5)) {
      return;
    }

    const startX = startLandmark.x * width;
    const startY = startLandmark.y * height;
    const endX = endLandmark.x * width;
    const endY = endLandmark.y * height;

    // Determine connection color based on problem joints
    let strokeColor = 'rgba(0, 255, 0, 0.6)'; // Default green
    let lineWidth = 2;

    // If either joint is a problem joint, highlight the connection
    if (problemJoints.includes(start) || problemJoints.includes(end)) {
      strokeColor = 'rgba(255, 100, 100, 0.8)'; // Red for problems
      lineWidth = 3;
    }

    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = lineWidth;
    ctx.stroke();
  });
}

/**
 * Draw individual joints/landmarks
 */
function drawJoints(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number,
  problemJoints: number[],
  radius: number
) {
  landmarks.forEach((landmark, index) => {
    // Skip landmarks with low visibility
    if (!landmark || (landmark.visibility && landmark.visibility < 0.5)) {
      return;
    }

    const x = landmark.x * width;
    const y = landmark.y * height;

    // Determine joint color and size
    let fillColor = 'rgba(0, 255, 0, 0.8)'; // Default green
    let jointRadius = radius;

    if (problemJoints.includes(index)) {
      fillColor = 'rgba(255, 50, 50, 1)'; // Bright red for problem joints
      jointRadius = radius * 1.5; // Make problem joints larger
      
      // Add pulsing effect for problem joints
      const pulse = Math.sin(Date.now() / 200) * 0.2 + 1;
      jointRadius *= pulse;
    }

    // Draw joint circle
    ctx.beginPath();
    ctx.arc(x, y, jointRadius, 0, 2 * Math.PI);
    ctx.fillStyle = fillColor;
    ctx.fill();

    // Add border for better visibility
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.8)';
    ctx.lineWidth = 1;
    ctx.stroke();
  });
}

/**
 * Draw exercise-specific overlays
 */
function drawExerciseOverlays(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number,
  exerciseType: string
) {
  const exercise = exerciseType.toLowerCase();

  if (exercise.includes('pushup')) {
    drawPushupOverlay(ctx, landmarks, width, height);
  } else if (exercise.includes('pullup')) {
    drawPullupOverlay(ctx, landmarks, width, height);
  } else if (exercise.includes('situp')) {
    drawSitupOverlay(ctx, landmarks, width, height);
  }
}

/**
 * Draw pushup-specific overlay (body alignment line)
 */
function drawPushupOverlay(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number
) {
  const leftShoulder = landmarks[POSE_LANDMARKS.LEFT_SHOULDER];
  const rightShoulder = landmarks[POSE_LANDMARKS.RIGHT_SHOULDER];
  const leftHip = landmarks[POSE_LANDMARKS.LEFT_HIP];
  const rightHip = landmarks[POSE_LANDMARKS.RIGHT_HIP];
  const leftAnkle = landmarks[POSE_LANDMARKS.LEFT_ANKLE];
  const rightAnkle = landmarks[POSE_LANDMARKS.RIGHT_ANKLE];

  if (!leftShoulder || !rightShoulder || !leftHip || !rightHip || !leftAnkle || !rightAnkle) {
    return;
  }

  // Calculate midpoints
  const midShoulderX = (leftShoulder.x + rightShoulder.x) / 2 * width;
  const midShoulderY = (leftShoulder.y + rightShoulder.y) / 2 * height;
  const midHipX = (leftHip.x + rightHip.x) / 2 * width;
  const midHipY = (leftHip.y + rightHip.y) / 2 * height;
  const midAnkleX = (leftAnkle.x + rightAnkle.x) / 2 * width;
  const midAnkleY = (leftAnkle.y + rightAnkle.y) / 2 * height;

  // Draw body alignment line
  ctx.beginPath();
  ctx.moveTo(midShoulderX, midShoulderY);
  ctx.lineTo(midHipX, midHipY);
  ctx.lineTo(midAnkleX, midAnkleY);
  ctx.strokeStyle = 'rgba(100, 100, 255, 0.5)';
  ctx.lineWidth = 2;
  ctx.setLineDash([5, 5]);
  ctx.stroke();
  ctx.setLineDash([]);
}

/**
 * Draw pullup-specific overlay (bar reference)
 */
function drawPullupOverlay(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number
) {
  const leftWrist = landmarks[POSE_LANDMARKS.LEFT_WRIST];
  const rightWrist = landmarks[POSE_LANDMARKS.RIGHT_WRIST];

  if (!leftWrist || !rightWrist) {
    return;
  }

  // Draw bar line at wrist level
  const barY = (leftWrist.y + rightWrist.y) / 2 * height;
  
  ctx.beginPath();
  ctx.moveTo(width * 0.1, barY);
  ctx.lineTo(width * 0.9, barY);
  ctx.strokeStyle = 'rgba(150, 150, 150, 0.7)';
  ctx.lineWidth = 6;
  ctx.stroke();
}

/**
 * Draw situp-specific overlay (knee angle indicator)
 */
function drawSitupOverlay(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number
) {
  const leftHip = landmarks[POSE_LANDMARKS.LEFT_HIP];
  const leftKnee = landmarks[POSE_LANDMARKS.LEFT_KNEE];
  const leftAnkle = landmarks[POSE_LANDMARKS.LEFT_ANKLE];

  if (!leftHip || !leftKnee || !leftAnkle) {
    return;
  }

  // Draw knee angle arc
  const kneeX = leftKnee.x * width;
  const kneeY = leftKnee.y * height;
  
  ctx.beginPath();
  ctx.arc(kneeX, kneeY, 30, 0, Math.PI / 2);
  ctx.strokeStyle = 'rgba(100, 200, 255, 0.5)';
  ctx.lineWidth = 3;
  ctx.stroke();
}

export default PoseVisualizer;