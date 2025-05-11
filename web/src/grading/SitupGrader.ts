/**
 * SitupGrader.ts
 * 
 * Implements sit-up specific grading logic.
 * This encapsulates the state machine and form evaluation criteria for sit-ups.
 */

import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { BaseExerciseGrader, GradingResult } from './ExerciseGrader';
import { PoseLandmarkIndex } from '../services/PoseLandmarkIndex';

/**
 * Constants for sit-up form evaluation
 */
export const SITUP_CONSTANTS = {
  // Min hip angle (shoulder-hip-knee) when DOWN (closer to 180)
  THRESHOLD_ANGLE_DOWN: 160,
  
  // Max hip angle (shoulder-hip-knee) when UP (more acute)
  THRESHOLD_ANGLE_UP: 80,
  
  // Max wrist-ear distance relative to shoulder width
  HAND_POSITION_THRESHOLD_FACTOR: 0.6,
  
  // Max allowed relative vertical ankle movement
  FOOT_LIFT_THRESHOLD: 0.08,
  
  // Visibility threshold for landmarks
  VISIBILITY_THRESHOLD: 0.6
};

/**
 * Required landmarks for sit-up tracking
 */
const REQUIRED_SITUP_LANDMARKS = [
  PoseLandmarkIndex.LEFT_SHOULDER,
  PoseLandmarkIndex.RIGHT_SHOULDER,
  PoseLandmarkIndex.LEFT_HIP,
  PoseLandmarkIndex.RIGHT_HIP,
  PoseLandmarkIndex.LEFT_KNEE,
  PoseLandmarkIndex.RIGHT_KNEE,
  PoseLandmarkIndex.LEFT_ANKLE,
  PoseLandmarkIndex.RIGHT_ANKLE,
  PoseLandmarkIndex.LEFT_WRIST,
  PoseLandmarkIndex.RIGHT_WRIST,
  PoseLandmarkIndex.LEFT_EAR,
  PoseLandmarkIndex.RIGHT_EAR
];

/**
 * Sit-up grader that implements the exercise state machine and form evaluation
 */
export class SitupGrader extends BaseExerciseGrader {
  // Track form faults during the current rep
  private formFaultDuringRep: boolean = false;
  private currentFormFault: string | null = null;
  
  // Store initial ankle positions to check for foot movement
  private initialLeftAnkleY: number | null = null;
  private initialRightAnkleY: number | null = null;
  
  constructor() {
    super('SITUP');
  }
  
  /**
   * Process a new frame of pose landmarks and update the sit-up state
   * @param landmarks Array of pose landmarks from MediaPipe
   * @returns GradingResult with updated state and rep information
   */
  processPose(landmarks: NormalizedLandmark[]): GradingResult {
    // Default result with no rep increment and no form fault
    let result: GradingResult = {
      state: this.state,
      repIncrement: 0,
      hasFormFault: false,
      formScore: 100 // Start with perfect form, deduct as needed
    };
    
    // Check if all required landmarks are visible
    if (!this.areLandmarksVisible(landmarks, REQUIRED_SITUP_LANDMARKS, SITUP_CONSTANTS.VISIBILITY_THRESHOLD)) {
      // Not enough landmarks visible for reliable tracking
      if (this.state !== 'start') {
        // Only reset state and show message if we were in the middle of tracking
        this.state = 'start';
        this.formFaultDuringRep = false;
        this.currentFormFault = null;
        this.initialLeftAnkleY = null;
        this.initialRightAnkleY = null;
        
        result.state = 'start';
        result.formFault = "Ensure full body is visible";
        result.hasFormFault = true;
      }
      return result;
    }
    
    // Extract relevant landmarks
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
    const leftEar = landmarks[PoseLandmarkIndex.LEFT_EAR];
    const rightEar = landmarks[PoseLandmarkIndex.RIGHT_EAR];
    
    // Calculate angles and distances
    const leftHipAngle = this.calculateAngle(leftShoulder, leftHip, leftKnee);
    const rightHipAngle = this.calculateAngle(rightShoulder, rightHip, rightKnee);
    const hipAngle = (leftHipAngle + rightHipAngle) / 2; // Average hip angle
    
    const shoulderWidth = this.calculateDistance(leftShoulder, rightShoulder);
    const leftHandDist = this.calculateDistance(leftWrist, leftEar);
    const rightHandDist = this.calculateDistance(rightWrist, rightEar);
    
    const leftHipKneeDist = this.calculateDistance(leftHip, leftKnee);
    const rightHipKneeDist = this.calculateDistance(rightHip, rightKnee);
    const avgHipKneeDist = (leftHipKneeDist + rightHipKneeDist) / 2;
    
    // Check form conditions
    const handsBehindHead = leftHandDist < SITUP_CONSTANTS.HAND_POSITION_THRESHOLD_FACTOR * shoulderWidth &&
                            rightHandDist < SITUP_CONSTANTS.HAND_POSITION_THRESHOLD_FACTOR * shoulderWidth;
    
    // Check foot lift relative to initial position when down
    let feetOnGround = true;
    if (this.initialLeftAnkleY !== null && this.initialRightAnkleY !== null && avgHipKneeDist > 0.01) {
      // Check only if we have initial positions and non-zero hip-knee distance
      const leftAnkleLift = this.initialLeftAnkleY - leftAnkle.y; // Y decreases upwards
      const rightAnkleLift = this.initialRightAnkleY - rightAnkle.y;
      const maxLiftThreshold = SITUP_CONSTANTS.FOOT_LIFT_THRESHOLD * avgHipKneeDist;
      
      if (leftAnkleLift > maxLiftThreshold || rightAnkleLift > maxLiftThreshold) {
        feetOnGround = false;
      }
    }
    
    // Check position states based on hip angle
    const isDown = hipAngle >= SITUP_CONSTANTS.THRESHOLD_ANGLE_DOWN;
    const isUp = hipAngle <= SITUP_CONSTANTS.THRESHOLD_ANGLE_UP;
    
    // Check for form faults
    let currentFormFault = false;
    let faultMsg = "";
    
    if (!handsBehindHead) {
      faultMsg = "Keep hands behind head!";
      currentFormFault = true;
      result.formScore = 85; // Deduct points for incorrect hand position
    }
    
    if (!feetOnGround && this.state !== 'start' && this.initialLeftAnkleY !== null) {
      faultMsg = "Keep feet on the ground!";
      currentFormFault = true;
      result.formScore = 80; // Deduct points for foot lift
    }
    
    // Update persistent form fault flag if a fault occurs during the rep cycle
    if (currentFormFault) {
      this.formFaultDuringRep = true;
      this.currentFormFault = faultMsg;
      result.formFault = faultMsg;
      result.hasFormFault = true;
    }
    
    // State machine transitions
    switch (this.state) {
      case 'start':
        if (isDown) {
          // Initial down position reached
          this.state = 'down';
          result.state = 'down';
          this.formFaultDuringRep = currentFormFault; // Record initial form state
          this.initialLeftAnkleY = leftAnkle.y;
          this.initialRightAnkleY = rightAnkle.y;
          console.log("State -> DOWN (Ready, Initial Feet Y recorded)");
        }
        break;
        
      case 'down':
        if (isUp) {
          // Reached the UP position
          this.state = 'up';
          result.state = 'up';
          
          if (!this.formFaultDuringRep) {
            // Only count if no form fault occurred during the upward movement
            result.repIncrement = 1; // Count rep!
            console.log("State -> UP (Rep Counted:", ", Hip Angle:", hipAngle.toFixed(0), ")");
          } else {
            // Reached UP but form was bad during the rep
            console.warn("State -> UP (Rep INVALID - Form Fault Detected, Hip Angle:", hipAngle.toFixed(0), ")");
            result.formFault = this.currentFormFault || "Invalid Rep - Check Form";
            result.hasFormFault = true;
          }
        }
        break;
        
      case 'up':
        if (isDown) {
          // Returned to the DOWN position, reset for next rep
          this.state = 'down';
          result.state = 'down';
          this.formFaultDuringRep = currentFormFault; // Reset fault flag based on current form at bottom
          this.initialLeftAnkleY = leftAnkle.y; // Record new initial ankle positions
          this.initialRightAnkleY = rightAnkle.y;
          console.log("State -> DOWN (Completed Rep Cycle, Ready for Next)");
        }
        break;
    }
    
    return result;
  }
  
  /**
   * Reset the sit-up grader to its initial state
   */
  reset(): void {
    super.reset();
    this.formFaultDuringRep = false;
    this.currentFormFault = null;
    this.initialLeftAnkleY = null;
    this.initialRightAnkleY = null;
  }
}

export default SitupGrader; 