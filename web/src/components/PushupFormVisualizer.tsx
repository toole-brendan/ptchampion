import React, { useEffect, useRef } from 'react';
import { NormalizedLandmark } from '../lib/types';
import { PoseLandmarkIndex } from '../services/PoseLandmarkIndex';
import { PushupFormAnalysis } from '../grading/PushupAnalyzer';

interface PushupFormVisualizerProps {
  landmarks: NormalizedLandmark[];
  formAnalysis: PushupFormAnalysis;
  width: number;
  height: number;
  showAngles?: boolean;
  showJoints?: boolean;
}

/**
 * Component to visualize push-up form with joint angles and issues
 */
const PushupFormVisualizer: React.FC<PushupFormVisualizerProps> = ({
  landmarks,
  formAnalysis,
  width,
  height,
  showAngles = true,
  showJoints = true,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Draw the form visualization when landmarks or analysis update
  useEffect(() => {
    if (!canvasRef.current || !landmarks.length) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw connections between landmarks (skeleton)
    drawSkeleton(ctx, landmarks, width, height, formAnalysis);

    // Draw joint angles if enabled
    if (showAngles) {
      drawJointAngles(ctx, landmarks, formAnalysis, width, height);
    }

    // Draw feedback indicators
    drawFeedbackIndicators(ctx, formAnalysis, width, height);

  }, [landmarks, formAnalysis, width, height, showAngles, showJoints]);

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      className="rounded-lg border border-gray-200 bg-white"
    />
  );
};

/**
 * Draw the skeleton connecting key landmarks
 */
function drawSkeleton(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number,
  analysis: PushupFormAnalysis
) {
  // Define connections for pushup analysis
  const connections = [
    // Arms
    [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.LEFT_ELBOW],
    [PoseLandmarkIndex.LEFT_ELBOW, PoseLandmarkIndex.LEFT_WRIST],
    [PoseLandmarkIndex.RIGHT_SHOULDER, PoseLandmarkIndex.RIGHT_ELBOW],
    [PoseLandmarkIndex.RIGHT_ELBOW, PoseLandmarkIndex.RIGHT_WRIST],
    // Torso
    [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.RIGHT_SHOULDER],
    [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.LEFT_HIP],
    [PoseLandmarkIndex.RIGHT_SHOULDER, PoseLandmarkIndex.RIGHT_HIP],
    [PoseLandmarkIndex.LEFT_HIP, PoseLandmarkIndex.RIGHT_HIP],
    // Legs
    [PoseLandmarkIndex.LEFT_HIP, PoseLandmarkIndex.LEFT_KNEE],
    [PoseLandmarkIndex.LEFT_KNEE, PoseLandmarkIndex.LEFT_ANKLE],
    [PoseLandmarkIndex.RIGHT_HIP, PoseLandmarkIndex.RIGHT_KNEE],
    [PoseLandmarkIndex.RIGHT_KNEE, PoseLandmarkIndex.RIGHT_ANKLE],
  ];

  // Draw connections with color based on form issues
  connections.forEach(([startIdx, endIdx]) => {
    const start = landmarks[startIdx];
    const end = landmarks[endIdx];

    // Skip if either landmark has low visibility
    if ((start.visibility && start.visibility < 0.5) || 
        (end.visibility && end.visibility < 0.5)) {
      return;
    }

    // Check if this connection is part of a form issue
    let strokeColor = '#00CC00'; // Default: good form (green)
    let lineWidth = 2;

    // Arms - check elbow angles
    if ((startIdx === PoseLandmarkIndex.LEFT_SHOULDER && endIdx === PoseLandmarkIndex.LEFT_ELBOW) ||
        (startIdx === PoseLandmarkIndex.LEFT_ELBOW && endIdx === PoseLandmarkIndex.LEFT_WRIST) ||
        (startIdx === PoseLandmarkIndex.RIGHT_SHOULDER && endIdx === PoseLandmarkIndex.RIGHT_ELBOW) ||
        (startIdx === PoseLandmarkIndex.RIGHT_ELBOW && endIdx === PoseLandmarkIndex.RIGHT_WRIST)) {
      if (analysis.leftElbowAngle < 90 || analysis.rightElbowAngle < 90) {
        // Good depth - strong green
        strokeColor = '#00AA00';
        lineWidth = 3;
      } else if (analysis.leftElbowAngle > 160 || analysis.rightElbowAngle > 160) {
        // Extended position - light blue
        strokeColor = '#00AAFF';
        lineWidth = 3;
      }
    }

    // Body alignment - check for sagging or piking
    if ((startIdx === PoseLandmarkIndex.LEFT_SHOULDER && endIdx === PoseLandmarkIndex.LEFT_HIP) ||
        (startIdx === PoseLandmarkIndex.RIGHT_SHOULDER && endIdx === PoseLandmarkIndex.RIGHT_HIP) ||
        (startIdx === PoseLandmarkIndex.LEFT_HIP && endIdx === PoseLandmarkIndex.LEFT_KNEE) ||
        (startIdx === PoseLandmarkIndex.RIGHT_HIP && endIdx === PoseLandmarkIndex.RIGHT_KNEE)) {
      if (analysis.isBodySagging) {
        // Sagging issue - red
        strokeColor = '#FF4444';
        lineWidth = 3;
      } else if (analysis.isBodyPiking) {
        // Piking issue - orange
        strokeColor = '#FFAA00';
        lineWidth = 3;
      }
    }

    // Draw the connection
    ctx.beginPath();
    ctx.moveTo(start.x * width, start.y * height);
    ctx.lineTo(end.x * width, end.y * height);
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = lineWidth;
    ctx.stroke();

    // Draw joints
    if (lineWidth > 2) {
      ctx.beginPath();
      ctx.arc(start.x * width, start.y * height, 5, 0, 2 * Math.PI);
      ctx.fillStyle = strokeColor;
      ctx.fill();

      ctx.beginPath();
      ctx.arc(end.x * width, end.y * height, 5, 0, 2 * Math.PI);
      ctx.fillStyle = strokeColor;
      ctx.fill();
    }
  });
}

/**
 * Draw joint angles on the visualization
 */
function drawJointAngles(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  analysis: PushupFormAnalysis,
  width: number,
  height: number
) {
  const angles = [
    {
      name: 'L Elbow',
      angle: Math.round(analysis.leftElbowAngle),
      x: landmarks[PoseLandmarkIndex.LEFT_ELBOW].x * width,
      y: landmarks[PoseLandmarkIndex.LEFT_ELBOW].y * height,
      isGood: analysis.leftElbowAngle <= 110 // Less than 110° is considered good form
    },
    {
      name: 'R Elbow',
      angle: Math.round(analysis.rightElbowAngle),
      x: landmarks[PoseLandmarkIndex.RIGHT_ELBOW].x * width,
      y: landmarks[PoseLandmarkIndex.RIGHT_ELBOW].y * height,
      isGood: analysis.rightElbowAngle <= 110
    },
    {
      name: 'Body',
      angle: Math.round(analysis.bodyAlignmentAngle),
      x: (landmarks[PoseLandmarkIndex.LEFT_HIP].x + landmarks[PoseLandmarkIndex.RIGHT_HIP].x) * width / 2,
      y: (landmarks[PoseLandmarkIndex.LEFT_HIP].y + landmarks[PoseLandmarkIndex.RIGHT_HIP].y) * height / 2,
      isGood: analysis.bodyAlignmentAngle >= 165 && analysis.bodyAlignmentAngle <= 195
    }
  ];

  angles.forEach(({ name, angle, x, y, isGood }) => {
    // Draw angle text with background
    const text = `${name}: ${angle}°`;
    ctx.font = '14px Arial';
    
    // Background
    ctx.fillStyle = isGood ? 'rgba(0, 128, 0, 0.7)' : 'rgba(255, 0, 0, 0.7)';
    const textWidth = ctx.measureText(text).width;
    const boxPadding = 4;
    ctx.fillRect(
      x - textWidth / 2 - boxPadding,
      y - 10 - boxPadding,
      textWidth + boxPadding * 2,
      20 + boxPadding * 2
    );
    
    // Text
    ctx.fillStyle = 'white';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, x, y);
  });
}

/**
 * Draw feedback indicators for form issues
 */
function drawFeedbackIndicators(
  ctx: CanvasRenderingContext2D,
  analysis: PushupFormAnalysis,
  width: number,
  height: number
) {
  const indicators = [];

  // Collect active indicators
  if (analysis.isBodySagging) {
    indicators.push({ text: 'SAGGING', color: '#FF4444' });
  }
  if (analysis.isBodyPiking) {
    indicators.push({ text: 'PIKING', color: '#FFAA00' });
  }
  if (analysis.isWorming) {
    indicators.push({ text: 'WORMING', color: '#FF44FF' });
  }
  if (analysis.handsLiftedOff) {
    indicators.push({ text: 'HANDS OFF GROUND', color: '#FF0000' });
  }
  if (analysis.feetLiftedOff) {
    indicators.push({ text: 'FEET OFF GROUND', color: '#FF0000' });
  }
  if (analysis.kneesTouchingGround) {
    indicators.push({ text: 'KNEES ON GROUND', color: '#FF0000' });
  }
  if (analysis.bodyTouchingGround) {
    indicators.push({ text: 'BODY ON GROUND', color: '#FF0000' });
  }
  if (analysis.isPaused) {
    indicators.push({ text: 'PAUSED', color: '#FFAA00' });
  }

  // Position indicators at top of canvas
  const boxHeight = 30;
  const boxPadding = 10;
  
  indicators.forEach((indicator, index) => {
    const x = width / 2;
    const y = 20 + (boxHeight + 10) * index;
    
    // Draw background
    ctx.fillStyle = indicator.color;
    const textWidth = ctx.measureText(indicator.text).width;
    ctx.fillRect(
      x - textWidth / 2 - boxPadding,
      y - boxHeight / 2,
      textWidth + boxPadding * 2,
      boxHeight
    );
    
    // Draw text
    ctx.fillStyle = 'white';
    ctx.font = 'bold 16px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(indicator.text, x, y);
  });

  // Draw positive indicator if form is good
  if (indicators.length === 0) {
    const text = analysis.isDownPosition ? 'GOOD DEPTH!' : 
                 analysis.isUpPosition ? 'GOOD EXTENSION!' : 'GOOD FORM';
    
    ctx.fillStyle = 'rgba(0, 150, 0, 0.7)';
    const textWidth = ctx.measureText(text).width;
    ctx.fillRect(
      width / 2 - textWidth / 2 - boxPadding,
      20 - boxHeight / 2,
      textWidth + boxPadding * 2,
      boxHeight
    );
    
    ctx.fillStyle = 'white';
    ctx.font = 'bold 16px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, width / 2, 20);
  }
}

export default PushupFormVisualizer; 