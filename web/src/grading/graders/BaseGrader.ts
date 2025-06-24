import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { GradingResult, ExerciseGrader } from '../ExerciseGrader';

export interface CalibrationData {
  armExtensionAngle?: number;
  shoulderHeight?: number;
  hipHeight?: number;
  kneeAngle?: number;
  torsoLength?: number;
}

export interface FormIssue {
  severity: 'critical' | 'moderate' | 'minor';
  message: string;
  joints: number[];
}

export interface GraderConfig {
  minStabilityFrames?: number;
  adaptiveCalibration?: boolean;
  formScoreEnabled?: boolean;
  debugMode?: boolean;
}

export abstract class BaseGrader implements ExerciseGrader {
  protected exerciseType: string;
  protected state: string = 'ready';
  protected previousState: string = 'ready';
  protected repCount: number = 0;
  protected formScores: number[] = [];
  protected currentFormScore: number = 100;
  protected problemJoints: Set<number> = new Set();
  protected lastFormIssue: string | null = null;
  protected stateFrameCount: number = 0;
  protected calibrationFrames: number = 0;
  protected calibrationData: CalibrationData = {};
  protected config: GraderConfig;
  
  private frameCount: number = 0;
  private lastMovement: number = 0;
  private movementHistory: number[] = [];
  private readonly MOVEMENT_WINDOW = 10;
  
  constructor(exerciseType: string, config: GraderConfig = {}) {
    this.exerciseType = exerciseType;
    this.config = {
      minStabilityFrames: 3,
      adaptiveCalibration: true,
      formScoreEnabled: true,
      debugMode: false,
      ...config
    };
  }

  abstract processPose(landmarks: NormalizedLandmark[]): GradingResult;
  
  protected abstract getRequiredLandmarks(): number[];
  
  protected abstract updateState(landmarks: NormalizedLandmark[]): void;
  
  protected abstract validateForm(landmarks: NormalizedLandmark[]): FormIssue[];

  reset(): void {
    this.state = 'ready';
    this.previousState = 'ready';
    this.repCount = 0;
    this.formScores = [];
    this.currentFormScore = 100;
    this.problemJoints.clear();
    this.lastFormIssue = null;
    this.stateFrameCount = 0;
    this.calibrationFrames = 0;
    this.calibrationData = {};
    this.frameCount = 0;
    this.lastMovement = 0;
    this.movementHistory = [];
  }

  getState(): string {
    return this.state;
  }

  getExerciseType(): string {
    return this.exerciseType;
  }

  getRepCount(): number {
    return this.repCount;
  }

  getFormScore(): number {
    if (this.formScores.length === 0) return 100;
    return Math.round(
      this.formScores.reduce((a, b) => a + b, 0) / this.formScores.length
    );
  }

  getAPFTScore(age: number, gender: 'male' | 'female'): number {
    return 0;
  }

  getProblemJoints(): number[] {
    return Array.from(this.problemJoints);
  }

  protected areLandmarksVisible(
    landmarks: NormalizedLandmark[],
    indices: number[],
    threshold: number = 0.6
  ): boolean {
    return indices.every(idx => {
      const landmark = landmarks[idx];
      return landmark && 
             landmark.visibility !== undefined && 
             landmark.visibility > threshold;
    });
  }

  protected calculateAngle(
    a: NormalizedLandmark,
    b: NormalizedLandmark,
    c: NormalizedLandmark
  ): number {
    const radians = Math.atan2(c.y - b.y, c.x - b.x) - 
                    Math.atan2(a.y - b.y, a.x - b.x);
    let degrees = Math.abs(radians * 180 / Math.PI);
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  protected calculateDistance(
    a: NormalizedLandmark,
    b: NormalizedLandmark
  ): number {
    return Math.sqrt(
      Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2)
    );
  }

  protected changeState(newState: string): void {
    if (this.state !== newState) {
      this.previousState = this.state;
      this.state = newState;
      this.stateFrameCount = 0;
      if (this.config.debugMode) {
        console.log(`State change: ${this.previousState} -> ${newState}`);
      }
    } else {
      this.stateFrameCount++;
    }
  }

  protected isStable(): boolean {
    return this.stateFrameCount >= (this.config.minStabilityFrames || 3);
  }

  protected updateMovementHistory(movement: number): void {
    this.movementHistory.push(movement);
    if (this.movementHistory.length > this.MOVEMENT_WINDOW) {
      this.movementHistory.shift();
    }
    this.lastMovement = movement;
  }

  protected getAverageMovement(): number {
    if (this.movementHistory.length === 0) return 0;
    return this.movementHistory.reduce((a, b) => a + b, 0) / 
           this.movementHistory.length;
  }

  protected isMovementStable(threshold: number = 0.02): boolean {
    if (this.movementHistory.length < this.MOVEMENT_WINDOW / 2) return false;
    
    const avg = this.getAverageMovement();
    const variance = this.movementHistory.reduce((sum, val) => {
      return sum + Math.pow(val - avg, 2);
    }, 0) / this.movementHistory.length;
    
    return Math.sqrt(variance) < threshold;
  }

  protected updateFormScore(issues: FormIssue[]): void {
    if (!this.config.formScoreEnabled) return;

    let frameScore = 100;
    this.problemJoints.clear();

    for (const issue of issues) {
      switch (issue.severity) {
        case 'critical':
          frameScore -= 20;
          break;
        case 'moderate':
          frameScore -= 10;
          break;
        case 'minor':
          frameScore -= 5;
          break;
      }
      
      issue.joints.forEach(joint => this.problemJoints.add(joint));
    }

    frameScore = Math.max(0, frameScore);
    this.currentFormScore = frameScore;
    
    if (issues.length > 0) {
      const criticalIssue = issues.find(i => i.severity === 'critical');
      this.lastFormIssue = criticalIssue?.message || issues[0].message;
    } else {
      this.lastFormIssue = null;
    }
  }

  protected incrementRep(): void {
    this.repCount++;
    if (this.currentFormScore > 0) {
      this.formScores.push(this.currentFormScore);
    }
    this.currentFormScore = 100;
  }

  protected performCalibration(landmarks: NormalizedLandmark[]): void {
    if (!this.config.adaptiveCalibration) return;
    if (this.calibrationFrames >= 30) return;
    
    this.calibrationFrames++;
  }

  protected debugLog(message: string, data?: any): void {
    if (this.config.debugMode) {
      console.log(`[${this.exerciseType}] ${message}`, data || '');
    }
  }
}

export const POSE_LANDMARKS = {
  NOSE: 0,
  LEFT_EYE_INNER: 1,
  LEFT_EYE: 2,
  LEFT_EYE_OUTER: 3,
  RIGHT_EYE_INNER: 4,
  RIGHT_EYE: 5,
  RIGHT_EYE_OUTER: 6,
  LEFT_EAR: 7,
  RIGHT_EAR: 8,
  LEFT_MOUTH: 9,
  RIGHT_MOUTH: 10,
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
  LEFT_HEEL: 29,
  RIGHT_HEEL: 30,
  LEFT_FOOT_INDEX: 31,
  RIGHT_FOOT_INDEX: 32
};