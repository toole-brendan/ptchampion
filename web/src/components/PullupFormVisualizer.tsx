import React, { useEffect, useRef } from 'react';
import { NormalizedLandmark } from '../lib/types';
import { PoseLandmarkIndex } from '../grading/PullupAnalyzer';
import { PullupFormAnalysis } from '../grading/PullupAnalyzer';

interface PullupFormVisualizerProps {
  landmarks: NormalizedLandmark[];
  formAnalysis: PullupFormAnalysis;
  width: number;
  height: number;
  showAngles?: boolean;
  showJoints?: boolean;
  showBar?: boolean;
}

/**
 * Component to visualize pull-up form with joint angles and feedback
 */
const PullupFormVisualizer: React.FC<PullupFormVisualizerProps> = ({
  landmarks,
  formAnalysis,
  width,
  height,
  showAngles = true,
  showJoints = true,
  showBar = true,
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

    // Draw bar reference if enabled
    if (showBar) {
      drawBar(ctx, formAnalysis.barY, width, height);
    }

    // Draw connections between landmarks (skeleton)
    drawSkeleton(ctx, landmarks, width, height, formAnalysis);

    // Draw joint angles if enabled
    if (showAngles) {
      drawJointAngles(ctx, landmarks, formAnalysis, width, height);
    }

    // Draw feedback indicators
    drawFeedbackIndicators(ctx, formAnalysis, width, height);

  }, [landmarks, formAnalysis, width, height, showAngles, showJoints, showBar]);

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
 * Draw the pull-up bar as a reference
 */
function drawBar(
  ctx: CanvasRenderingContext2D,
  barY: number,
  width: number,
  height: number
) {
  // Don't draw if bar Y position is not set
  if (barY === 0) return;

  // Draw horizontal bar
  ctx.beginPath();
  ctx.moveTo(width * 0.1, barY * height);
  ctx.lineTo(width * 0.9, barY * height);
  ctx.strokeStyle = '#333333';
  ctx.lineWidth = 8;
  ctx.stroke();

  // Draw support lines
  ctx.beginPath();
  ctx.moveTo(width * 0.1, 0);
  ctx.lineTo(width * 0.1, barY * height);
  ctx.strokeStyle = '#555555';
  ctx.lineWidth = 4;
  ctx.stroke();

  ctx.beginPath();
  ctx.moveTo(width * 0.9, 0);
  ctx.lineTo(width * 0.9, barY * height);
  ctx.strokeStyle = '#555555';
  ctx.lineWidth = 4;
  ctx.stroke();

  // Draw chin clearance reference line
  ctx.beginPath();
  ctx.moveTo(width * 0.1, (barY - 0.05) * height);
  ctx.lineTo(width * 0.9, (barY - 0.05) * height);
  ctx.strokeStyle = 'rgba(0, 255, 0, 0.4)';
  ctx.lineWidth = 2;
  ctx.setLineDash([5, 5]);
  ctx.stroke();
  ctx.setLineDash([]);
}

/**
 * Draw the skeleton connecting key landmarks
 */
function drawSkeleton(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  width: number,
  height: number,
  analysis: PullupFormAnalysis
) {
  // Define connections for pull-up analysis
  const connections = [
    // Head
    [PoseLandmarkIndex.NOSE, PoseLandmarkIndex.LEFT_EAR],
    [PoseLandmarkIndex.NOSE, PoseLandmarkIndex.RIGHT_EAR],
    // Arms
    [PoseLandmarkIndex.LEFT_SHOULDER, PoseLandmarkIndex.LEFT_ELBOW],
    [PoseLandmarkIndex.LEFT_ELBOW, PoseLandmarkIndex.LEFT_WRIST],
    [PoseLandmarkIndex.RIGHT_SHOULDER, PoseLandmarkIndex.RIGHT_ELBOW],
    [PoseLandmarkIndex.RIGHT_ELBOW, PoseLandmarkIndex.RIGHT_WRIST],
    // Hands
    [PoseLandmarkIndex.LEFT_WRIST, PoseLandmarkIndex.LEFT_PINKY],
    [PoseLandmarkIndex.LEFT_WRIST, PoseLandmarkIndex.LEFT_INDEX],
    [PoseLandmarkIndex.RIGHT_WRIST, PoseLandmarkIndex.RIGHT_PINKY],
    [PoseLandmarkIndex.RIGHT_WRIST, PoseLandmarkIndex.RIGHT_INDEX],
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

    // Elbow lockout check
    if ((startIdx === PoseLandmarkIndex.LEFT_SHOULDER && endIdx === PoseLandmarkIndex.LEFT_ELBOW) ||
        (startIdx === PoseLandmarkIndex.LEFT_ELBOW && endIdx === PoseLandmarkIndex.LEFT_WRIST) ||
        (startIdx === PoseLandmarkIndex.RIGHT_SHOULDER && endIdx === PoseLandmarkIndex.RIGHT_ELBOW) ||
        (startIdx === PoseLandmarkIndex.RIGHT_ELBOW && endIdx === PoseLandmarkIndex.RIGHT_WRIST)) {
      
      if (!analysis.isElbowLocked && analysis.isDownPosition) {
        // Incomplete elbow extension in down position - red
        strokeColor = '#FF4444';
        lineWidth = 3;
      } else if (analysis.isUpPosition) {
        // Good top position - blue
        strokeColor = '#4477FF';
        lineWidth = 3;
      }
    }

    // Swinging/kipping detection - check hip and leg connections
    if ((startIdx === PoseLandmarkIndex.LEFT_SHOULDER && endIdx === PoseLandmarkIndex.LEFT_HIP) ||
        (startIdx === PoseLandmarkIndex.RIGHT_SHOULDER && endIdx === PoseLandmarkIndex.RIGHT_HIP) ||
        (startIdx === PoseLandmarkIndex.LEFT_HIP && endIdx === PoseLandmarkIndex.RIGHT_HIP)) {
      
      if (analysis.isSwinging) {
        // Swinging detected - orange
        strokeColor = '#FFAA00';
        lineWidth = 3;
      }
    }

    // Kicking/kipping detection - check knee connections
    if ((startIdx === PoseLandmarkIndex.LEFT_HIP && endIdx === PoseLandmarkIndex.LEFT_KNEE) ||
        (startIdx === PoseLandmarkIndex.RIGHT_HIP && endIdx === PoseLandmarkIndex.RIGHT_KNEE) ||
        (startIdx === PoseLandmarkIndex.LEFT_KNEE && endIdx === PoseLandmarkIndex.LEFT_ANKLE) ||
        (startIdx === PoseLandmarkIndex.RIGHT_KNEE && endIdx === PoseLandmarkIndex.RIGHT_ANKLE)) {
      
      if (analysis.isKipping) {
        // Kipping detected - orange
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

    // Draw key joints as circles
    if (lineWidth > 2 || 
        startIdx === PoseLandmarkIndex.NOSE || 
        startIdx === PoseLandmarkIndex.LEFT_SHOULDER || 
        startIdx === PoseLandmarkIndex.RIGHT_SHOULDER ||
        startIdx === PoseLandmarkIndex.LEFT_ELBOW ||
        startIdx === PoseLandmarkIndex.RIGHT_ELBOW ||
        startIdx === PoseLandmarkIndex.LEFT_WRIST ||
        startIdx === PoseLandmarkIndex.RIGHT_WRIST) {
      
      const jointSize = lineWidth > 2 ? 5 : 3;
      
      ctx.beginPath();
      ctx.arc(start.x * width, start.y * height, jointSize, 0, 2 * Math.PI);
      ctx.fillStyle = strokeColor;
      ctx.fill();

      if (endIdx === PoseLandmarkIndex.LEFT_ELBOW || 
          endIdx === PoseLandmarkIndex.RIGHT_ELBOW ||
          endIdx === PoseLandmarkIndex.LEFT_WRIST ||
          endIdx === PoseLandmarkIndex.RIGHT_WRIST) {
        ctx.beginPath();
        ctx.arc(end.x * width, end.y * height, jointSize, 0, 2 * Math.PI);
        ctx.fillStyle = strokeColor;
        ctx.fill();
      }
    }
  });

  // Highlight nose position relative to bar
  const nose = landmarks[PoseLandmarkIndex.NOSE];
  if (nose.visibility && nose.visibility > 0.5) {
    const noseSize = analysis.chinClearsBar ? 8 : 5;
    const noseColor = analysis.chinClearsBar ? '#00CC00' : '#FFAA00';
    
    ctx.beginPath();
    ctx.arc(nose.x * width, nose.y * height, noseSize, 0, 2 * Math.PI);
    ctx.fillStyle = noseColor;
    ctx.fill();
  }
}

/**
 * Draw joint angles on the visualization
 */
function drawJointAngles(
  ctx: CanvasRenderingContext2D,
  landmarks: NormalizedLandmark[],
  analysis: PullupFormAnalysis,
  width: number,
  height: number
) {
  const angles = [
    {
      name: 'L Elbow',
      angle: Math.round(analysis.leftElbowAngle),
      x: landmarks[PoseLandmarkIndex.LEFT_ELBOW].x * width,
      y: landmarks[PoseLandmarkIndex.LEFT_ELBOW].y * height,
      isGood: analysis.isDownPosition ? analysis.leftElbowAngle >= 160 : true
    },
    {
      name: 'R Elbow',
      angle: Math.round(analysis.rightElbowAngle),
      x: landmarks[PoseLandmarkIndex.RIGHT_ELBOW].x * width,
      y: landmarks[PoseLandmarkIndex.RIGHT_ELBOW].y * height,
      isGood: analysis.isDownPosition ? analysis.rightElbowAngle >= 160 : true
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

  // Show displacement for swing detection
  if (analysis.maxHorizontalDisplacement > 0.01) {
    const text = `Swing: ${Math.round(analysis.maxHorizontalDisplacement * 100)}%`;
    const x = width * 0.85;
    const y = height * 0.1;
    const isGood = !analysis.isSwinging;
    
    ctx.font = '14px Arial';
    ctx.fillStyle = isGood ? 'rgba(0, 128, 0, 0.7)' : 'rgba(255, 128, 0, 0.7)';
    
    const textWidth = ctx.measureText(text).width;
    const boxPadding = 4;
    ctx.fillRect(
      x - textWidth / 2 - boxPadding,
      y - 10 - boxPadding,
      textWidth + boxPadding * 2,
      20 + boxPadding * 2
    );
    
    ctx.fillStyle = 'white';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(text, x, y);
  }
}

/**
 * Draw feedback indicators for form issues
 */
function drawFeedbackIndicators(
  ctx: CanvasRenderingContext2D,
  analysis: PullupFormAnalysis,
  width: number,
  height: number
) {
  const indicators = [];

  // Collect active indicators
  if (!analysis.isElbowLocked && analysis.isDownPosition) {
    indicators.push({ text: 'ELBOWS NOT LOCKED OUT', color: '#FF4444' });
  }
  if (analysis.isSwinging) {
    indicators.push({ text: 'EXCESSIVE SWINGING', color: '#FFAA00' });
  }
  if (analysis.isKipping) {
    indicators.push({ text: 'KIPPING DETECTED', color: '#FFAA00' });
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
    let text = 'GOOD FORM';
    
    if (analysis.isDownPosition) {
      text = 'GOOD DEAD HANG';
    } else if (analysis.isUpPosition) {
      text = 'CHIN ABOVE BAR - GOOD!';
    }
    
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

export default PullupFormVisualizer; 