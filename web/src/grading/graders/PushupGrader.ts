import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { GradingResult } from '../ExerciseGrader';
import { PushupAnalyzer, PushupFormAnalysis } from '../PushupAnalyzer';
import { BaseGrader, FormIssue, GraderConfig, POSE_LANDMARKS } from './BaseGrader';
import { getAPFTScore } from '../APFTScoring';

enum PushupPhase {
  UP = 'up',
  DESCENDING = 'descending',
  ASCENDING = 'ascending'
}

interface PushupConfig extends GraderConfig {
  minArmExtensionAngle?: number;
  maxElbowFlexionAngle?: number;
  minDescentDistance?: number;
  calibrationEnabled?: boolean;
}

export class PushupGrader extends BaseGrader {
  private analyzer: PushupAnalyzer;
  private phase: PushupPhase = PushupPhase.UP;
  private hasReachedBottom: boolean = false;
  private startHeight: number = 0;
  private lowestPoint: number = 0;
  private repStartTime: number = 0;
  private pushupConfig: PushupConfig;
  
  private calibratedArmExtension: number = 160;
  private calibrationSamples: number[] = [];
  
  constructor(config: PushupConfig = {}) {
    super('pushup', config);
    this.pushupConfig = {
      minArmExtensionAngle: 150,
      maxElbowFlexionAngle: 100,
      minDescentDistance: 0.015,
      calibrationEnabled: true,
      ...config
    };
    
    this.analyzer = new PushupAnalyzer({
      minElbowExtensionAngle: this.pushupConfig.minArmExtensionAngle!,
      maxElbowFlexionAngle: this.pushupConfig.maxElbowFlexionAngle!
    });
  }

  reset(): void {
    super.reset();
    this.analyzer.reset();
    this.phase = PushupPhase.UP;
    this.hasReachedBottom = false;
    this.startHeight = 0;
    this.lowestPoint = 0;
    this.repStartTime = 0;
    this.calibratedArmExtension = this.pushupConfig.minArmExtensionAngle!;
    this.calibrationSamples = [];
  }

  processPose(landmarks: NormalizedLandmark[]): GradingResult {
    const timestamp = Date.now();
    
    if (!this.areLandmarksVisible(landmarks, this.getRequiredLandmarks())) {
      return {
        state: 'unknown',
        repIncrement: 0,
        hasFormFault: false,
        formFault: 'Cannot see all required body parts'
      };
    }
    
    const analysis = this.analyzer.analyzePushupForm(landmarks, timestamp);
    
    this.performCalibration(landmarks, analysis);
    
    this.updateState(landmarks, analysis);
    
    const formIssues = this.validateForm(landmarks, analysis);
    this.updateFormScore(formIssues);
    
    let repIncrement = 0;
    if (this.phase === PushupPhase.UP && 
        this.hasReachedBottom && 
        this.isStable() &&
        analysis.isUpPosition) {
      
      const repDuration = timestamp - this.repStartTime;
      const validRep = analysis.minElbowAngleDuringRep <= this.pushupConfig.maxElbowFlexionAngle! &&
                      formIssues.filter(i => i.severity === 'critical').length === 0 &&
                      repDuration > 500;
      
      if (validRep) {
        this.incrementRep();
        repIncrement = 1;
        this.debugLog('Rep completed', { 
          count: this.repCount, 
          formScore: this.currentFormScore,
          duration: repDuration 
        });
      }
      
      this.hasReachedBottom = false;
      this.analyzer.resetMinElbowAngle();
      this.repStartTime = timestamp;
    }
    
    return {
      state: this.phase,
      repIncrement,
      hasFormFault: formIssues.some(i => i.severity === 'critical'),
      formFault: this.lastFormIssue || undefined,
      formScore: this.currentFormScore
    };
  }

  protected getRequiredLandmarks(): number[] {
    return [
      POSE_LANDMARKS.LEFT_SHOULDER,
      POSE_LANDMARKS.RIGHT_SHOULDER,
      POSE_LANDMARKS.LEFT_ELBOW,
      POSE_LANDMARKS.RIGHT_ELBOW,
      POSE_LANDMARKS.LEFT_WRIST,
      POSE_LANDMARKS.RIGHT_WRIST,
      POSE_LANDMARKS.LEFT_HIP,
      POSE_LANDMARKS.RIGHT_HIP,
      POSE_LANDMARKS.LEFT_ANKLE,
      POSE_LANDMARKS.RIGHT_ANKLE
    ];
  }

  protected updateState(landmarks: NormalizedLandmark[], analysis?: PushupFormAnalysis): void {
    const form = analysis || this.analyzer.analyzePushupForm(landmarks, Date.now());
    const currentElbowAngle = Math.min(form.leftElbowAngle, form.rightElbowAngle);
    
    const shoulderHeight = (landmarks[POSE_LANDMARKS.LEFT_SHOULDER].y + 
                           landmarks[POSE_LANDMARKS.RIGHT_SHOULDER].y) / 2;
    
    switch (this.phase) {
      case PushupPhase.UP:
        if (currentElbowAngle >= this.calibratedArmExtension) {
          if (this.startHeight === 0) {
            this.startHeight = shoulderHeight;
          }
          
          if (currentElbowAngle < this.calibratedArmExtension - 10) {
            this.changeState(PushupPhase.DESCENDING);
            this.lowestPoint = shoulderHeight;
          }
        }
        break;
        
      case PushupPhase.DESCENDING:
        if (shoulderHeight > this.lowestPoint) {
          this.lowestPoint = shoulderHeight;
        }
        
        const descentDistance = this.lowestPoint - this.startHeight;
        
        if (currentElbowAngle <= this.pushupConfig.maxElbowFlexionAngle! ||
            descentDistance >= this.pushupConfig.minDescentDistance!) {
          this.hasReachedBottom = true;
        }
        
        if (currentElbowAngle > this.pushupConfig.maxElbowFlexionAngle! + 20 &&
            shoulderHeight < this.lowestPoint - 0.01) {
          this.changeState(PushupPhase.ASCENDING);
        }
        break;
        
      case PushupPhase.ASCENDING:
        const returnThreshold = this.startHeight + 0.02;
        
        if (currentElbowAngle >= this.calibratedArmExtension &&
            shoulderHeight <= returnThreshold) {
          this.changeState(PushupPhase.UP);
        }
        break;
    }
  }

  protected validateForm(landmarks: NormalizedLandmark[], analysis?: PushupFormAnalysis): FormIssue[] {
    const form = analysis || this.analyzer.analyzePushupForm(landmarks, Date.now());
    const issues: FormIssue[] = [];
    
    if (form.isBodySagging) {
      issues.push({
        severity: 'critical',
        message: 'Keep your body straight - hips are sagging',
        joints: [POSE_LANDMARKS.LEFT_HIP, POSE_LANDMARKS.RIGHT_HIP]
      });
    }
    
    if (form.isBodyPiking) {
      issues.push({
        severity: 'critical',
        message: 'Keep your body straight - hips are too high',
        joints: [POSE_LANDMARKS.LEFT_HIP, POSE_LANDMARKS.RIGHT_HIP]
      });
    }
    
    if (form.isWorming) {
      issues.push({
        severity: 'moderate',
        message: 'Move your body as one unit',
        joints: [
          POSE_LANDMARKS.LEFT_SHOULDER, 
          POSE_LANDMARKS.RIGHT_SHOULDER,
          POSE_LANDMARKS.LEFT_HIP,
          POSE_LANDMARKS.RIGHT_HIP
        ]
      });
    }
    
    if (form.kneesTouchingGround) {
      issues.push({
        severity: 'critical',
        message: 'Keep knees off the ground',
        joints: [POSE_LANDMARKS.LEFT_KNEE, POSE_LANDMARKS.RIGHT_KNEE]
      });
    }
    
    if (form.handsLiftedOff) {
      issues.push({
        severity: 'critical',
        message: 'Keep hands on the ground',
        joints: [POSE_LANDMARKS.LEFT_WRIST, POSE_LANDMARKS.RIGHT_WRIST]
      });
    }
    
    if (form.isPaused) {
      issues.push({
        severity: 'moderate',
        message: 'Keep moving - no pausing',
        joints: []
      });
    }
    
    if (this.phase === PushupPhase.UP && !form.isUpPosition && this.stateFrameCount > 10) {
      issues.push({
        severity: 'minor',
        message: 'Fully extend your arms',
        joints: [POSE_LANDMARKS.LEFT_ELBOW, POSE_LANDMARKS.RIGHT_ELBOW]
      });
    }
    
    return issues;
  }

  protected performCalibration(landmarks: NormalizedLandmark[], analysis: PushupFormAnalysis): void {
    if (!this.pushupConfig.calibrationEnabled) return;
    if (this.calibrationFrames >= 30) return;
    
    super.performCalibration(landmarks);
    
    if (this.phase === PushupPhase.UP && analysis.isUpPosition) {
      const currentAngle = Math.min(analysis.leftElbowAngle, analysis.rightElbowAngle);
      
      if (currentAngle > 140 && currentAngle < 175) {
        this.calibrationSamples.push(currentAngle);
        
        if (this.calibrationSamples.length >= 5) {
          const avgAngle = this.calibrationSamples.reduce((a, b) => a + b, 0) / 
                          this.calibrationSamples.length;
          
          this.calibratedArmExtension = Math.max(150, avgAngle - 5);
          
          this.debugLog('Calibrated arm extension', { 
            angle: this.calibratedArmExtension,
            samples: this.calibrationSamples.length 
          });
        }
      }
    }
  }

  getAPFTScore(age: number, gender: 'male' | 'female'): number {
    return getAPFTScore('pushup', this.repCount, age, gender);
  }
}