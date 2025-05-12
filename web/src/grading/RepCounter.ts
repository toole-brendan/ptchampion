import { ExerciseType } from './ExerciseType';

/**
 * Definition of possible exercise states
 */
export type RepState = 'UP' | 'DOWN' | 'TRANSITION' | 'UNKNOWN';

/**
 * Enum for tracking direction of movement
 */
export enum RepDirection {
  UP_TO_DOWN = 'UP_TO_DOWN',
  DOWN_TO_UP = 'DOWN_TO_UP',
  NONE = 'NONE'
}

/**
 * Configuration interface for RepCounter
 */
export interface RepCounterConfig {
  /**
   * Minimum number of consecutive frames to confirm a state change
   * Used to stabilize detection and prevent oscillation
   */
  stateStabilityThreshold: number;
  
  /**
   * Counting direction for each exercise type
   * Determines which transition triggers a rep count
   */
  countingDirections: {
    [key in ExerciseType]?: RepDirection;
  };
  
  /**
   * Minimum time (ms) between valid rep counts
   * Prevents double-counting due to small fluctuations
   */
  minRepDurationMs: number;
}

/**
 * Interface for rep counting result
 */
export interface RepCountResult {
  /**
   * Current state of the exercise
   */
  currentState: RepState;
  
  /**
   * Previous stable state of the exercise
   */
  previousState: RepState;
  
  /**
   * Number of new completed reps (0 or 1 typically)
   */
  newReps: number;
  
  /**
   * Total cumulative reps counted
   */
  totalReps: number;
  
  /**
   * Progress of the current rep (0-1)
   * 0 = starting position, 1 = end position
   */
  repProgress: number;
  
  /**
   * Direction of the current movement
   */
  direction: RepDirection;
  
  /**
   * Timestamp when the last rep was counted
   */
  lastRepTimestamp: number;
  
  /**
   * Whether a rep is currently in progress
   */
  repInProgress: boolean;
  
  /**
   * Reason why the last attempted rep was invalid, if applicable
   */
  invalidRepReason?: string;
  
  /**
   * Form score for the last completed rep (0-100)
   */
  lastRepFormScore?: number;
  
  /**
   * Whether a new invalid rep was detected in this update
   */
  newInvalidRep?: boolean;
  
  /**
   * Count of invalid reps
   */
  invalidReps?: number;
}

/**
 * Interface for set summary report
 */
export interface SetSummaryReport {
  /**
   * Total valid reps counted
   */
  totalValidReps: number;
  
  /**
   * Total invalid reps attempted
   */
  totalInvalidReps: number;
  
  /**
   * Percentage of reps that were valid
   */
  validRepPercentage: number;
  
  /**
   * Average form score across all valid reps
   */
  averageFormScore: number;
  
  /**
   * List of form issues detected during the set
   */
  formIssues: {
    reason: string;
    count: number;
  }[];
  
  /**
   * Form scores for each valid rep
   */
  repScores: number[];
  
  /**
   * Total attempted reps (valid + invalid)
   */
  totalAttemptedReps: number;
  
  /**
   * Duration of the set in milliseconds
   */
  setDurationMs: number;
  
  /**
   * Start timestamp of the set
   */
  startTimestamp: number;
  
  /**
   * End timestamp of the set
   */
  endTimestamp: number;
}

/**
 * Interface for collected metrics during a rep
 */
export interface RepMetrics {
  // General metrics
  startTimestamp: number;
  endTimestamp: number;
  duration: number;
  
  // Exercise-specific metrics
  minElbowAngle?: number;
  maxElbowAngle?: number;
  minTrunkAngle?: number;
  maxTrunkAngle?: number;
  maxChinHeight?: number;
  maxHorizontalDisplacement?: number;
  maxKneeAngleChange?: number;
  
  // Disqualifying movement flags
  handsLiftedOff?: boolean;
  feetLiftedOff?: boolean;
  kneesTouchingGround?: boolean;
  bodyTouchingGround?: boolean;
  isPaused?: boolean;
  
  // Body alignment metrics
  maxHipDeviation?: number;
  
  // Sit-up specific metrics
  noseY?: number;
  hipY?: number;
  shoulderDiffFromGround?: number;
  hipLift?: number;
  wristDistance?: number;
  isHandPositionCorrect?: boolean;
  isShoulderBladeGrounded?: boolean;
  isHipStable?: boolean;
  isKneeAngleCorrect?: boolean;
  
  // Pull-up specific metrics
  chinClearsBar?: boolean;
  normalizedHorizontalDisplacement?: number;
  isKipping?: boolean;
  isSwinging?: boolean;
  chinY?: number;
  mouthY?: number;
  barHeight?: number;
  chinBarProximity?: number;
  hipX?: number;
  shoulderWidth?: number;
  
  // Additional metrics can be added as needed
  [key: string]: unknown;
}

/**
 * Type for form validation function
 */
export type FormValidationFn = (metrics: RepMetrics) => {
  isValid: boolean;
  reason?: string;
  formScore?: number;
};

/**
 * Default configuration values
 */
const DEFAULT_CONFIG: RepCounterConfig = {
  stateStabilityThreshold: 3,
  countingDirections: {
    [ExerciseType.PUSHUP]: RepDirection.DOWN_TO_UP,
    [ExerciseType.PULLUP]: RepDirection.UP_TO_DOWN,
    [ExerciseType.SITUP]: RepDirection.UP_TO_DOWN
  },
  minRepDurationMs: 500
};

/**
 * Class to handle real-time rep counting using a state machine approach
 */
export class RepCounter {
  private config: RepCounterConfig;
  private exerciseType: ExerciseType;
  private countingDirection: RepDirection;
  
  // State tracking
  private currentState: RepState = 'UNKNOWN';
  private previousState: RepState = 'UNKNOWN';
  private stateBuffer: RepState[] = [];
  private totalReps: number = 0;
  private invalidReps: number = 0;
  private lastRepTimestamp: number = 0;
  private repProgress: number = 0;
  
  // Rep tracking flags and metrics
  private repInProgress: boolean = false;
  private currentRepMetrics: RepMetrics = this.createEmptyMetrics();
  private lastRepMetrics: RepMetrics = this.createEmptyMetrics();
  private invalidRepReason?: string;
  private lastRepFormScore?: number;
  
  // Set statistics tracking
  private setStartTimestamp: number = 0;
  private repScores: number[] = [];
  private formIssueReasons: Map<string, number> = new Map();
  private newInvalidRep: boolean = false;
  
  // Form validation function
  private formValidationFn?: FormValidationFn;
  
  /**
   * Create a new RepCounter for a specific exercise type
   * @param exerciseType The type of exercise to count
   * @param config Optional configuration overrides
   * @param formValidationFn Optional function to validate rep form
   */
  constructor(
    exerciseType: ExerciseType, 
    config?: Partial<RepCounterConfig>,
    formValidationFn?: FormValidationFn
  ) {
    this.exerciseType = exerciseType;
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.formValidationFn = formValidationFn;
    
    // Set the counting direction for this exercise
    this.countingDirection = this.config.countingDirections[exerciseType] || RepDirection.NONE;
    
    if (this.countingDirection === RepDirection.NONE) {
      console.warn(`No counting direction specified for ${exerciseType}`);
    }
    
    // Initialize set start timestamp
    this.setStartTimestamp = Date.now();
  }
  
  /**
   * Reset the counter to its initial state
   */
  reset(): void {
    this.currentState = 'UNKNOWN';
    this.previousState = 'UNKNOWN';
    this.stateBuffer = [];
    this.totalReps = 0;
    this.invalidReps = 0;
    this.lastRepTimestamp = 0;
    this.repProgress = 0;
    this.repInProgress = false;
    this.currentRepMetrics = this.createEmptyMetrics();
    this.lastRepMetrics = this.createEmptyMetrics();
    this.invalidRepReason = undefined;
    this.lastRepFormScore = undefined;
    
    // Reset set statistics
    this.setStartTimestamp = Date.now();
    this.repScores = [];
    this.formIssueReasons = new Map();
    this.newInvalidRep = false;
  }
  
  /**
   * Set form validation function
   * @param validationFn Function to validate rep form
   */
  setFormValidationFn(validationFn: FormValidationFn): void {
    this.formValidationFn = validationFn;
  }
  
  /**
   * Process the current frame's state and determine if a rep has occurred
   * @param state The current frame's raw state (UP or DOWN)
   * @param progress Optional progress value (0-1) for the current rep
   * @param timestamp Current timestamp in milliseconds
   * @param metrics Optional metrics to track for this frame
   * @returns Result of rep counting, including new reps and total reps
   */
  processState(
    state: 'UP' | 'DOWN', 
    progress: number = 0, 
    timestamp: number,
    metrics?: Partial<RepMetrics>
  ): RepCountResult {
    // Add current raw state to the buffer
    this.stateBuffer.push(state);
    
    // Keep buffer at configured size
    if (this.stateBuffer.length > this.config.stateStabilityThreshold) {
      this.stateBuffer.shift();
    }
    
    // Store current rep progress
    this.repProgress = progress;
    
    // Update metrics for current rep if in progress
    if (this.repInProgress && metrics) {
      this.updateRepMetrics(metrics);
    }
    
    // Check if the buffer shows a stable state
    const stableState = this.getStableState();
    
    // Detect start of downward/upward motion based on exercise type
    if (!this.repInProgress && stableState !== 'UNKNOWN') {
      if ((this.countingDirection === RepDirection.DOWN_TO_UP && state === 'DOWN') || 
          (this.countingDirection === RepDirection.UP_TO_DOWN && state === 'UP')) {
        // Starting a new rep
        this.repInProgress = true;
        this.currentRepMetrics = this.createEmptyMetrics();
        this.currentRepMetrics.startTimestamp = timestamp;
        
        // Initialize with current metrics if provided
        if (metrics) {
          this.updateRepMetrics(metrics);
        }
      }
    }
    
    // If we have a stable state different from the current one, we have a state change
    if (stableState !== 'UNKNOWN' && stableState !== this.currentState) {
      // Store previous state before updating
      this.previousState = this.currentState;
      this.currentState = stableState;
      
      // Check if this transition counts as a rep
      let newReps = 0;
      this.invalidRepReason = undefined;
      
      const timeSinceLastRep = timestamp - this.lastRepTimestamp;
      const minTimeMet = timeSinceLastRep > this.config.minRepDurationMs;
      
      // Check if transition matches the counting direction for the exercise
      if (minTimeMet && this.repInProgress) {
        if ((this.countingDirection === RepDirection.DOWN_TO_UP && 
            this.previousState === 'DOWN' && this.currentState === 'UP') || 
            (this.countingDirection === RepDirection.UP_TO_DOWN && 
            this.previousState === 'UP' && this.currentState === 'DOWN')) {
          
          // Complete the rep metrics
          this.currentRepMetrics.endTimestamp = timestamp;
          this.currentRepMetrics.duration = timestamp - this.currentRepMetrics.startTimestamp;
          
          // Validate the rep if a validation function is provided
          if (this.formValidationFn) {
            const validation = this.formValidationFn(this.currentRepMetrics);
            if (validation.isValid) {
              newReps = 1;
              this.lastRepFormScore = validation.formScore;
              
              // Store the form score for the valid rep
              if (validation.formScore !== undefined) {
                this.repScores.push(validation.formScore);
              }
            } else {
              this.invalidRepReason = validation.reason || 'Invalid form';
              this.invalidReps++;
              this.newInvalidRep = true;
              
              // Track the reason for invalid rep
              if (validation.reason) {
                const count = this.formIssueReasons.get(validation.reason) || 0;
                this.formIssueReasons.set(validation.reason, count + 1);
              }
            }
          } else {
            // No validation function, count the rep
            newReps = 1;
          }
          
          // Store timestamp and metrics for the last rep
          if (newReps > 0) {
            this.lastRepTimestamp = timestamp;
            this.lastRepMetrics = { ...this.currentRepMetrics };
          }
          
          // Reset rep tracking
          this.repInProgress = false;
          this.currentRepMetrics = this.createEmptyMetrics();
        }
      }
      
      // Update total rep count
      this.totalReps += newReps;
      
      // Reset the newInvalidRep flag after reporting it
      const tempNewInvalidRep = this.newInvalidRep;
      this.newInvalidRep = false;
      
      return {
        currentState: this.currentState,
        previousState: this.previousState,
        newReps,
        totalReps: this.totalReps,
        repProgress: this.repProgress,
        direction: this.getDirection(),
        lastRepTimestamp: this.lastRepTimestamp,
        repInProgress: this.repInProgress,
        invalidRepReason: this.invalidRepReason,
        lastRepFormScore: this.lastRepFormScore,
        newInvalidRep: tempNewInvalidRep,
        invalidReps: this.invalidReps
      };
    }
    
    // No state change
    return {
      currentState: this.currentState,
      previousState: this.previousState,
      newReps: 0,
      totalReps: this.totalReps,
      repProgress: this.repProgress,
      direction: this.getDirection(),
      lastRepTimestamp: this.lastRepTimestamp,
      repInProgress: this.repInProgress,
      invalidRepReason: this.invalidRepReason,
      lastRepFormScore: this.lastRepFormScore,
      newInvalidRep: this.newInvalidRep,
      invalidReps: this.invalidReps
    };
  }
  
  /**
   * Update metrics for the current rep
   * @param metrics New metrics to consider
   */
  private updateRepMetrics(metrics: Partial<RepMetrics>): void {
    // Update all provided metrics
    Object.keys(metrics).forEach(key => {
      const metricValue = metrics[key as keyof RepMetrics];
      
      if (metricValue !== undefined) {
        // For min values, store the minimum encountered
        if (key.startsWith('min') && this.currentRepMetrics[key] !== undefined) {
          this.currentRepMetrics[key] = Math.min(
            this.currentRepMetrics[key] as number,
            metricValue as number
          );
        }
        // For max values, store the maximum encountered
        else if (key.startsWith('max') && this.currentRepMetrics[key] !== undefined) {
          this.currentRepMetrics[key] = Math.max(
            this.currentRepMetrics[key] as number,
            metricValue as number
          );
        }
        // For boolean flags, set to true if any frame had true
        else if (typeof metricValue === 'boolean') {
          this.currentRepMetrics[key] = (this.currentRepMetrics[key] as boolean) || metricValue;
        }
        // For other values, just update
        else {
          this.currentRepMetrics[key] = metricValue;
        }
      }
    });
  }
  
  /**
   * Create empty metrics object with default values
   */
  private createEmptyMetrics(): RepMetrics {
    return {
      startTimestamp: 0,
      endTimestamp: 0,
      duration: 0,
      minElbowAngle: 180,
      maxElbowAngle: 0,
      minTrunkAngle: 180,
      maxTrunkAngle: 0,
      maxChinHeight: 0,
      maxHorizontalDisplacement: 0,
      maxKneeAngleChange: 0,
      // Initialize disqualifying movement flags
      handsLiftedOff: false,
      feetLiftedOff: false,
      kneesTouchingGround: false,
      bodyTouchingGround: false,
      isPaused: false,
      // Initialize body alignment metrics
      maxHipDeviation: 0,
      // Initialize sit-up specific metrics
      noseY: 0,
      hipY: 0,
      shoulderDiffFromGround: 0,
      hipLift: 0,
      wristDistance: 0,
      isHandPositionCorrect: true,
      isShoulderBladeGrounded: true,
      isHipStable: true,
      isKneeAngleCorrect: true,
      // Initialize pull-up specific metrics
      chinClearsBar: false,
      normalizedHorizontalDisplacement: 0,
      isKipping: false,
      isSwinging: false,
      chinY: 0,
      mouthY: 0,
      barHeight: 0,
      chinBarProximity: 0,
      hipX: 0,
      shoulderWidth: 0
    };
  }
  
  /**
   * Get the last rep's metrics
   */
  getLastRepMetrics(): RepMetrics {
    return this.lastRepMetrics;
  }
  
  /**
   * Get the current rep's metrics
   */
  getCurrentRepMetrics(): RepMetrics {
    return this.currentRepMetrics;
  }
  
  /**
   * Determine a stable state from the state buffer
   * @returns The stable state or UNKNOWN if no stable state
   */
  private getStableState(): RepState {
    if (this.stateBuffer.length < this.config.stateStabilityThreshold) {
      return 'UNKNOWN';
    }
    
    // Check if all states in the buffer are the same
    const firstState = this.stateBuffer[0];
    const allSame = this.stateBuffer.every(state => state === firstState);
    
    return allSame ? firstState : 'TRANSITION';
  }
  
  /**
   * Determine the current direction of movement
   * @returns Direction of movement
   */
  private getDirection(): RepDirection {
    if (this.previousState === 'DOWN' && this.currentState === 'UP') {
      return RepDirection.DOWN_TO_UP;
    } else if (this.previousState === 'UP' && this.currentState === 'DOWN') {
      return RepDirection.UP_TO_DOWN;
    } else {
      return RepDirection.NONE;
    }
  }
  
  /**
   * Generate a summary report for the completed set
   */
  generateSetSummary(): SetSummaryReport {
    const totalAttemptedReps = this.totalReps + this.invalidReps;
    const validRepPercentage = totalAttemptedReps > 0 
      ? (this.totalReps / totalAttemptedReps) * 100 
      : 0;
    
    const averageFormScore = this.repScores.length > 0 
      ? this.repScores.reduce((sum, score) => sum + score, 0) / this.repScores.length 
      : 0;
    
    // Format form issues into an array for reporting
    const formIssues = Array.from(this.formIssueReasons.entries()).map(([reason, count]) => ({
      reason,
      count
    }));
    
    return {
      totalValidReps: this.totalReps,
      totalInvalidReps: this.invalidReps,
      validRepPercentage,
      averageFormScore,
      formIssues,
      repScores: [...this.repScores],
      totalAttemptedReps,
      setDurationMs: Date.now() - this.setStartTimestamp,
      startTimestamp: this.setStartTimestamp,
      endTimestamp: Date.now()
    };
  }
} 