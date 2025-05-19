import React, { useEffect, useRef } from 'react';
import { NormalizedLandmark } from '../lib/types';
import { PoseLandmarkIndex } from '../grading/SitupAnalyzer';
import { SitupFormAnalysis } from '../grading/SitupAnalyzer';

interface SitupFormVisualizerProps {
  landmarks: NormalizedLandmark[];
  formAnalysis: SitupFormAnalysis;
  width: number;
  height: number;
  showAngles?: boolean;
  showJoints?: boolean;
}

/**
 * Component to visualize sit-up form with joint angles and issues
 */
const SitupFormVisualizer: React.FC<SitupFormVisualizerProps> = ({
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
  analysis: SitupFormAnalysis
) {
  // Define connections for sit-up analysis
  const connections = [
    // Head and neck
    [PoseLandmarkIndex.NOSE, PoseLandmarkIndex.LEFT_EAR],
    [PoseLandmarkIndex.NOSE, PoseLandmarkIndex.RIGHT_EAR],
    // Arms and hands
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

    // Check hand position
    if ((startIdx === PoseLandmarkIndex.LEFT_ELBOW && endIdx === PoseLandmarkIndex.LEFT_WRIST) ||
        (startIdx === PoseLandmarkIndex.RIGHT_ELBOW && endIdx === PoseLandmarkIndex.RIGHT_WRIST)) {
      if (!analysis.isHandPositionCorrect) {
        // Incorrect hand position - red
        strokeColor = '#FF4444';
        lineWidth = 3;
      }
    }

    // Trunk angle - check verticality in up position
    if ((startIdx === PoseLandmarkIndex.LEFT_SHOULDER && endIdx === PoseLandmarkIndex.LEFT_HIP) ||
        (startIdx === PoseLandmarkIndex.RIGHT_SHOULDER && endIdx === PoseLandmarkIndex.RIGHT_HIP)) {
      if (analysis.trunkAngle < 60) {
        // Not vertical enough - orange
        strokeColor = '#FFAA00';
        lineWidth = 3;
      } else if (analysis.trunkAngle > 95) {
        // Too far back - red
        strokeColor = '#FF4444';
        lineWidth = 3;
      } else if (analysis.isUpPosition) {
        // Good up position - strong green
        strokeColor = '#00AA00';
        lineWidth = 3;
      }
    }

    // Knee stability
    if ((startIdx === PoseLandmarkIndex.LEFT_HIP && endIdx === PoseLandmarkIndex.LEFT_KNEE) ||
        (startIdx === PoseLandmarkIndex.RIGHT_HIP && endIdx === PoseLandmarkIndex.RIGHT_KNEE) ||
        (startIdx === PoseLandmarkIndex.LEFT_KNEE && endIdx === PoseLandmarkIndex.LEFT_ANKLE) ||
        (startIdx === PoseLandmarkIndex.RIGHT_KNEE && endIdx === PoseLandmarkIndex.RIGHT_ANKLE)) {
      if (!analysis.isKneeAngleCorrect) {
        // Incorrect knee angle - orange
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

    // Draw joints as circles
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
  analysis: SitupFormAnalysis,
  width: number,
  height: number
) {
  const angles = [
    {
      name: 'Trunk',
      angle: Math.round(analysis.trunkAngle),
      x: (landmarks[PoseLandmarkIndex.LEFT_HIP].x + landmarks[PoseLandmarkIndex.RIGHT_HIP].x) * width / 2,
      y: (landmarks[PoseLandmarkIndex.LEFT_HIP].y + landmarks[PoseLandmarkIndex.RIGHT_HIP].y) * height / 2,
      isGood: analysis.trunkAngle >= 60 && analysis.trunkAngle <= 95
    },
    {
      name: 'L Knee',
      angle: Math.round(analysis.leftKneeAngle),
      x: landmarks[PoseLandmarkIndex.LEFT_KNEE].x * width,
      y: landmarks[PoseLandmarkIndex.LEFT_KNEE].y * height,
      isGood: analysis.leftKneeAngle >= 70 && analysis.leftKneeAngle <= 110 
    },
    {
      name: 'R Knee',
      angle: Math.round(analysis.rightKneeAngle),
      x: landmarks[PoseLandmarkIndex.RIGHT_KNEE].x * width,
      y: landmarks[PoseLandmarkIndex.RIGHT_KNEE].y * height,
      isGood: analysis.rightKneeAngle >= 70 && analysis.rightKneeAngle <= 110
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
  analysis: SitupFormAnalysis,
  width: number,
  height: number
) {
  const indicators = [];

  // Collect active indicators
  if (!analysis.isHandPositionCorrect) {
    indicators.push({ text: 'HANDS NOT BEHIND HEAD', color: '#FF4444' });
  }
  if (!analysis.isKneeAngleCorrect) {
    indicators.push({ text: 'INCORRECT KNEE ANGLE', color: '#FFAA00' });
  }
  if (!analysis.isShoulderBladeGrounded && analysis.isDownPosition) {
    indicators.push({ text: 'SHOULDERS OFF GROUND', color: '#FF4444' });
  }
  if (!analysis.isHipStable) {
    indicators.push({ text: 'HIPS LIFTING', color: '#FF4444' });
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
    const text = analysis.isUpPosition ? 'GOOD SIT-UP!' : 
                 analysis.isDownPosition ? 'READY POSITION' : 'GOOD FORM';
    
    ctx.fillStyle = 'rgba(0, 150, 0, 0.7)';
    ctx.font = 'bold 16px Arial';
    const textWidth = ctx.measureText(text).width;
    ctx.fillRect(
      width / 2 - textWidth / 2 - boxPadding,
      20 - boxHeight / 2,
      textWidth + boxPadding * 2,
      boxHeight
    );
    
    ctx.fillStyle = 'white';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, width / 2, 20);
  }

  // Draw rep progress indicator at bottom
  const progressWidth = width * 0.8;
  const progressHeight = 10;
  const progressX = (width - progressWidth) / 2;
  const progressY = height - 20;
  
  // Background
  ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
  ctx.fillRect(progressX, progressY, progressWidth, progressHeight);
  
  // Progress fill
  ctx.fillStyle = 'rgba(0, 150, 0, 0.7)';
  ctx.fillRect(progressX, progressY, progressWidth * analysis.repProgress, progressHeight);
}

export default SitupFormVisualizer; 