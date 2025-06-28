import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { GradingResult } from '../ExerciseGrader';
import { SitupAnalyzer, SitupFormAnalysis } from '../SitupAnalyzer';
import { BaseGrader, FormIssue, GraderConfig, POSE_LANDMARKS } from './BaseGrader';
import { calculateSitupScore } from '../APFTScoring';

enum SitupPhase {
  DOWN = 'down',
  RISING = 'rising',
  LOWERING = 'lowering'
}

interface SitupConfig extends GraderConfig {
  minTrunkAngle?: number;
  maxTrunkAngle?: number;
  minKneeAngle?: number;
  maxKneeAngle?: number;
  elbowToKneeThreshold?: number;
}

export class SitupGrader extends BaseGrader {
  private analyzer: SitupAnalyzer;
  private phase: SitupPhase = SitupPhase.DOWN;
  private hasReachedTop: boolean = false;
  private repStartTime: number = 0;
  private situpConfig: SitupConfig;
  
  private maxTrunkAngleInRep: number = 0;
  private shoulderBladesGroundedFrames: number = 0;
  private elbowsReachedKnees: boolean = false;
  
  constructor(config: SitupConfig = {}) {
    super('situp', config);
    this.situpConfig = {
      minTrunkAngle: 70,
      maxTrunkAngle: 95,
      minKneeAngle: 80,
      maxKneeAngle: 100,
      elbowToKneeThreshold: 0.15,
      ...config
    };
    
    this.analyzer = new SitupAnalyzer({
      minTrunkAngle: this.situpConfig.minTrunkAngle!,
      maxTrunkAngle: this.situpConfig.maxTrunkAngle!,
      minKneeAngle: this.situpConfig.minKneeAngle! - 10,
      maxKneeAngle: this.situpConfig.maxKneeAngle! + 10
    });
  }

  reset(): void {
    super.reset();
    this.analyzer.reset();
    this.phase = SitupPhase.DOWN;
    this.hasReachedTop = false;
    this.repStartTime = 0;
    this.maxTrunkAngleInRep = 0;
    this.shoulderBladesGroundedFrames = 0;
    this.elbowsReachedKnees = false;
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
    
    if (this.calibrationFrames === 0) {
      this.analyzer.setCalibrationData(landmarks);
    }
    
    const analysis = this.analyzer.analyzeSitupForm(landmarks, timestamp);
    
    this.performCalibration(landmarks, analysis);
    
    this.updateState(landmarks, analysis);
    
    const formIssues = this.validateForm(landmarks, analysis);
    this.updateFormScore(formIssues);
    
    let repIncrement = 0;
    if (this.phase === SitupPhase.DOWN && 
        this.hasReachedTop && 
        this.isStable() &&
        analysis.isDownPosition &&
        this.shoulderBladesGroundedFrames >= 3) {
      
      const repDuration = timestamp - this.repStartTime;
      const validRep = this.elbowsReachedKnees &&
                      formIssues.filter(i => i.severity === 'critical').length === 0 &&
                      repDuration > 500 && repDuration < 10000;
      
      if (validRep) {
        this.incrementRep();
        repIncrement = 1;
        this.debugLog('Rep completed', { 
          count: this.repCount, 
          formScore: this.currentFormScore,
          duration: repDuration,
          maxTrunkAngle: this.maxTrunkAngleInRep
        });
      }
      
      this.hasReachedTop = false;
      this.maxTrunkAngleInRep = 0;
      this.elbowsReachedKnees = false;
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
      POSE_LANDMARKS.NOSE,
      POSE_LANDMARKS.LEFT_EAR,
      POSE_LANDMARKS.RIGHT_EAR,
      POSE_LANDMARKS.LEFT_SHOULDER,
      POSE_LANDMARKS.RIGHT_SHOULDER,
      POSE_LANDMARKS.LEFT_ELBOW,
      POSE_LANDMARKS.RIGHT_ELBOW,
      POSE_LANDMARKS.LEFT_WRIST,
      POSE_LANDMARKS.RIGHT_WRIST,
      POSE_LANDMARKS.LEFT_HIP,
      POSE_LANDMARKS.RIGHT_HIP,
      POSE_LANDMARKS.LEFT_KNEE,
      POSE_LANDMARKS.RIGHT_KNEE,
      POSE_LANDMARKS.LEFT_ANKLE,
      POSE_LANDMARKS.RIGHT_ANKLE
    ];
  }

  protected updateState(landmarks: NormalizedLandmark[], analysis?: SitupFormAnalysis): void {
    const form = analysis || this.analyzer.analyzeSitupForm(landmarks, Date.now());
    
    if (form.trunkAngle > this.maxTrunkAngleInRep) {
      this.maxTrunkAngleInRep = form.trunkAngle;
    }
    
    if (form.isShoulderBladeGrounded) {
      this.shoulderBladesGroundedFrames++;
    } else {
      this.shoulderBladesGroundedFrames = 0;
    }
    
    const leftElbow = landmarks[POSE_LANDMARKS.LEFT_ELBOW];
    const rightElbow = landmarks[POSE_LANDMARKS.RIGHT_ELBOW];
    const leftKnee = landmarks[POSE_LANDMARKS.LEFT_KNEE];
    const rightKnee = landmarks[POSE_LANDMARKS.RIGHT_KNEE];
    
    const leftElbowToKnee = this.calculateDistance(leftElbow, leftKnee);
    const rightElbowToKnee = this.calculateDistance(rightElbow, rightKnee);
    const minElbowToKnee = Math.min(leftElbowToKnee, rightElbowToKnee);
    
    if (minElbowToKnee < this.situpConfig.elbowToKneeThreshold!) {
      this.elbowsReachedKnees = true;
    }
    
    switch (this.phase) {
      case SitupPhase.DOWN:
        if (form.isDownPosition && this.shoulderBladesGroundedFrames >= 3) {
          if (!form.isShoulderBladeGrounded || form.repProgress > 0.1) {
            this.changeState(SitupPhase.RISING);
          }
        }
        break;
        
      case SitupPhase.RISING:
        if (form.isUpPosition || form.trunkAngle >= this.situpConfig.minTrunkAngle!) {
          this.hasReachedTop = true;
          
          if (form.repProgress >= 0.9 && this.elbowsReachedKnees) {
            this.changeState(SitupPhase.LOWERING);
          }
        }
        
        if (form.repProgress < 0.3 && !this.hasReachedTop) {
          this.changeState(SitupPhase.DOWN);
        }
        break;
        
      case SitupPhase.LOWERING:
        if (form.isDownPosition && form.isShoulderBladeGrounded) {
          this.changeState(SitupPhase.DOWN);
        }
        
        if (form.repProgress > 0.8 && form.trunkAngle >= this.situpConfig.minTrunkAngle!) {
          this.changeState(SitupPhase.RISING);
        }
        break;
    }
  }

  protected validateForm(landmarks: NormalizedLandmark[], analysis?: SitupFormAnalysis): FormIssue[] {
    const form = analysis || this.analyzer.analyzeSitupForm(landmarks, Date.now());
    const issues: FormIssue[] = [];
    
    if (!form.isHandPositionCorrect) {
      issues.push({
        severity: 'critical',
        message: 'Keep hands behind head with fingers interlocked',
        joints: [POSE_LANDMARKS.LEFT_WRIST, POSE_LANDMARKS.RIGHT_WRIST]
      });
    }
    
    if (!form.isKneeAngleCorrect) {
      const avgKneeAngle = (form.leftKneeAngle + form.rightKneeAngle) / 2;
      const message = avgKneeAngle < this.situpConfig.minKneeAngle! 
        ? 'Keep knees bent at 90 degrees'
        : 'Do not straighten knees too much';
      
      issues.push({
        severity: 'moderate',
        message,
        joints: [POSE_LANDMARKS.LEFT_KNEE, POSE_LANDMARKS.RIGHT_KNEE]
      });
    }
    
    if (!form.isHipStable) {
      issues.push({
        severity: 'critical',
        message: 'Keep hips on the ground',
        joints: [POSE_LANDMARKS.LEFT_HIP, POSE_LANDMARKS.RIGHT_HIP]
      });
    }
    
    if (form.isPaused) {
      issues.push({
        severity: 'moderate',
        message: 'Keep moving - no pausing',
        joints: []
      });
    }
    
    if (this.phase === SitupPhase.RISING && !this.elbowsReachedKnees && form.repProgress > 0.7) {
      issues.push({
        severity: 'minor',
        message: 'Touch elbows to knees',
        joints: [POSE_LANDMARKS.LEFT_ELBOW, POSE_LANDMARKS.RIGHT_ELBOW]
      });
    }
    
    if (this.phase === SitupPhase.DOWN && !form.isShoulderBladeGrounded && this.stateFrameCount > 10) {
      issues.push({
        severity: 'minor',
        message: 'Touch shoulder blades to ground',
        joints: [POSE_LANDMARKS.LEFT_SHOULDER, POSE_LANDMARKS.RIGHT_SHOULDER]
      });
    }
    
    return issues;
  }

  protected performCalibration(landmarks: NormalizedLandmark[], analysis: SitupFormAnalysis): void {
    super.performCalibration(landmarks);
    
    if (this.calibrationFrames === 1) {
      this.debugLog('Situp calibration complete', {
        shoulderY: analysis.initialShoulderY,
        hipY: analysis.initialHipY
      });
    }
  }

  getAPFTScore(age: number, gender: 'male' | 'female'): number {
    return calculateSitupScore(this.repCount);
  }
}