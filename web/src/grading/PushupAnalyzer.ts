import { NormalizedLandmark } from '../lib/types';
import { PoseLandmarkIndex } from '../services/PoseLandmarkIndex';

/**
 * Interface for storing pushup form analysis results
 */
export interface PushupFormAnalysis {
  // Rep counting
  isDownPosition: boolean;
  isUpPosition: boolean;
  isValidRep: boolean;
  
  // Angle measurements
  leftElbowAngle: number;
  rightElbowAngle: number;
  bodyAlignmentAngle: number;
  
  // Form issues
  isBodySagging: boolean;
  isBodyPiking: boolean;
  isWorming: boolean;
  
  // Disqualifying breaks
  handsLiftedOff: boolean;
  feetLiftedOff: boolean;
  kneesTouchingGround: boolean;
  bodyTouchingGround: boolean;
  isPaused: boolean;
  
  // Debug info
  minElbowAngleDuringRep: number;
}

/**
 * Configuration options for push-up form analysis
 */
export interface PushupAnalyzerConfig {
  // Angle thresholds
  minElbowExtensionAngle: number; // Minimum angle considered "up" position (e.g., 160°)
  maxElbowFlexionAngle: number;   // Maximum angle considered "down" position (e.g., 90°)
  
  // Body alignment thresholds
  maxPikingAngle: number;         // Maximum angle before considered "piking" (e.g., 165°)
  minSaggingAngle: number;        // Minimum angle before considered "sagging" (e.g., 195°)
  
  // Movement thresholds
  wormingThreshold: number;       // Allowed difference in shoulder vs hip movement (in normalized units)
  groundTouchThreshold: number;   // Threshold for detecting body touching ground
  
  // Duration thresholds
  pauseThresholdMs: number;       // Time in ms before considered "paused" in position
}

// Default configuration values
const DEFAULT_CONFIG: PushupAnalyzerConfig = {
  minElbowExtensionAngle: 160,
  maxElbowFlexionAngle: 90,
  maxPikingAngle: 165,
  minSaggingAngle: 195,
  wormingThreshold: 0.03,
  groundTouchThreshold: 0.02,
  pauseThresholdMs: 2000,
};

/**
 * Class for analyzing push-up form using MediaPipe pose landmarks
 */
export class PushupAnalyzer {
  private config: PushupAnalyzerConfig;
  private prevLandmarks: NormalizedLandmark[] | null = null;
  private prevTimestamp: number = 0;
  private minElbowAngle: number = 180;
  private timeInCurrentPosition: number = 0;
  private lastPositionChangeTime: number = 0;
  
  constructor(config: Partial<PushupAnalyzerConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }
  
  /**
   * Reset the analyzer state for a new set of push-ups
   */
  reset(): void {
    this.prevLandmarks = null;
    this.prevTimestamp = 0;
    this.minElbowAngle = 180;
    this.timeInCurrentPosition = 0;
    this.lastPositionChangeTime = 0;
  }
  
  /**
   * Analyze push-up form from pose landmarks
   * 
   * @param landmarks MediaPipe pose landmarks
   * @param timestamp Current timestamp in milliseconds
   * @returns Analysis results
   */
  analyzePushupForm(
    landmarks: NormalizedLandmark[],
    timestamp: number
  ): PushupFormAnalysis {
    // Calculate joint angles
    const leftElbowAngle = this.calculateAngle(
      landmarks[PoseLandmarkIndex.LEFT_SHOULDER],
      landmarks[PoseLandmarkIndex.LEFT_ELBOW],
      landmarks[PoseLandmarkIndex.LEFT_WRIST]
    );
    
    const rightElbowAngle = this.calculateAngle(
      landmarks[PoseLandmarkIndex.RIGHT_SHOULDER],
      landmarks[PoseLandmarkIndex.RIGHT_ELBOW],
      landmarks[PoseLandmarkIndex.RIGHT_WRIST]
    );
    
    // Calculate body alignment using midpoints
    const midShoulder = this.getMidpoint(
      landmarks[PoseLandmarkIndex.LEFT_SHOULDER],
      landmarks[PoseLandmarkIndex.RIGHT_SHOULDER]
    );
    
    const midHip = this.getMidpoint(
      landmarks[PoseLandmarkIndex.LEFT_HIP],
      landmarks[PoseLandmarkIndex.RIGHT_HIP]
    );
    
    const midAnkle = this.getMidpoint(
      landmarks[PoseLandmarkIndex.LEFT_ANKLE],
      landmarks[PoseLandmarkIndex.RIGHT_ANKLE]
    );
    
    // Calculate angle to check body alignment (shoulder-hip-ankle)
    const bodyAlignmentAngle = this.calculateAngle(midShoulder, midHip, midAnkle);
    
    // Check up and down positions
    const currentElbowAngle = Math.min(leftElbowAngle, rightElbowAngle);
    const isDownPosition = currentElbowAngle <= this.config.maxElbowFlexionAngle;
    const isUpPosition = currentElbowAngle >= this.config.minElbowExtensionAngle;
    
    // Track minimum elbow angle during the rep
    if (currentElbowAngle < this.minElbowAngle) {
      this.minElbowAngle = currentElbowAngle;
    }
    
    // Check body alignment issues
    const isBodySagging = bodyAlignmentAngle > this.config.minSaggingAngle;
    const isBodyPiking = bodyAlignmentAngle < this.config.maxPikingAngle;
    
    // Detect worming (shoulders and hips not moving in sync)
    let isWorming = false;
    if (this.prevLandmarks) {
      const shoulderMovement = Math.abs(midShoulder.y - this.getMidpoint(
        this.prevLandmarks[PoseLandmarkIndex.LEFT_SHOULDER],
        this.prevLandmarks[PoseLandmarkIndex.RIGHT_SHOULDER]
      ).y);
      
      const hipMovement = Math.abs(midHip.y - this.getMidpoint(
        this.prevLandmarks[PoseLandmarkIndex.LEFT_HIP],
        this.prevLandmarks[PoseLandmarkIndex.RIGHT_HIP]
      ).y);
      
      isWorming = Math.abs(shoulderMovement - hipMovement) > this.config.wormingThreshold;
    }
    
    // Detect disqualifying breaks
    const handsLiftedOff = this.detectLiftOff(
      landmarks[PoseLandmarkIndex.LEFT_WRIST],
      landmarks[PoseLandmarkIndex.RIGHT_WRIST],
      this.prevLandmarks ? [
        this.prevLandmarks[PoseLandmarkIndex.LEFT_WRIST],
        this.prevLandmarks[PoseLandmarkIndex.RIGHT_WRIST]
      ] : null
    );
    
    const feetLiftedOff = this.detectLiftOff(
      landmarks[PoseLandmarkIndex.LEFT_ANKLE],
      landmarks[PoseLandmarkIndex.RIGHT_ANKLE],
      this.prevLandmarks ? [
        this.prevLandmarks[PoseLandmarkIndex.LEFT_ANKLE],
        this.prevLandmarks[PoseLandmarkIndex.RIGHT_ANKLE]
      ] : null
    );
    
    // Detect knees touching ground
    const leftKneeY = landmarks[PoseLandmarkIndex.LEFT_KNEE].y;
    const rightKneeY = landmarks[PoseLandmarkIndex.RIGHT_KNEE].y;
    const leftHipY = landmarks[PoseLandmarkIndex.LEFT_HIP].y;
    const rightHipY = landmarks[PoseLandmarkIndex.RIGHT_HIP].y;
    
    const kneesTouchingGround = Math.abs(leftKneeY - leftHipY) < this.config.groundTouchThreshold || 
                               Math.abs(rightKneeY - rightHipY) < this.config.groundTouchThreshold;
    
    // Detect entire body touching ground
    const bodyTouchingGround = Math.abs(midShoulder.y - midHip.y) < this.config.groundTouchThreshold;
    
    // Check for pausing in position
    let isPaused = false;
    if (this.prevTimestamp > 0) {
      // Update time in current position
      const timeDiff = timestamp - this.prevTimestamp;
      
      if ((this.prevLandmarks && isUpPosition) || (this.prevLandmarks && isDownPosition)) {
        this.timeInCurrentPosition += timeDiff;
      } else {
        this.timeInCurrentPosition = 0;
        this.lastPositionChangeTime = timestamp;
      }
      
      isPaused = this.timeInCurrentPosition > this.config.pauseThresholdMs;
    }
    
    // Determine if the current rep is valid
    const isValidRep = !isBodySagging && 
                      !isBodyPiking && 
                      !isWorming && 
                      !handsLiftedOff && 
                      !feetLiftedOff && 
                      !kneesTouchingGround && 
                      !bodyTouchingGround && 
                      !isPaused && 
                      this.minElbowAngle <= this.config.maxElbowFlexionAngle;
    
    // Update state for next analysis
    this.prevLandmarks = [...landmarks];
    this.prevTimestamp = timestamp;
    
    // Return analysis results
    return {
      isDownPosition,
      isUpPosition,
      isValidRep,
      leftElbowAngle,
      rightElbowAngle,
      bodyAlignmentAngle,
      isBodySagging,
      isBodyPiking,
      isWorming,
      handsLiftedOff,
      feetLiftedOff,
      kneesTouchingGround,
      bodyTouchingGround,
      isPaused,
      minElbowAngleDuringRep: this.minElbowAngle
    };
  }
  
  /**
   * Calculate the angle between three points (in degrees)
   */
  private calculateAngle(
    a: NormalizedLandmark,
    b: NormalizedLandmark,
    c: NormalizedLandmark
  ): number {
    // Create vectors
    const vectorBA = {
      x: a.x - b.x,
      y: a.y - b.y,
      z: a.z - b.z
    };
    
    const vectorBC = {
      x: c.x - b.x,
      y: c.y - b.y,
      z: c.z - b.z
    };
    
    // Calculate dot product
    const dotProduct = vectorBA.x * vectorBC.x + vectorBA.y * vectorBC.y + vectorBA.z * vectorBC.z;
    
    // Calculate magnitudes
    const magnitudeBA = Math.sqrt(vectorBA.x * vectorBA.x + vectorBA.y * vectorBA.y + vectorBA.z * vectorBA.z);
    const magnitudeBC = Math.sqrt(vectorBC.x * vectorBC.x + vectorBC.y * vectorBC.y + vectorBC.z * vectorBC.z);
    
    // Calculate angle in radians
    const angleRad = Math.acos(dotProduct / (magnitudeBA * magnitudeBC));
    
    // Convert to degrees
    const angleDeg = angleRad * (180 / Math.PI);
    
    return angleDeg;
  }
  
  /**
   * Calculate midpoint between two landmarks
   */
  private getMidpoint(a: NormalizedLandmark, b: NormalizedLandmark): NormalizedLandmark {
    return {
      x: (a.x + b.x) / 2,
      y: (a.y + b.y) / 2,
      z: (a.z + b.z) / 2,
      visibility: Math.min(a.visibility || 0, b.visibility || 0)
    };
  }
  
  /**
   * Detect if landmarks have lifted off from their position
   */
  private detectLiftOff(
    leftLandmark: NormalizedLandmark,
    rightLandmark: NormalizedLandmark,
    prevLandmarks: NormalizedLandmark[] | null
  ): boolean {
    // If no previous landmarks, can't detect lift-off
    if (!prevLandmarks) return false;
    
    // Check for significant change in Y coordinate (vertical movement)
    const leftDiffY = Math.abs(leftLandmark.y - prevLandmarks[0].y);
    const rightDiffY = Math.abs(rightLandmark.y - prevLandmarks[1].y);
    
    // Detect if either landmark has moved significantly
    return leftDiffY > 0.03 || rightDiffY > 0.03;
  }
  
  /**
   * Reset minimum elbow angle tracked during a rep
   */
  resetMinElbowAngle(): void {
    this.minElbowAngle = 180;
  }
} 