import { NormalizedLandmark } from '../lib/types';
import { calculateAngle, calculateDistance } from './mathUtils';

// Import the landmark indices
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

export interface PullupAnalyzerConfig {
  // Angle thresholds
  minElbowLockoutAngle: number;  // Minimum angle for elbow lockout (down position)
  maxElbowTopAngle: number;      // Maximum elbow angle at top position
  
  // Position thresholds
  chinAboveBarThreshold: number; // How far chin must clear bar (in normalized units)
  
  // Movement thresholds
  maxHorizontalDisplacement: number; // Maximum allowed horizontal movement (for swing detection)
  maxKneeAngleChange: number;       // Maximum allowed knee angle change (for kipping detection)
  
  // Timing
  pauseThresholdMs: number;     // Time considered paused if no movement
  validRepTimeoutMs: number;    // Maximum time for a rep
}

export interface PullupFormAnalysis {
  // Angles
  leftElbowAngle: number;       // Left elbow angle
  rightElbowAngle: number;      // Right elbow angle
  
  // Positions
  isDownPosition: boolean;      // In the down position (dead hang)
  isUpPosition: boolean;        // In the up position (chin above bar)
  chinClearsBar: boolean;       // Whether chin is above the bar
  
  // Form issues
  isElbowLocked: boolean;       // Elbows are locked out in down position
  isSwinging: boolean;          // Excessive horizontal movement detected
  isKipping: boolean;           // Knee movement/kicking detected
  isPaused: boolean;            // User has paused too long
  
  // Rep validation
  isValidRep: boolean;          // Whether the rep meets all criteria
  repProgress: number;          // Progress through the rep (0-1)
  
  // Calibration references
  barY: number;                 // Calibrated Y position of the bar
  leftWristX: number;           // Initial X position of left wrist
  rightWristX: number;          // Initial X position of right wrist
  hipX: number;                 // Initial X position of hips
  
  // Tracking vars
  maxHorizontalDisplacement: number; // Maximum horizontal movement during rep
  maxKneeAngleChange: number;       // Maximum knee angle change during rep
  
  // Timestamps
  timestamp: number;            // Current timestamp
  lastMovementTimestamp: number; // Last significant movement timestamp
}

/**
 * Analyzes pull-up form using pose landmarks from MediaPipe Holistic
 */
export class PullupAnalyzer {
  private config: PullupAnalyzerConfig;
  private barY: number = 0;
  private initialLeftWristX: number = 0;
  private initialRightWristX: number = 0;
  private initialHipX: number = 0;
  private initialKneeAngle: number = 0;
  
  private lastAnalysis: PullupFormAnalysis | null = null;
  private inUpPosition: boolean = false;
  private inDownPosition: boolean = true; // Start in down position
  private lastMovementTimestamp: number = 0;
  private repStartTimestamp: number = 0;
  
  // Tracking variables for a single rep
  private maxHorizontalDisplacement: number = 0;
  private maxKneeAngleChange: number = 0;
  
  constructor(config?: Partial<PullupAnalyzerConfig>) {
    // Default configuration
    this.config = {
      minElbowLockoutAngle: 160,  // Minimum angle for elbow lockout (dead hang)
      maxElbowTopAngle: 90,       // Maximum elbow angle at top position
      chinAboveBarThreshold: 0.05, // Chin should be 0.05 units above the bar
      maxHorizontalDisplacement: 0.07, // Max horizontal movement
      maxKneeAngleChange: 20,     // Max knee angle change during rep
      pauseThresholdMs: 2000,     // 2 seconds pause threshold
      validRepTimeoutMs: 10000,   // 10 seconds max for a valid rep
      ...config
    };
  }
  
  /**
   * Set calibration data from initial position (dead hang)
   */
  setCalibrationData(landmarks: NormalizedLandmark[]): void {
    if (!landmarks || landmarks.length < 33) return;
    
    // Set bar height based on wrist positions (average)
    this.barY = (landmarks[PoseLandmarkIndex.LEFT_WRIST].y + 
                landmarks[PoseLandmarkIndex.RIGHT_WRIST].y) / 2;
    
    // Record initial wrist X positions for swing detection
    this.initialLeftWristX = landmarks[PoseLandmarkIndex.LEFT_WRIST].x;
    this.initialRightWristX = landmarks[PoseLandmarkIndex.RIGHT_WRIST].x;
    
    // Record initial hip X position (average of left and right)
    this.initialHipX = (landmarks[PoseLandmarkIndex.LEFT_HIP].x + 
                       landmarks[PoseLandmarkIndex.RIGHT_HIP].x) / 2;
    
    // Calculate initial knee angle (average of left and right)
    const leftKneeAngle = calculateAngle(
      landmarks[PoseLandmarkIndex.LEFT_HIP].x, landmarks[PoseLandmarkIndex.LEFT_HIP].y,
      landmarks[PoseLandmarkIndex.LEFT_KNEE].x, landmarks[PoseLandmarkIndex.LEFT_KNEE].y,
      landmarks[PoseLandmarkIndex.LEFT_ANKLE].x, landmarks[PoseLandmarkIndex.LEFT_ANKLE].y
    );
    
    const rightKneeAngle = calculateAngle(
      landmarks[PoseLandmarkIndex.RIGHT_HIP].x, landmarks[PoseLandmarkIndex.RIGHT_HIP].y,
      landmarks[PoseLandmarkIndex.RIGHT_KNEE].x, landmarks[PoseLandmarkIndex.RIGHT_KNEE].y,
      landmarks[PoseLandmarkIndex.RIGHT_ANKLE].x, landmarks[PoseLandmarkIndex.RIGHT_ANKLE].y
    );
    
    this.initialKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    
    console.log('Pull-up calibration set:', { 
      barY: this.barY, 
      leftWristX: this.initialLeftWristX,
      rightWristX: this.initialRightWristX,
      hipX: this.initialHipX,
      kneeAngle: this.initialKneeAngle
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
    this.maxHorizontalDisplacement = 0;
    this.maxKneeAngleChange = 0;
  }
  
  /**
   * Analyze pull-up form from pose landmarks
   */
  analyzePullupForm(landmarks: NormalizedLandmark[], timestamp: number): PullupFormAnalysis {
    if (!landmarks || landmarks.length < 33) {
      return this.createEmptyAnalysis(timestamp);
    }
    
    // If we haven't set initial calibration, do it now
    if (this.barY === 0) {
      this.setCalibrationData(landmarks);
    }
    
    // Extract landmarks we need
    const nose = landmarks[PoseLandmarkIndex.NOSE];
    const leftShoulder = landmarks[PoseLandmarkIndex.LEFT_SHOULDER];
    const rightShoulder = landmarks[PoseLandmarkIndex.RIGHT_SHOULDER];
    const leftElbow = landmarks[PoseLandmarkIndex.LEFT_ELBOW];
    const rightElbow = landmarks[PoseLandmarkIndex.RIGHT_ELBOW];
    const leftWrist = landmarks[PoseLandmarkIndex.LEFT_WRIST];
    const rightWrist = landmarks[PoseLandmarkIndex.RIGHT_WRIST];
    const leftHip = landmarks[PoseLandmarkIndex.LEFT_HIP];
    const rightHip = landmarks[PoseLandmarkIndex.RIGHT_HIP];
    const leftKnee = landmarks[PoseLandmarkIndex.LEFT_KNEE];
    const rightKnee = landmarks[PoseLandmarkIndex.RIGHT_KNEE];
    const leftAnkle = landmarks[PoseLandmarkIndex.LEFT_ANKLE];
    const rightAnkle = landmarks[PoseLandmarkIndex.RIGHT_ANKLE];
    
    // Calculate elbow angles
    const leftElbowAngle = calculateAngle(
      leftShoulder.x, leftShoulder.y,
      leftElbow.x, leftElbow.y,
      leftWrist.x, leftWrist.y
    );
    
    const rightElbowAngle = calculateAngle(
      rightShoulder.x, rightShoulder.y,
      rightElbow.x, rightElbow.y,
      rightWrist.x, rightWrist.y
    );
    
    // Check elbow lockout (dead hang position)
    const isElbowLocked = 
      leftElbowAngle >= this.config.minElbowLockoutAngle && 
      rightElbowAngle >= this.config.minElbowLockoutAngle;
    
    // Check chin above bar
    const chinClearsBar = nose.y < (this.barY - this.config.chinAboveBarThreshold);
    
    // Calculate current knee angles
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
    
    const currentKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    
    // Calculate horizontal displacement for swing detection
    const currentHipX = (leftHip.x + rightHip.x) / 2;
    const hipDisplacement = Math.abs(currentHipX - this.initialHipX);
    
    const leftWristDisplacement = Math.abs(leftWrist.x - this.initialLeftWristX);
    const rightWristDisplacement = Math.abs(rightWrist.x - this.initialRightWristX);
    const wristDisplacement = Math.max(leftWristDisplacement, rightWristDisplacement);
    
    // Use the larger of hip and wrist displacement to detect swinging
    const horizontalDisplacement = Math.max(hipDisplacement, wristDisplacement);
    
    // Update max horizontal displacement during this rep
    this.maxHorizontalDisplacement = Math.max(this.maxHorizontalDisplacement, horizontalDisplacement);
    
    // Update max knee angle change during this rep
    const kneeAngleChange = Math.abs(currentKneeAngle - this.initialKneeAngle);
    this.maxKneeAngleChange = Math.max(this.maxKneeAngleChange, kneeAngleChange);
    
    // Determine if swinging or kipping is happening
    const isSwinging = this.maxHorizontalDisplacement > this.config.maxHorizontalDisplacement;
    const isKipping = this.maxKneeAngleChange > this.config.maxKneeAngleChange;
    
    // Determine up/down positions
    const isDownPositionNow = 
      isElbowLocked && 
      !chinClearsBar;
    
    const isUpPositionNow = chinClearsBar;
    
    // Check for movement (based on elbow angle changes)
    let isPaused = false;
    if (this.lastAnalysis) {
      const significantMovement = 
        Math.abs(leftElbowAngle - this.lastAnalysis.leftElbowAngle) > 5 ||
        Math.abs(rightElbowAngle - this.lastAnalysis.rightElbowAngle) > 5;
      
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
      // Entered up position
      this.inUpPosition = true;
      console.log('Pull-up: Reached top position');
    } else if (!this.inDownPosition && isDownPositionNow) {
      // Entered down position (dead hang)
      this.inDownPosition = true;
      this.inUpPosition = false;
      
      // Reset tracking variables for the next rep
      this.maxHorizontalDisplacement = 0;
      this.maxKneeAngleChange = 0;
      
      // Start timing for a new rep
      this.repStartTimestamp = timestamp;
      console.log('Pull-up: Returned to dead hang');
    } else if (this.inUpPosition && !isUpPositionNow) {
      // Exited up position
      this.inUpPosition = false;
    } else if (this.inDownPosition && !isDownPositionNow) {
      // Exited down position
      this.inDownPosition = false;
    }
    
    // Calculate rep progress (0 to 1)
    let repProgress = 0;
    if (this.inUpPosition) {
      repProgress = 1; // Fully up
    } else if (!this.inDownPosition) {
      // Interpolate based on nose position relative to bar
      const topNoseY = this.barY - this.config.chinAboveBarThreshold; // Target nose Y at top
      const bottomNoseY = this.barY + 0.2; // Approximate nose Y at bottom (dead hang)
      
      if (nose.y <= topNoseY) {
        repProgress = 1; // At or beyond top position
      } else if (nose.y >= bottomNoseY) {
        repProgress = 0; // At or below bottom position
      } else {
        // Linear interpolation between bottom and top position
        repProgress = 1 - ((nose.y - topNoseY) / (bottomNoseY - topNoseY));
      }
      
      // Ensure progress is between 0 and 1
      repProgress = Math.max(0, Math.min(1, repProgress));
    }
    
    // Check if this is a valid rep
    const isValidRep = 
      isElbowLocked && // Proper elbow lockout in down position
      chinClearsBar && // Chin clears the bar in up position
      !isSwinging &&   // No excessive swinging
      !isKipping &&    // No kipping/kicking
      !isPaused;       // No excessive pausing
    
    const analysis: PullupFormAnalysis = {
      leftElbowAngle,
      rightElbowAngle,
      isDownPosition: this.inDownPosition,
      isUpPosition: this.inUpPosition,
      chinClearsBar,
      isElbowLocked,
      isSwinging,
      isKipping,
      isPaused,
      isValidRep,
      repProgress,
      barY: this.barY,
      leftWristX: this.initialLeftWristX,
      rightWristX: this.initialRightWristX,
      hipX: this.initialHipX,
      maxHorizontalDisplacement: this.maxHorizontalDisplacement,
      maxKneeAngleChange: this.maxKneeAngleChange,
      timestamp,
      lastMovementTimestamp: this.lastMovementTimestamp
    };
    
    this.lastAnalysis = analysis;
    return analysis;
  }
  
  /**
   * Create empty analysis object when landmarks are unavailable
   */
  private createEmptyAnalysis(timestamp: number): PullupFormAnalysis {
    return {
      leftElbowAngle: 180,
      rightElbowAngle: 180,
      isDownPosition: true,
      isUpPosition: false,
      chinClearsBar: false,
      isElbowLocked: true,
      isSwinging: false,
      isKipping: false,
      isPaused: false,
      isValidRep: false,
      repProgress: 0,
      barY: this.barY,
      leftWristX: this.initialLeftWristX,
      rightWristX: this.initialRightWristX,
      hipX: this.initialHipX,
      maxHorizontalDisplacement: 0,
      maxKneeAngleChange: 0,
      timestamp,
      lastMovementTimestamp: this.lastMovementTimestamp
    };
  }
} 