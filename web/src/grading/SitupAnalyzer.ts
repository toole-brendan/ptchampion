import { NormalizedLandmark } from '../lib/types';
import { calculateAngle, calculateDistance } from './mathUtils';

// Index reference for pose landmarks
export const PoseLandmarkIndex = {
  NOSE: 0,
  LEFT_EYE_INNER: 1,
  LEFT_EYE: 2,
  LEFT_EYE_OUTER: 3,
  RIGHT_EYE_INNER: 4,
  RIGHT_EYE: 5,
  RIGHT_EYE_OUTER: 6,
  LEFT_EAR: 7,
  RIGHT_EAR: 8,
  MOUTH_LEFT: 9,
  MOUTH_RIGHT: 10,
  LEFT_SHOULDER: 11,
  RIGHT_SHOULDER: 12,
  LEFT_ELBOW: 13,
  RIGHT_ELBOW: 14,
  LEFT_WRIST: 15,
  RIGHT_WRIST: 16,
  LEFT_PINKY: 17,
  RIGHT_PINKY: 18,
  LEFT_INDEX: 19,
  RIGHT_INDEX: 20,
  LEFT_THUMB: 21,
  RIGHT_THUMB: 22,
  LEFT_HIP: 23,
  RIGHT_HIP: 24,
  LEFT_KNEE: 25,
  RIGHT_KNEE: 26,
  LEFT_ANKLE: 27,
  RIGHT_ANKLE: 28,
};

export interface SitupAnalyzerConfig {
  // Angle thresholds
  minTrunkAngle: number;        // Minimum angle for trunk verticality
  maxTrunkAngle: number;        // Maximum angle for trunk verticality
  minKneeAngle: number;         // Minimum knee angle
  maxKneeAngle: number;         // Maximum knee angle
  
  // Distance thresholds
  wristToHeadMaxDistance: number; // Maximum distance between wrists and head
  wristsMaxDistance: number;      // Maximum distance between wrists
  shoulderGroundThreshold: number; // Maximum distance from ground for shoulders
  hipLiftThreshold: number;       // Maximum allowed hip lift from ground
  
  // Timing and position
  pauseThresholdMs: number;     // Time considered paused if no movement
  validRepTimeoutMs: number;    // Maximum time for a rep
}

export interface SitupFormAnalysis {
  // Angles
  trunkAngle: number;           // Angle of trunk (shoulder-hip-knee)
  leftKneeAngle: number;        // Left knee angle (hip-knee-ankle)
  rightKneeAngle: number;       // Right knee angle (hip-knee-ankle)
  
  // Positions
  isUpPosition: boolean;        // In the up position (sit-up completed)
  isDownPosition: boolean;      // In the down position (starting/ending)
  
  // Form issues
  isHandPositionCorrect: boolean; // Hands properly positioned behind head
  isShoulderBladeGrounded: boolean; // Shoulders properly on ground in down position
  isHipStable: boolean;          // Hip remains stable (not lifting)
  isKneeAngleCorrect: boolean;   // Knee angle is within acceptable range
  isPaused: boolean;             // User has paused too long
  
  // Rep validation
  isValidRep: boolean;           // Whether the rep meets all criteria
  repProgress: number;           // Progress through the rep (0-1)
  
  // Calibration references
  initialShoulderY: number;      // Calibrated Y position of shoulders
  initialHipY: number;           // Calibrated Y position of hips
  
  // Timestamps
  timestamp: number;             // Current timestamp
  lastMovementTimestamp: number; // Last significant movement timestamp
}

/**
 * Analyzes sit-up form using pose landmarks from MediaPipe Holistic
 */
export class SitupAnalyzer {
  private config: SitupAnalyzerConfig;
  private initialShoulderY: number = 0;
  private initialHipY: number = 0;
  private lastAnalysis: SitupFormAnalysis | null = null;
  private inUpPosition: boolean = false;
  private inDownPosition: boolean = true; // Start in down position
  private lastMovementTimestamp: number = 0;
  private repStartTimestamp: number = 0;
  
  constructor(config?: Partial<SitupAnalyzerConfig>) {
    // Default configuration
    this.config = {
      minTrunkAngle: 60,         // At least 60° vertical trunk for up position
      maxTrunkAngle: 95,         // Not more than 95° for up position
      minKneeAngle: 70,          // Minimum knee angle
      maxKneeAngle: 110,         // Maximum knee angle
      wristToHeadMaxDistance: 0.15, // Maximum normalized distance for wrists to head
      wristsMaxDistance: 0.1,    // Maximum normalized distance between wrists
      shoulderGroundThreshold: 0.03, // Max shoulder movement from ground
      hipLiftThreshold: 0.03,    // Max hip lift from initial position
      pauseThresholdMs: 2000,    // 2 seconds pause threshold
      validRepTimeoutMs: 10000,  // 10 seconds max for a valid rep
      ...config
    };
  }
  
  /**
   * Set calibration data from initial position
   */
  setCalibrationData(landmarks: NormalizedLandmark[]): void {
    if (!landmarks || landmarks.length < 33) return;
    
    // Use average of left and right shoulders for a more stable measurement
    this.initialShoulderY = (landmarks[PoseLandmarkIndex.LEFT_SHOULDER].y + 
                           landmarks[PoseLandmarkIndex.RIGHT_SHOULDER].y) / 2;
    
    // Use average of left and right hips for a more stable measurement
    this.initialHipY = (landmarks[PoseLandmarkIndex.LEFT_HIP].y + 
                       landmarks[PoseLandmarkIndex.RIGHT_HIP].y) / 2;
    
    console.log('Sit-up calibration set:', { 
      shoulderY: this.initialShoulderY, 
      hipY: this.initialHipY 
    });
  }
  
  /**
   * Reset analyzer state
   */
  reset(): void {
    this.inUpPosition = false;
    this.inDownPosition = true;
    this.lastMovementTimestamp = 0;
    this.repStartTimestamp = 0;
    this.lastAnalysis = null;
  }
  
  /**
   * Analyze sit-up form from pose landmarks
   */
  analyzeSitupForm(landmarks: NormalizedLandmark[], timestamp: number): SitupFormAnalysis {
    if (!landmarks || landmarks.length < 33) {
      return this.createEmptyAnalysis(timestamp);
    }
    
    // If we haven't set initial calibration, do it now
    if (this.initialShoulderY === 0 || this.initialHipY === 0) {
      this.setCalibrationData(landmarks);
    }
    
    const nose = landmarks[PoseLandmarkIndex.NOSE];
    const leftEar = landmarks[PoseLandmarkIndex.LEFT_EAR];
    const rightEar = landmarks[PoseLandmarkIndex.RIGHT_EAR];
    const leftShoulder = landmarks[PoseLandmarkIndex.LEFT_SHOULDER];
    const rightShoulder = landmarks[PoseLandmarkIndex.RIGHT_SHOULDER];
    const leftHip = landmarks[PoseLandmarkIndex.LEFT_HIP];
    const rightHip = landmarks[PoseLandmarkIndex.RIGHT_HIP];
    const leftKnee = landmarks[PoseLandmarkIndex.LEFT_KNEE];
    const rightKnee = landmarks[PoseLandmarkIndex.RIGHT_KNEE];
    const leftAnkle = landmarks[PoseLandmarkIndex.LEFT_ANKLE];
    const rightAnkle = landmarks[PoseLandmarkIndex.RIGHT_ANKLE];
    const leftWrist = landmarks[PoseLandmarkIndex.LEFT_WRIST];
    const rightWrist = landmarks[PoseLandmarkIndex.RIGHT_WRIST];
    
    // Calculate angles
    // Trunk angle - use shoulder-hip-knee angle as proxy for verticality
    const leftTrunkAngle = calculateAngle(
      leftShoulder.x, leftShoulder.y,
      leftHip.x, leftHip.y,
      leftKnee.x, leftKnee.y
    );
    
    const rightTrunkAngle = calculateAngle(
      rightShoulder.x, rightShoulder.y,
      rightHip.x, rightHip.y,
      rightKnee.x, rightKnee.y
    );
    
    // Average trunk angle for more stability
    const trunkAngle = (leftTrunkAngle + rightTrunkAngle) / 2;
    
    // Knee angles
    const leftKneeAngle = calculateAngle(
      leftHip.x, leftHip.y,
      leftKnee.x, leftKnee.y,
      leftAnkle.x, leftAnkle.y
    );
    
    const rightKneeAngle = calculateAngle(
      rightHip.x, rightHip.y,
      rightKnee.x, rightKnee.y,
      rightAnkle.x, rightAnkle.y
    );
    
    // Check hand position - hands should be behind head
    const leftWristToHeadDist = Math.min(
      calculateDistance(leftWrist.x, leftWrist.y, leftEar.x, leftEar.y),
      calculateDistance(leftWrist.x, leftWrist.y, rightEar.x, rightEar.y)
    );
    
    const rightWristToHeadDist = Math.min(
      calculateDistance(rightWrist.x, rightWrist.y, leftEar.x, leftEar.y),
      calculateDistance(rightWrist.x, rightWrist.y, rightEar.x, rightEar.y)
    );
    
    const wristsToDist = calculateDistance(
      leftWrist.x, leftWrist.y,
      rightWrist.x, rightWrist.y
    );
    
    const isHandPositionCorrect = 
      leftWristToHeadDist < this.config.wristToHeadMaxDistance && 
      rightWristToHeadDist < this.config.wristToHeadMaxDistance &&
      wristsToDist < this.config.wristsMaxDistance;
    
    // Check if shoulders are grounded in down position
    const currentShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    const shoulderYDiff = Math.abs(currentShoulderY - this.initialShoulderY);
    const isShoulderBladeGrounded = shoulderYDiff < this.config.shoulderGroundThreshold;
    
    // Check if hips are stable
    const currentHipY = (leftHip.y + rightHip.y) / 2;
    const hipYDiff = Math.abs(currentHipY - this.initialHipY);
    const isHipStable = hipYDiff < this.config.hipLiftThreshold;
    
    // Check knee angle
    const isKneeAngleCorrect = 
      leftKneeAngle >= this.config.minKneeAngle && 
      leftKneeAngle <= this.config.maxKneeAngle &&
      rightKneeAngle >= this.config.minKneeAngle && 
      rightKneeAngle <= this.config.maxKneeAngle;
    
    // Determine up/down positions
    // Up position: trunk is more vertical and nose is higher than hips
    const headY = nose.y;  // Use nose Y position
    const hipY = (leftHip.y + rightHip.y) / 2;
    
    // For sit-ups, up position is when head is higher than hip line and trunk is more vertical
    const isUpPositionNow = 
      headY < hipY && 
      trunkAngle >= this.config.minTrunkAngle && 
      trunkAngle <= this.config.maxTrunkAngle;
    
    // Down position is when shoulders are back on the ground
    const isDownPositionNow = 
      isShoulderBladeGrounded && 
      headY > hipY;
    
    // Check for movement
    let isPaused = false;
    if (this.lastAnalysis) {
      const significantMovement = 
        Math.abs(trunkAngle - this.lastAnalysis.trunkAngle) > 5;
      
      if (significantMovement) {
        this.lastMovementTimestamp = timestamp;
      } else {
        // Check if paused too long
        isPaused = (timestamp - this.lastMovementTimestamp) > this.config.pauseThresholdMs;
      }
    } else {
      this.lastMovementTimestamp = timestamp;
    }
    
    // Handle state transitions
    if (!this.inUpPosition && isUpPositionNow) {
      this.inUpPosition = true;
      
      // If we were in down position, this completes a rep
      if (this.inDownPosition) {
        console.log('Sit-up: Completed up position');
      }
    } else if (!this.inDownPosition && isDownPositionNow) {
      this.inDownPosition = true;
      this.inUpPosition = false;
      
      // Start timing for a new rep
      this.repStartTimestamp = timestamp;
      console.log('Sit-up: Returned to down position');
    }
    
    // Calculate rep progress (0 to 1)
    let repProgress = 0;
    if (this.inUpPosition) {
      repProgress = 1; // Fully up
    } else if (!this.inDownPosition) {
      // If not in down or up position, calculate intermediate progress
      // This is a simplification - in reality you'd use more geometrical data
      const maxHeadY = hipY; // At maximum up position, head should be at hip line or higher
      const minHeadY = this.initialShoulderY; // At rest, head is near shoulders on ground
      
      if (headY < maxHeadY) {
        repProgress = 1; // Beyond expected up position
      } else if (headY > minHeadY) {
        repProgress = 0; // At or below starting position
      } else {
        // Linear interpolation between down and up positions
        repProgress = 1 - ((headY - maxHeadY) / (minHeadY - maxHeadY));
      }
      
      // Ensure progress is between 0 and 1
      repProgress = Math.max(0, Math.min(1, repProgress));
    }
    
    // Check if this is a valid rep
    const isValidRep = 
      isHandPositionCorrect && 
      isKneeAngleCorrect && 
      isHipStable && 
      !isPaused;
    
    const analysis: SitupFormAnalysis = {
      trunkAngle,
      leftKneeAngle,
      rightKneeAngle,
      isUpPosition: this.inUpPosition,
      isDownPosition: this.inDownPosition,
      isHandPositionCorrect,
      isShoulderBladeGrounded,
      isHipStable,
      isKneeAngleCorrect,
      isPaused,
      isValidRep,
      repProgress,
      initialShoulderY: this.initialShoulderY,
      initialHipY: this.initialHipY,
      timestamp,
      lastMovementTimestamp: this.lastMovementTimestamp
    };
    
    this.lastAnalysis = analysis;
    return analysis;
  }
  
  /**
   * Create empty analysis object for when landmarks are unavailable
   */
  private createEmptyAnalysis(timestamp: number): SitupFormAnalysis {
    return {
      trunkAngle: 0,
      leftKneeAngle: 0,
      rightKneeAngle: 0,
      isUpPosition: false,
      isDownPosition: true,
      isHandPositionCorrect: false,
      isShoulderBladeGrounded: true,
      isHipStable: true,
      isKneeAngleCorrect: false,
      isPaused: false,
      isValidRep: false,
      repProgress: 0,
      initialShoulderY: this.initialShoulderY,
      initialHipY: this.initialHipY,
      timestamp,
      lastMovementTimestamp: this.lastMovementTimestamp
    };
  }
} 