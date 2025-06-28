import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { GradingResult } from '../ExerciseGrader';
import { PullupAnalyzer, PullupFormAnalysis } from '../PullupAnalyzer';
import { BaseGrader, FormIssue, GraderConfig, POSE_LANDMARKS } from './BaseGrader';
import { calculatePullupScore } from '../APFTScoring';

enum PullupPhase {
  DOWN = 'down',
  PULLING = 'pulling',
  LOWERING = 'lowering'
}

interface PullupConfig extends GraderConfig {
  minElbowLockoutAngle?: number;
  maxElbowTopAngle?: number;
  chinClearanceThreshold?: number;
  maxSwingDistance?: number;
  maxKippingAngle?: number;
  deadHangFrames?: number;
}

export class PullupGrader extends BaseGrader {
  private analyzer: PullupAnalyzer;
  private phase: PullupPhase = PullupPhase.DOWN;
  private hasReachedTop: boolean = false;
  private startedFromDeadHang: boolean = false;
  private repStartTime: number = 0;
  private pullupConfig: PullupConfig;
  
  private deadHangFrameCount: number = 0;
  private chinClearedFrames: number = 0;
  private peakHeight: number = 1;
  
  constructor(config: PullupConfig = {}) {
    super('pullup', config);
    this.pullupConfig = {
      minElbowLockoutAngle: 160,
      maxElbowTopAngle: 120,
      chinClearanceThreshold: 0.02,
      maxSwingDistance: 0.1,
      maxKippingAngle: 20,
      deadHangFrames: 3,
      ...config
    };
    
    this.analyzer = new PullupAnalyzer({
      minElbowLockoutAngle: this.pullupConfig.minElbowLockoutAngle!,
      maxElbowTopAngle: this.pullupConfig.maxElbowTopAngle!,
      chinAboveBarThreshold: this.pullupConfig.chinClearanceThreshold!,
      maxHorizontalDisplacement: this.pullupConfig.maxSwingDistance!,
      maxKneeAngleChange: this.pullupConfig.maxKippingAngle!
    });
  }

  reset(): void {
    super.reset();
    this.analyzer.reset();
    this.phase = PullupPhase.DOWN;
    this.hasReachedTop = false;
    this.startedFromDeadHang = false;
    this.repStartTime = 0;
    this.deadHangFrameCount = 0;
    this.chinClearedFrames = 0;
    this.peakHeight = 1;
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
    
    const analysis = this.analyzer.analyzePullupForm(landmarks, timestamp);
    
    this.performCalibration(landmarks, analysis);
    
    this.updateState(landmarks, analysis);
    
    const formIssues = this.validateForm(landmarks, analysis);
    this.updateFormScore(formIssues);
    
    let repIncrement = 0;
    if (this.phase === PullupPhase.DOWN && 
        this.hasReachedTop && 
        this.startedFromDeadHang &&
        this.isStable() &&
        analysis.isDownPosition &&
        this.deadHangFrameCount >= this.pullupConfig.deadHangFrames!) {
      
      const repDuration = timestamp - this.repStartTime;
      const validRep = this.chinClearedFrames >= 3 &&
                      formIssues.filter(i => i.severity === 'critical').length === 0 &&
                      repDuration > 500 && repDuration < 15000;
      
      if (validRep) {
        this.incrementRep();
        repIncrement = 1;
        this.debugLog('Rep completed', { 
          count: this.repCount, 
          formScore: this.currentFormScore,
          duration: repDuration,
          peakHeight: this.peakHeight 
        });
      }
      
      this.hasReachedTop = false;
      this.startedFromDeadHang = false;
      this.chinClearedFrames = 0;
      this.peakHeight = 1;
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

  protected updateState(landmarks: NormalizedLandmark[], analysis?: PullupFormAnalysis): void {
    const form = analysis || this.analyzer.analyzePullupForm(landmarks, Date.now());
    
    if (form.isElbowLocked) {
      this.deadHangFrameCount++;
    } else {
      this.deadHangFrameCount = 0;
    }
    
    if (form.chinClearsBar) {
      this.chinClearedFrames++;
    } else {
      this.chinClearedFrames = Math.max(0, this.chinClearedFrames - 1);
    }
    
    const noseHeight = landmarks[POSE_LANDMARKS.NOSE].y;
    if (noseHeight < this.peakHeight) {
      this.peakHeight = noseHeight;
    }
    
    switch (this.phase) {
      case PullupPhase.DOWN:
        if (form.isDownPosition && 
            form.isElbowLocked && 
            this.deadHangFrameCount >= this.pullupConfig.deadHangFrames!) {
          
          this.startedFromDeadHang = true;
          
          if (form.repProgress > 0.1 || !form.isElbowLocked) {
            this.changeState(PullupPhase.PULLING);
          }
        }
        break;
        
      case PullupPhase.PULLING:
        if (form.chinClearsBar || form.isUpPosition) {
          this.hasReachedTop = true;
          
          if (this.chinClearedFrames >= 2) {
            this.changeState(PullupPhase.LOWERING);
          }
        }
        
        if (form.repProgress < 0.2 && !this.hasReachedTop) {
          this.changeState(PullupPhase.DOWN);
        }
        break;
        
      case PullupPhase.LOWERING:
        if (form.isDownPosition && form.isElbowLocked) {
          this.changeState(PullupPhase.DOWN);
        }
        
        if (form.repProgress > 0.8 && form.chinClearsBar) {
          this.changeState(PullupPhase.PULLING);
        }
        break;
    }
  }

  protected validateForm(landmarks: NormalizedLandmark[], analysis?: PullupFormAnalysis): FormIssue[] {
    const form = analysis || this.analyzer.analyzePullupForm(landmarks, Date.now());
    const issues: FormIssue[] = [];
    
    if (form.isSwinging) {
      issues.push({
        severity: 'critical',
        message: 'Control your body - no swinging',
        joints: [POSE_LANDMARKS.LEFT_HIP, POSE_LANDMARKS.RIGHT_HIP]
      });
    }
    
    if (form.isKipping) {
      issues.push({
        severity: 'critical',
        message: 'No kipping - keep legs straight',
        joints: [POSE_LANDMARKS.LEFT_KNEE, POSE_LANDMARKS.RIGHT_KNEE]
      });
    }
    
    if (form.isPaused) {
      issues.push({
        severity: 'moderate',
        message: 'Keep moving - no pausing',
        joints: []
      });
    }
    
    if (this.phase === PullupPhase.DOWN && !form.isElbowLocked && this.stateFrameCount > 10) {
      issues.push({
        severity: 'minor',
        message: 'Fully extend arms to dead hang',
        joints: [POSE_LANDMARKS.LEFT_ELBOW, POSE_LANDMARKS.RIGHT_ELBOW]
      });
    }
    
    if (this.phase === PullupPhase.PULLING && !form.chinClearsBar && form.repProgress > 0.8) {
      issues.push({
        severity: 'minor',
        message: 'Pull chin above the bar',
        joints: [POSE_LANDMARKS.NOSE]
      });
    }
    
    const avgElbowAngle = (form.leftElbowAngle + form.rightElbowAngle) / 2;
    if (this.phase === PullupPhase.PULLING && avgElbowAngle < 60) {
      issues.push({
        severity: 'moderate',
        message: 'Pull with control - elbows too tight',
        joints: [POSE_LANDMARKS.LEFT_ELBOW, POSE_LANDMARKS.RIGHT_ELBOW]
      });
    }
    
    return issues;
  }

  protected performCalibration(landmarks: NormalizedLandmark[], analysis: PullupFormAnalysis): void {
    super.performCalibration(landmarks);
    
    if (this.calibrationFrames === 1) {
      this.debugLog('Pullup calibration complete', {
        barY: analysis.barY,
        leftWristX: analysis.leftWristX,
        rightWristX: analysis.rightWristX,
        hipX: analysis.hipX
      });
    }
  }

  getAPFTScore(age: number, gender: 'male' | 'female'): number {
    return calculatePullupScore(this.repCount);
  }
}