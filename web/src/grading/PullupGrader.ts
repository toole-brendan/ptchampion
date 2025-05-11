/**
 * PullupGrader.ts
 * 
 * Implements pull-up specific grading logic.
 * This encapsulates the state machine and form evaluation criteria for pull-ups.
 */

import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { BaseExerciseGrader, GradingResult } from './ExerciseGrader';
import { PoseLandmarkIndex } from '../services/PoseLandmarkIndex';

/**
 * Constants for pull-up form evaluation
 */
export const PULLUP_CONSTANTS = {
  // Angle for fully extended arms at bottom
  THRESHOLD_ELBOW_ANGLE_DOWN: 160,
  
  // Threshold for chin (nose landmark) being above wrists
  // Positive value means nose needs to be *higher* than wrists (smaller y-coordinate)
  CHIN_OVER_BAR_VERTICAL_THRESHOLD: 0.05,
  
  // Threshold to detect excessive kipping (vertical hip movement relative to shoulders)
  KIPPING_VERTICAL_THRESHOLD: 0.15,
  
  // Visibility threshold for landmarks
  VISIBILITY_THRESHOLD: 0.6
};

/**
 * Required landmarks for pull-up tracking
 */
const REQUIRED_PULLUP_LANDMARKS = [
  PoseLandmarkIndex.NOSE,
  PoseLandmarkIndex.LEFT_SHOULDER,
  PoseLandmarkIndex.RIGHT_SHOULDER,
  PoseLandmarkIndex.LEFT_ELBOW,
  PoseLandmarkIndex.RIGHT_ELBOW,
  PoseLandmarkIndex.LEFT_WRIST,
  PoseLandmarkIndex.RIGHT_WRIST,
  PoseLandmarkIndex.LEFT_HIP,
  PoseLandmarkIndex.RIGHT_HIP
];

/**
 * Pull-up grader that implements the exercise state machine and form evaluation
 */
export class PullupGrader extends BaseExerciseGrader {
  // Track form faults during the current rep
  private currentFormFault: string | null = null;
  
  // Store initial positions for checking kipping
  private initialHipY: number | null = null;
  private initialShoulderY: number | null = null;
  
  constructor() {
    super('PULLUP');
  }
  
  /**
   * Process a new frame of pose landmarks and update the pull-up state
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
    if (!this.areLandmarksVisible(landmarks, REQUIRED_PULLUP_LANDMARKS, PULLUP_CONSTANTS.VISIBILITY_THRESHOLD)) {
      // Not enough landmarks visible for reliable tracking
      if (this.state !== 'start') {
        // Only reset state and show message if we were in the middle of tracking
        this.state = 'start';
        this.currentFormFault = null;
        this.initialHipY = null;
        this.initialShoulderY = null;
        
        result.state = 'start';
        result.formFault = "Ensure full body is visible";
        result.hasFormFault = true;
      }
      return result;
    }
    
    // Extract relevant landmarks
    const nose = landmarks[PoseLandmarkIndex.NOSE];
    const leftShoulder = landmarks[PoseLandmarkIndex.LEFT_SHOULDER];
    const rightShoulder = landmarks[PoseLandmarkIndex.RIGHT_SHOULDER];
    const leftElbow = landmarks[PoseLandmarkIndex.LEFT_ELBOW];
    const rightElbow = landmarks[PoseLandmarkIndex.RIGHT_ELBOW];
    const leftWrist = landmarks[PoseLandmarkIndex.LEFT_WRIST];
    const rightWrist = landmarks[PoseLandmarkIndex.RIGHT_WRIST];
    const leftHip = landmarks[PoseLandmarkIndex.LEFT_HIP];
    const rightHip = landmarks[PoseLandmarkIndex.RIGHT_HIP];
    
    // Calculate angles and positions
    const leftElbowAngle = this.calculateAngle(leftShoulder, leftElbow, leftWrist);
    const rightElbowAngle = this.calculateAngle(rightShoulder, rightElbow, rightWrist);
    const elbowAngle = (leftElbowAngle + rightElbowAngle) / 2; // Average elbow angle
    
    // Calculate vertical positions (y-coordinate, smaller is higher on screen)
    const noseY = nose.y;
    const avgWristY = (leftWrist.y + rightWrist.y) / 2;
    const avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    const avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Conditions for state transitions
    const isArmsExtended = elbowAngle >= PULLUP_CONSTANTS.THRESHOLD_ELBOW_ANGLE_DOWN;
    // Check if nose is significantly higher than wrists
    const isChinOverBar = noseY < avgWristY - PULLUP_CONSTANTS.CHIN_OVER_BAR_VERTICAL_THRESHOLD;
    
    // State machine transitions
    let kippingFaultDetected = false;
    
    switch (this.state) {
      case 'start':
        // Waiting to reach the bottom hang position (arms extended)
        if (isArmsExtended) {
          this.state = 'down';
          this.currentFormFault = null; // Reset fault flag for the new rep attempt
          
          // Record initial positions for kipping check
          this.initialHipY = avgHipY;
          this.initialShoulderY = avgShoulderY;
          
          console.log("State -> DOWN (Arms Extended)");
          result.state = 'down';
        }
        break;
        
      case 'down':
        // At the bottom, waiting for upward movement AND chin over bar
        if (isChinOverBar) {
          // Check for excessive kipping during the upward movement
          if (this.initialHipY !== null && this.initialShoulderY !== null) {
            const currentRelativeHipY = avgHipY - avgShoulderY;
            const initialRelativeHipY = this.initialHipY - this.initialShoulderY;
            const verticalHipDisplacement = initialRelativeHipY - currentRelativeHipY;
            
            if (verticalHipDisplacement > PULLUP_CONSTANTS.KIPPING_VERTICAL_THRESHOLD) {
              this.currentFormFault = "Excessive Kipping Detected!";
              kippingFaultDetected = true;
              console.warn(`Form Fault: ${this.currentFormFault} Displacement: ${verticalHipDisplacement.toFixed(3)}`);
              result.hasFormFault = true;
              result.formScore = 70; // Deduct more points for kipping
            }
          }
          
          // Transition to 'up' regardless of kipping for state flow, fault flag handles counting
          this.state = 'up';
          console.log(`State -> UP (Chin Over Bar: ${isChinOverBar}, Kipping Fault: ${kippingFaultDetected})`);
          result.state = 'up';
          
          if (this.currentFormFault) {
            result.formFault = this.currentFormFault;
          }
        }
        break;
        
      case 'up':
        // At the top, waiting for downward movement (arms extending)
        if (isArmsExtended) {
          // Successfully returned to bottom hang position
          if (!result.hasFormFault && !kippingFaultDetected) {
            // Only count if no form fault was detected during the rep
            result.repIncrement = 1; // Count the rep!
            console.log("State -> DOWN (Rep Counted)");
          } else {
            console.log("State -> DOWN (Rep Not Counted due to Form Fault)");
            // Give feedback that the previous rep was invalid
            if (!this.currentFormFault) {
              this.currentFormFault = "Invalid Rep - Check Form";
            }
            result.formFault = this.currentFormFault;
          }
          
          this.state = 'down'; // Go back to down state, ready for next rep
          result.state = 'down';
          this.currentFormFault = null; // Reset fault flag for the NEW rep cycle
          
          // Record new initial positions
          this.initialHipY = avgHipY;
          this.initialShoulderY = avgShoulderY;
        }
        break;
    }
    
    // Update any form fault status from this frame into the result
    if (this.currentFormFault && !result.formFault) {
      result.formFault = this.currentFormFault;
      result.hasFormFault = true;
    }
    
    return result;
  }
  
  /**
   * Reset the pull-up grader to its initial state
   */
  reset(): void {
    super.reset();
    this.currentFormFault = null;
    this.initialHipY = null;
    this.initialShoulderY = null;
  }
}

export default PullupGrader; 