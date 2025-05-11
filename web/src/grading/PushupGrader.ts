/**
 * PushupGrader.ts
 * 
 * Implements push-up specific grading logic.
 * This encapsulates the state machine and form evaluation criteria for push-ups.
 */

import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { BaseExerciseGrader, GradingResult } from './ExerciseGrader';
import { PoseLandmarkIndex } from '../services/PoseLandmarkIndex';

/**
 * Constants for push-up form evaluation
 */
export const PUSHUP_CONSTANTS = {
  // Threshold angle when arms are bent/down (elbows)
  THRESHOLD_ANGLE_DOWN: 90, 
  
  // Threshold angle when arms are straight/up (elbows)
  THRESHOLD_ANGLE_UP: 160,
  
  // Minimum angle for straight back (shoulder-hip-knee)
  BACK_STRAIGHT_THRESHOLD_ANGLE: 165,
  
  // Visibility threshold for landmarks
  VISIBILITY_THRESHOLD: 0.6
};

/**
 * Required landmarks for push-up tracking
 */
const REQUIRED_PUSHUP_LANDMARKS = [
  PoseLandmarkIndex.LEFT_SHOULDER,
  PoseLandmarkIndex.RIGHT_SHOULDER,
  PoseLandmarkIndex.LEFT_ELBOW,
  PoseLandmarkIndex.RIGHT_ELBOW,
  PoseLandmarkIndex.LEFT_WRIST,
  PoseLandmarkIndex.RIGHT_WRIST,
  PoseLandmarkIndex.LEFT_HIP,
  PoseLandmarkIndex.RIGHT_HIP,
  PoseLandmarkIndex.LEFT_KNEE,
  PoseLandmarkIndex.RIGHT_KNEE
];

/**
 * Push-up grader that implements the exercise state machine and form evaluation
 */
export class PushupGrader extends BaseExerciseGrader {
  // Current state and previous state for transitions
  private previousState: 'start' | 'down' | 'up' = 'start';
  
  // Track form faults during the current rep
  private currentFormFault: string | null = null;
  
  constructor() {
    super('PUSHUP');
  }
  
  /**
   * Process a new frame of pose landmarks and update the push-up state
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
    if (!this.areLandmarksVisible(landmarks, REQUIRED_PUSHUP_LANDMARKS, PUSHUP_CONSTANTS.VISIBILITY_THRESHOLD)) {
      // Not enough landmarks visible for reliable tracking
      if (this.state !== 'start') {
        // Only reset state and show message if we were in the middle of tracking
        this.state = 'start';
        this.currentFormFault = null;
        result.state = 'start';
        result.formFault = "Ensure full body is visible";
        result.hasFormFault = true;
      }
      return result;
    }
    
    // Extract relevant landmarks
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
    
    // Calculate angles for form evaluation
    const leftElbowAngle = this.calculateAngle(leftShoulder, leftElbow, leftWrist);
    const rightElbowAngle = this.calculateAngle(rightShoulder, rightElbow, rightWrist);
    const elbowAngle = (leftElbowAngle + rightElbowAngle) / 2; // Average elbow angle
    
    const leftBodyAngle = this.calculateAngle(leftShoulder, leftHip, leftKnee);
    const rightBodyAngle = this.calculateAngle(rightShoulder, rightHip, rightKnee);
    const bodyAngle = (leftBodyAngle + rightBodyAngle) / 2; // Average body angle
    
    // Check form conditions
    const isBackStraight = bodyAngle >= PUSHUP_CONSTANTS.BACK_STRAIGHT_THRESHOLD_ANGLE;
    const isArmsExtended = elbowAngle >= PUSHUP_CONSTANTS.THRESHOLD_ANGLE_UP;
    const isArmsBentDown = elbowAngle <= PUSHUP_CONSTANTS.THRESHOLD_ANGLE_DOWN;
    
    // Keep track of the previous state for transitions
    this.previousState = this.state;
    
    // Handle form fault (back not straight)
    if (!isBackStraight) {
      if (this.state !== 'start') {
        console.log("Form Error: Back not straight. Resetting state. Body Angle:", bodyAngle.toFixed(0));
        this.state = 'start';
        this.currentFormFault = "Keep body straight!";
        
        result.state = 'start';
        result.formFault = this.currentFormFault;
        result.hasFormFault = true;
        result.formScore = 80; // Deduct points for bad form
      }
      return result;
    }
    
    // State machine transitions
    switch (this.state) {
      case 'start':
        // Need to be extended first before starting the movement
        if (isArmsExtended) {
          this.state = 'up'; // Ready to go down
          console.log("State -> UP (Ready) (Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
          result.state = 'up';
        }
        break;
        
      case 'up': // Arms are extended, waiting for downward motion
        if (isArmsBentDown) {
          // Successfully reached the 'down' position with good form
          this.state = 'down';
          console.log("State -> DOWN (Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
          result.state = 'down';
        }
        break;
        
      case 'down': // Arms are bent, waiting for upward motion (extension)
        if (isArmsExtended) {
          // Successfully returned to 'up' position -> COUNT REP
          this.state = 'up';
          console.log("State -> UP (Rep Counted, Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
          result.state = 'up';
          result.repIncrement = 1; // Count the rep!
        }
        break;
    }
    
    // Update any form fault status from this frame into the result
    if (this.currentFormFault) {
      result.formFault = this.currentFormFault;
      result.hasFormFault = true;
      this.currentFormFault = null; // Clear it after reporting
    }
    
    return result;
  }
  
  /**
   * Reset the push-up grader to its initial state
   */
  reset(): void {
    super.reset();
    this.previousState = 'start';
    this.currentFormFault = null;
  }
}

export default PushupGrader; 