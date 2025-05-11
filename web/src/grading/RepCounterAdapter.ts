import { ExerciseType } from './index';
import { RepCounter, RepCountResult, RepMetrics, FormValidationFn, SetSummaryReport } from './RepCounter';
import { NormalizedLandmark } from '../lib/types';
import { PushupAnalyzer, PushupFormAnalysis } from './PushupAnalyzer';
import { PullupAnalyzer, PullupFormAnalysis } from './PullupAnalyzer';
import { SitupAnalyzer, SitupFormAnalysis } from './SitupAnalyzer';

/**
 * Interface for rep count analysis result
 * Combines form analysis with rep counting
 */
export interface RepCountAnalysis<T> {
  /**
   * The form analysis from the specific exercise analyzer
   */
  formAnalysis: T;
  
  /**
   * The rep counting result
   */
  repCount: RepCountResult;
  
  /**
   * Feedback message about the rep form
   */
  feedback?: {
    message: string;
    color: string; // 'green' for good, 'red' for bad, 'yellow' for warning
    isInvalidRep?: boolean; // Flag to indicate if this is feedback for an invalid rep
  };
}

/**
 * Detailed set summary results interface
 */
export interface SetSummaryAnalysis {
  /**
   * Basic set summary from the rep counter
   */
  summary: SetSummaryReport;
  
  /**
   * Formatted message for display
   */
  message: string;
  
  /**
   * Visual feedback style
   */
  style: 'success' | 'warning' | 'error';
  
  /**
   * Issues detected during the set
   */
  issues: {
    issue: string;
    count: number;
    percentage: number;
  }[];
}

/**
 * Factory function to create the appropriate adapter for an exercise type
 */
export function createRepCounterAdapter(exerciseType: ExerciseType): RepCounterAdapter<PushupFormAnalysis | PullupFormAnalysis | SitupFormAnalysis> {
  switch (exerciseType) {
    case ExerciseType.PUSHUP:
      return new PushupRepCounterAdapter();
    case ExerciseType.PULLUP:
      return new PullupRepCounterAdapter();
    case ExerciseType.SITUP:
      return new SitupRepCounterAdapter();
    default:
      throw new Error(`No RepCounterAdapter available for ${exerciseType}`);
  }
}

/**
 * Base interface for rep counter adapters
 */
export interface RepCounterAdapter<T> {
  /**
   * Process pose landmarks to analyze form and count reps
   */
  processFrame(landmarks: NormalizedLandmark[], timestamp: number): RepCountAnalysis<T>;
  
  /**
   * Reset the adapter state
   */
  reset(): void;
  
  /**
   * Get the current rep count
   */
  getTotalReps(): number;
  
  /**
   * Get the exercise type
   */
  getExerciseType(): ExerciseType;
  
  /**
   * Get metrics for the last completed rep
   */
  getLastRepMetrics(): RepMetrics;
  
  /**
   * Generate a summary report for the completed set
   */
  generateSetSummary(): SetSummaryAnalysis;
}

/**
 * Abstract base class for rep counter adapters
 */
abstract class BaseRepCounterAdapter<T> implements RepCounterAdapter<T> {
  protected repCounter: RepCounter;
  protected exerciseType: ExerciseType;
  protected lastFeedback?: { message: string; color: string; isInvalidRep?: boolean };
  
  constructor(exerciseType: ExerciseType) {
    this.exerciseType = exerciseType;
    this.repCounter = new RepCounter(exerciseType);
    
    // Set form validation function specific to this exercise
    this.repCounter.setFormValidationFn(this.createFormValidationFn());
  }
  
  abstract processFrame(landmarks: NormalizedLandmark[], timestamp: number): RepCountAnalysis<T>;
  
  /**
   * Create a form validation function for this specific exercise
   */
  protected abstract createFormValidationFn(): FormValidationFn;
  
  /**
   * Generate feedback based on rep count result
   */
  protected generateFeedback(repCount: RepCountResult): { message: string; color: string; isInvalidRep?: boolean } | undefined {
    if (repCount.newReps > 0) {
      // Valid rep was counted
      const formScore = repCount.lastRepFormScore;
      if (formScore !== undefined) {
        if (formScore >= 90) {
          return { message: "Perfect Rep!", color: "green" };
        } else if (formScore >= 70) {
          return { message: "Good Rep", color: "green" };
        } else {
          return { message: "Acceptable Rep", color: "yellow" };
        }
      }
      return { message: "Rep Counted", color: "green" };
    } else if (repCount.newInvalidRep) {
      // Invalid rep with reason
      return { 
        message: repCount.invalidRepReason || "Bad Rep - Not Counted", 
        color: "red",
        isInvalidRep: true 
      };
    } else if (repCount.invalidRepReason && !this.lastFeedback?.isInvalidRep) {
      // Show invalid rep feedback but don't overwrite existing invalid rep feedback
      return { 
        message: repCount.invalidRepReason, 
        color: "red",
        isInvalidRep: true 
      };
    }
    
    return undefined;
  }
  
  reset(): void {
    this.repCounter.reset();
    this.lastFeedback = undefined;
  }
  
  getTotalReps(): number {
    return this.repCounter.processState('DOWN', 0, Date.now()).totalReps;
  }
  
  getExerciseType(): ExerciseType {
    return this.exerciseType;
  }
  
  getLastRepMetrics(): RepMetrics {
    return this.repCounter.getLastRepMetrics();
  }
  
  /**
   * Generate a formatted summary of the completed set
   */
  generateSetSummary(): SetSummaryAnalysis {
    const summary = this.repCounter.generateSetSummary();
    
    // Determine overall style based on performance
    let style: 'success' | 'warning' | 'error';
    if (summary.validRepPercentage >= 90) {
      style = 'success';
    } else if (summary.validRepPercentage >= 70) {
      style = 'warning';
    } else {
      style = 'error';
    }
    
    // Format issues with percentages
    const issues = summary.formIssues.map(issue => ({
      issue: issue.reason,
      count: issue.count,
      percentage: (issue.count / Math.max(1, summary.totalInvalidReps)) * 100
    }));
    
    // Create a summary message
    const message = `Completed ${summary.totalValidReps} valid reps out of ${summary.totalAttemptedReps} attempts (${summary.validRepPercentage.toFixed(1)}%).\nAverage form score: ${summary.averageFormScore.toFixed(1)}/100`;
    
    return {
      summary,
      message,
      style,
      issues
    };
  }
}

/**
 * Adapter for pushup rep counting
 */
export class PushupRepCounterAdapter extends BaseRepCounterAdapter<PushupFormAnalysis> {
  private analyzer: PushupAnalyzer;
  
  constructor() {
    super(ExerciseType.PUSHUP);
    this.analyzer = new PushupAnalyzer();
  }
  
  processFrame(landmarks: NormalizedLandmark[], timestamp: number): RepCountAnalysis<PushupFormAnalysis> {
    // Analyze form
    const formAnalysis = this.analyzer.analyzePushupForm(landmarks, timestamp);
    
    // Extract metrics from form analysis
    const metrics: Partial<RepMetrics> = {
      minElbowAngle: Math.min(formAnalysis.leftElbowAngle, formAnalysis.rightElbowAngle),
      maxElbowAngle: Math.max(formAnalysis.leftElbowAngle, formAnalysis.rightElbowAngle),
      bodyAlignmentAngle: formAnalysis.bodyAlignmentAngle,
      // Add disqualifying movement flags
      handsLiftedOff: formAnalysis.handsLiftedOff,
      feetLiftedOff: formAnalysis.feetLiftedOff,
      kneesTouchingGround: formAnalysis.kneesTouchingGround,
      bodyTouchingGround: formAnalysis.bodyTouchingGround,
      isPaused: formAnalysis.isPaused,
      // Track max hip deviation for body alignment validation
      maxHipDeviation: Math.abs(180 - formAnalysis.bodyAlignmentAngle)
    };
    
    // Determine current state
    const currentState = formAnalysis.isUpPosition ? 'UP' : 
                         formAnalysis.isDownPosition ? 'DOWN' : 'TRANSITION';
    
    // Process through rep counter with form progress
    const repCount = this.repCounter.processState(
      currentState as 'UP' | 'DOWN',
      formAnalysis.isUpPosition ? 1 : formAnalysis.isDownPosition ? 0 : 0.5,
      timestamp,
      metrics
    );
    
    // Generate feedback if rep was counted or invalid
    const feedback = this.generateFeedback(repCount);
    if (feedback) {
      this.lastFeedback = feedback;
    }
    
    return {
      formAnalysis,
      repCount,
      feedback: this.lastFeedback
    };
  }
  
  protected createFormValidationFn(): FormValidationFn {
    return (metrics: RepMetrics) => {
      // Extract pushup-specific metrics
      const minElbowAngle = metrics.minElbowAngle || 180;
      const maxElbowAngle = metrics.maxElbowAngle || 0;
      const bodyAlignmentAngle = metrics.bodyAlignmentAngle as number;
      const maxHipDeviation = Math.abs(180 - (bodyAlignmentAngle || 180));
      
      // Define invalidation thresholds according to APFT standards
      const MIN_DEPTH_THRESHOLD = 100; // Elbow must bend to less than 100° (ideally 90°)
      const MIN_LOCKOUT_THRESHOLD = 160; // Elbows must extend to at least 160° at top
      const MAX_HIP_DEVIATION_THRESHOLD = 20; // Hip angle shouldn't deviate more than 20° from straight line
      
      // Check critical criteria for a valid rep
      const hasValidDepth = minElbowAngle <= MIN_DEPTH_THRESHOLD;
      const hasFullLockout = maxElbowAngle >= MIN_LOCKOUT_THRESHOLD;
      const hasGoodAlignment = maxHipDeviation <= MAX_HIP_DEVIATION_THRESHOLD;
      
      // Extract disqualifying movements if present in metrics
      const handsLeftGround = metrics.handsLiftedOff as boolean;
      const feetLeftGround = metrics.feetLiftedOff as boolean;
      const kneeOrChestTouchedGround = metrics.kneesTouchingGround as boolean || metrics.bodyTouchingGround as boolean;
      const pausedInWrongPosition = metrics.isPaused as boolean;
      const hadDisqualifyingMovement = handsLeftGround || feetLeftGround || kneeOrChestTouchedGround || pausedInWrongPosition;
      
      // Calculate form score (0-100)
      let formScore = 100;
      
      // Penalize for insufficient depth
      if (minElbowAngle > 90) {
        // Progressive penalty: 2 points per degree beyond 90°, capped at 50 points
        formScore -= Math.min(50, (minElbowAngle - 90) * 2);
      }
      
      // Penalize for incomplete lockout
      if (maxElbowAngle < MIN_LOCKOUT_THRESHOLD) {
        // Progressive penalty: 2 points per degree under 160°, capped at 30 points
        formScore -= Math.min(30, (MIN_LOCKOUT_THRESHOLD - maxElbowAngle) * 2);
      }
      
      // Penalize for poor body alignment
      if (maxHipDeviation > 10) {
        // Progressive penalty: 2 points per degree beyond 10°, capped at 30 points
        formScore -= Math.min(30, (maxHipDeviation - 10) * 2);
      }
      
      // Ensure score is in range 0-100
      formScore = Math.max(0, Math.min(100, formScore));
      
      // Determine if the rep is valid (all criteria must be met)
      const isValid = hasValidDepth && hasFullLockout && hasGoodAlignment && !hadDisqualifyingMovement;
      
      // Provide specific reason if invalid
      let reason;
      if (!hasValidDepth) {
        reason = "Insufficient depth - elbows must bend to 90°";
      } else if (!hasFullLockout) {
        reason = "Incomplete extension - arms must fully lock out at top";
      } else if (!hasGoodAlignment) {
        reason = "Poor body alignment - maintain straight line from shoulders to ankles";
      } else if (handsLeftGround) {
        reason = "Hands left the ground";
      } else if (feetLeftGround) {
        reason = "Feet left the ground";
      } else if (kneeOrChestTouchedGround) {
        reason = "Knees or chest touched the ground";
      } else if (pausedInWrongPosition) {
        reason = "Paused in incorrect position";
      }
      
      return {
        isValid,
        reason,
        formScore
      };
    };
  }
  
  override reset(): void {
    super.reset();
    this.analyzer.reset();
  }
}

/**
 * Adapter for pullup rep counting
 */
export class PullupRepCounterAdapter extends BaseRepCounterAdapter<PullupFormAnalysis> {
  private analyzer: PullupAnalyzer;
  
  constructor() {
    super(ExerciseType.PULLUP);
    this.analyzer = new PullupAnalyzer();
  }
  
  processFrame(landmarks: NormalizedLandmark[], timestamp: number): RepCountAnalysis<PullupFormAnalysis> {
    // Analyze form
    const formAnalysis = this.analyzer.analyzePullupForm(landmarks, timestamp);
    
    // Calculate additional metrics for comprehensive form validation
    // Get nose position for chin clearing bar validation
    const noseY = landmarks[0]?.y || 0; // NOSE is at index 0
    const mouthY = (landmarks[9]?.y || 0 + landmarks[10]?.y || 0) / 2; // Average of MOUTH_LEFT and MOUTH_RIGHT
    
    // Get elbow angles for dead hang validation
    const minElbowAngle = Math.min(formAnalysis.leftElbowAngle, formAnalysis.rightElbowAngle);
    const maxElbowAngle = Math.max(formAnalysis.leftElbowAngle, formAnalysis.rightElbowAngle);
    
    // Get hip position for horizontal displacement and stability tracking
    const hipX = (landmarks[23]?.x || 0 + landmarks[24]?.x || 0) / 2; // Average of LEFT_HIP and RIGHT_HIP
    const shoulderWidth = Math.abs(landmarks[11]?.x || 0 - landmarks[12]?.x || 0); // Distance between shoulders as reference
    
    // Calculate normalized horizontal displacement relative to body width
    const normalizedHorizontalDisplacement = formAnalysis.maxHorizontalDisplacement / shoulderWidth;
    
    // Get chin-to-bar proximity for detecting bar contact/assistance
    const chinY = Math.min(noseY, mouthY); // Lower of nose or mouth Y position
    const barY = formAnalysis.barY || 0;
    const chinBarProximity = Math.abs(chinY - barY);
    
    // Extract metrics from form analysis
    const metrics: Partial<RepMetrics> = {
      minElbowAngle,
      maxElbowAngle,
      maxHorizontalDisplacement: formAnalysis.maxHorizontalDisplacement,
      normalizedHorizontalDisplacement,
      maxKneeAngleChange: formAnalysis.maxKneeAngleChange,
      chinClearsBar: formAnalysis.chinClearsBar,
      // Additional metrics for detailed validation
      noseY,
      mouthY,
      barHeight: formAnalysis.barY || 0,
      chinY,
      chinBarProximity,
      isKipping: formAnalysis.maxKneeAngleChange > 20,
      isSwinging: normalizedHorizontalDisplacement > 0.1,
      hipX,
      shoulderWidth
    };
    
    // Determine current state
    const currentState = formAnalysis.isUpPosition ? 'UP' : 
                         formAnalysis.isDownPosition ? 'DOWN' : 'TRANSITION';
    
    // Process through rep counter with form progress
    const repCount = this.repCounter.processState(
      currentState as 'UP' | 'DOWN',
      formAnalysis.repProgress,
      timestamp,
      metrics
    );
    
    // Generate feedback if rep was counted or invalid
    const feedback = this.generateFeedback(repCount);
    if (feedback) {
      this.lastFeedback = feedback;
    }
    
    return {
      formAnalysis,
      repCount,
      feedback: this.lastFeedback
    };
  }
  
  protected createFormValidationFn(): FormValidationFn {
    return (metrics: RepMetrics) => {
      // Extract pullup-specific metrics
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const minElbowAngle = metrics.minElbowAngle || 180;
      const maxElbowAngle = metrics.maxElbowAngle || 0;
      const normalizedHorizontalDisplacement = metrics.normalizedHorizontalDisplacement || 0;
      const maxKneeAngleChange = metrics.maxKneeAngleChange || 0;
      const chinY = metrics.chinY || 0;
      const barHeight = metrics.barHeight || 0;
      const chinBarProximity = metrics.chinBarProximity || 0;

      // Define thresholds based on APFT standards
      const MIN_DEAD_HANG_ANGLE = 160; // Minimum elbow angle for dead hang
      const MAX_HORIZONTAL_SWING = 0.07; // 7% of body width as max allowable swing
      const MAX_KNEE_ANGLE_CHANGE = 20; // Maximum knee angle change before considered kipping
      const MIN_CHIN_BAR_PROXIMITY = 0.01; // Chin-bar proximity that suggests contact/assistance

      // Validate form criteria

      // 4C.1. Chin Must Clear Bar
      // Check if chin (nose or mouth) clears the bar
      const chinClearsBarHeight = chinY < barHeight;

      // 4C.2. Must Return to Dead Hang
      // Check if elbows fully extend at bottom
      const returnsToDeadHang = maxElbowAngle >= MIN_DEAD_HANG_ANGLE;

      // 4C.3. No Kipping, Swinging, or Bouncing
      // Check for excessive horizontal movement or knee angle changes
      const noExcessiveSwinging = normalizedHorizontalDisplacement <= MAX_HORIZONTAL_SWING;
      const noKipping = maxKneeAngleChange <= MAX_KNEE_ANGLE_CHANGE;

      // 4C.4. Bar Contact or Assistance (Optional)
      // Check if chin is suspiciously close to bar, suggesting contact/assistance
      const noBarAssistance = chinBarProximity > MIN_CHIN_BAR_PROXIMITY;

      // Calculate form score (0-100)
      let formScore = 100;

      // Penalize for insufficient chin height
      if (!chinClearsBarHeight) {
        formScore -= 40; // Severe penalty for not clearing the bar
      }

      // Penalize for incomplete dead hang
      if (!returnsToDeadHang) {
        // Penalty proportional to how far from proper extension
        formScore -= Math.min(30, (MIN_DEAD_HANG_ANGLE - maxElbowAngle) * 1.5);
      }

      // Penalize for excessive swinging
      if (!noExcessiveSwinging) {
        // Penalty proportional to excessive swing
        const excessSwing = normalizedHorizontalDisplacement - MAX_HORIZONTAL_SWING;
        formScore -= Math.min(30, excessSwing * 300); // Scale penalty for visibility
      }

      // Penalize for kipping
      if (!noKipping) {
        // Penalty proportional to excessive knee movement
        const excessKneeMovement = maxKneeAngleChange - MAX_KNEE_ANGLE_CHANGE;
        formScore -= Math.min(30, excessKneeMovement * 2);
      }

      // Penalize for bar assistance
      if (!noBarAssistance) {
        formScore -= 20; // Penalty for apparent bar contact
      }

      // Ensure score is in range 0-100
      formScore = Math.max(0, Math.min(100, formScore));

      // Determine if the rep is valid (all critical criteria must be met)
      const isValid = chinClearsBarHeight && returnsToDeadHang && noExcessiveSwinging && noKipping;

      // Provide specific reason if invalid
      let reason;
      if (!chinClearsBarHeight) {
        reason = "Chin must clear the bar";
      } else if (!returnsToDeadHang) {
        reason = "Must return to full extension at bottom position";
      } else if (!noExcessiveSwinging) {
        reason = "Excessive swinging detected - maintain body control";
      } else if (!noKipping) {
        reason = "Kipping/hip drive detected - keep legs still";
      } else if (!noBarAssistance && !isValid) {
        reason = "Bar contact/assistance detected";
      }

      return {
        isValid,
        reason,
        formScore
      };
    };
  }
  
  override reset(): void {
    super.reset();
    this.analyzer.reset();
  }
}

/**
 * Adapter for situp rep counting
 */
export class SitupRepCounterAdapter extends BaseRepCounterAdapter<SitupFormAnalysis> {
  private analyzer: SitupAnalyzer;
  
  constructor() {
    super(ExerciseType.SITUP);
    this.analyzer = new SitupAnalyzer();
  }
  
  processFrame(landmarks: NormalizedLandmark[], timestamp: number): RepCountAnalysis<SitupFormAnalysis> {
    // Analyze form
    const formAnalysis = this.analyzer.analyzeSitupForm(landmarks, timestamp);
    
    // Calculate additional metrics from landmarks for rep validation
    const midHipY = formAnalysis.initialHipY || 0;
    const midShoulderY = formAnalysis.initialShoulderY || 0;
    
    // Get nose and hip positions for up position validation
    const noseY = landmarks[0]?.y || 0; // NOSE is at index 0
    const hipY = (landmarks[23]?.y || 0 + landmarks[24]?.y || 0) / 2; // Average LEFT_HIP and RIGHT_HIP
    
    // Calculate wrist distance for hand position validation
    const leftWristY = landmarks[15]?.y || 0; // LEFT_WRIST
    const rightWristY = landmarks[16]?.y || 0; // RIGHT_WRIST
    const leftWristX = landmarks[15]?.x || 0;
    const rightWristX = landmarks[16]?.x || 0;
    const wristDistance = Math.sqrt(
      Math.pow(leftWristX - rightWristX, 2) + 
      Math.pow(leftWristY - rightWristY, 2)
    );
    
    // Extract metrics from form analysis
    const metrics: Partial<RepMetrics> = {
      maxTrunkAngle: formAnalysis.trunkAngle,
      isHandPositionCorrect: formAnalysis.isHandPositionCorrect,
      isShoulderBladeGrounded: formAnalysis.isShoulderBladeGrounded,
      isHipStable: formAnalysis.isHipStable,
      isKneeAngleCorrect: formAnalysis.isKneeAngleCorrect,
      
      // Additional metrics for detailed validation
      noseY,
      hipY,
      shoulderDiffFromGround: Math.abs(midShoulderY - formAnalysis.initialShoulderY),
      hipLift: Math.abs(midHipY - formAnalysis.initialHipY),
      wristDistance,
      isPaused: formAnalysis.isPaused
    };
    
    // Determine current state
    const currentState = formAnalysis.isUpPosition ? 'UP' : 
                         formAnalysis.isDownPosition ? 'DOWN' : 'TRANSITION';
    
    // Process through rep counter with form progress
    const repCount = this.repCounter.processState(
      currentState as 'UP' | 'DOWN',
      formAnalysis.repProgress,
      timestamp,
      metrics
    );
    
    // Generate feedback if rep was counted or invalid
    const feedback = this.generateFeedback(repCount);
    if (feedback) {
      this.lastFeedback = feedback;
    }
    
    return {
      formAnalysis,
      repCount,
      feedback: this.lastFeedback
    };
  }
  
  protected createFormValidationFn(): FormValidationFn {
    return (metrics: RepMetrics) => {
      // Extract situp-specific metrics
      const maxTrunkAngle = metrics.maxTrunkAngle || 0;
      const isHandPositionCorrect = metrics.isHandPositionCorrect as boolean;
      // Remove or prefix unused variables with underscore
      // const _isShoulderBladeGrounded = metrics.isShoulderBladeGrounded as boolean;
      const isHipStable = metrics.isHipStable as boolean;
      // const _isKneeAngleCorrect = metrics.isKneeAngleCorrect as boolean;
      const noseY = metrics.noseY || 0;
      const hipY = metrics.hipY || 0;
      const shoulderDiffFromGround = metrics.shoulderDiffFromGround || 0;
      const hipLift = metrics.hipLift || 0;
      const wristDistance = metrics.wristDistance || 0;
      const isPaused = metrics.isPaused as boolean;

      // Define validation thresholds
      const MAX_SHOULDER_GROUND_DIFF = 0.03; // Maximum shoulder distance from ground
      const MAX_HIP_LIFT = 0.03; // Maximum hip lift from ground
      const MAX_WRIST_DISTANCE = 0.1; // Maximum distance between wrists
      const MIN_HIP_ANGLE_UP = 90; // Minimum hip angle at up position

      // Validate specific criteria based on APFT standards

      // 4B.1. Must Reach "Vertical" Up Position
      // Check if neck/shoulders rose above hips or hip angle < 90°
      const reachedVerticalPosition = noseY < hipY || maxTrunkAngle < MIN_HIP_ANGLE_UP;

      // 4B.2. Must Lower Fully
      // Check if shoulders returned to ground level
      const loweredFully = shoulderDiffFromGround < MAX_SHOULDER_GROUND_DIFF;

      // 4B.3. Hands Must Stay Interlocked Behind Head
      // Check if hands stayed together behind head
      const handsStayedInterlocked = isHandPositionCorrect && wristDistance < MAX_WRIST_DISTANCE;

      // 4B.4. Butt Must Remain on Ground
      // Check if hips remained on ground
      const buttStayedOnGround = hipLift < MAX_HIP_LIFT && isHipStable;

      // Calculate form score (0-100)
      let formScore = 100;

      // Penalize for not reaching vertical up position
      if (!reachedVerticalPosition) {
        formScore -= 30;
      }

      // Penalize for not lowering fully
      if (!loweredFully) {
        formScore -= 25;
      }

      // Penalize for incorrect hand position
      if (!handsStayedInterlocked) {
        formScore -= 25;
      }

      // Penalize for hips lifting off ground
      if (!buttStayedOnGround) {
        formScore -= 20;
      }

      // Penalize for pausing during the rep
      if (isPaused) {
        formScore -= 15;
      }

      // Ensure score is in range 0-100
      formScore = Math.max(0, Math.min(100, formScore));

      // Determine if the rep is valid (all critical criteria must be met)
      const isValid = reachedVerticalPosition && loweredFully && 
                     handsStayedInterlocked && buttStayedOnGround && !isPaused;

      // Provide specific reason if invalid
      let reason;
      if (!reachedVerticalPosition) {
        reason = "Didn't reach vertical position - sit up more completely";
      } else if (!loweredFully) {
        reason = "Shoulder blades must touch ground at bottom position";
      } else if (!handsStayedInterlocked) {
        reason = "Hands must stay interlocked behind head";
      } else if (!buttStayedOnGround) {
        reason = "Hips must remain on ground throughout rep";
      } else if (isPaused) {
        reason = "No pausing during the rep";
      }

      return {
        isValid,
        reason,
        formScore
      };
    };
  }
  
  override reset(): void {
    super.reset();
    this.analyzer.reset();
  }
} 