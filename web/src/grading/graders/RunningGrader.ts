import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { GradingResult } from '../ExerciseGrader';
import { BaseGrader, FormIssue, GraderConfig } from './BaseGrader';
import { calculateRunningScore } from '../APFTScoring';

interface RunningConfig extends GraderConfig {
  targetDistanceMeters?: number;
  maxDurationSeconds?: number;
  minPaceMetersPerSecond?: number;
  maxPaceMetersPerSecond?: number;
}

interface GPSPosition {
  latitude: number;
  longitude: number;
  timestamp: number;
  accuracy?: number;
}

export class RunningGrader extends BaseGrader {
  private runningConfig: RunningConfig;
  
  private startTime: number = 0;
  private endTime: number = 0;
  private totalDistanceMeters: number = 0;
  private elapsedTimeSeconds: number = 0;
  private currentPaceMetersPerSecond: number = 0;
  private isRunning: boolean = false;
  private isComplete: boolean = false;
  
  private gpsPositions: GPSPosition[] = [];
  private lastPosition: GPSPosition | null = null;
  
  private static readonly METERS_PER_MILE = 1609.34;
  private static readonly TWO_MILES_METERS = 3218.69;
  
  constructor(config: RunningConfig = {}) {
    super('run', config);
    this.runningConfig = {
      targetDistanceMeters: RunningGrader.TWO_MILES_METERS,
      maxDurationSeconds: 1800,
      minPaceMetersPerSecond: 1.5,
      maxPaceMetersPerSecond: 7.0,
      ...config
    };
  }

  reset(): void {
    super.reset();
    this.startTime = 0;
    this.endTime = 0;
    this.totalDistanceMeters = 0;
    this.elapsedTimeSeconds = 0;
    this.currentPaceMetersPerSecond = 0;
    this.isRunning = false;
    this.isComplete = false;
    this.gpsPositions = [];
    this.lastPosition = null;
  }

  startRun(): void {
    if (!this.isRunning && !this.isComplete) {
      this.startTime = Date.now();
      this.isRunning = true;
      this.changeState('running');
      this.debugLog('Run started', { startTime: this.startTime });
    }
  }

  stopRun(): void {
    if (this.isRunning) {
      this.endTime = Date.now();
      this.isRunning = false;
      this.isComplete = true;
      this.elapsedTimeSeconds = (this.endTime - this.startTime) / 1000;
      this.changeState('completed');
      
      const score = this.calculateScore();
      this.currentFormScore = score;
      this.formScores.push(score);
      
      this.debugLog('Run completed', {
        distance: this.totalDistanceMeters,
        duration: this.elapsedTimeSeconds,
        score: score
      });
    }
  }

  updateGPSPosition(position: GPSPosition): void {
    if (!this.isRunning) return;
    
    if (this.lastPosition) {
      const distance = this.calculateDistance(
        this.lastPosition.latitude,
        this.lastPosition.longitude,
        position.latitude,
        position.longitude
      );
      
      const timeDelta = (position.timestamp - this.lastPosition.timestamp) / 1000;
      
      if (timeDelta > 0 && distance > 0 && distance < 100) {
        this.totalDistanceMeters += distance;
        this.currentPaceMetersPerSecond = distance / timeDelta;
        
        this.updateMovementHistory(this.currentPaceMetersPerSecond);
      }
    }
    
    this.gpsPositions.push(position);
    this.lastPosition = position;
    this.elapsedTimeSeconds = (Date.now() - this.startTime) / 1000;
    
    if (this.totalDistanceMeters >= this.runningConfig.targetDistanceMeters!) {
      this.stopRun();
    }
  }

  processPose(landmarks: NormalizedLandmark[]): GradingResult {
    const formIssues = this.validateForm();
    this.updateFormScore(formIssues);
    
    return {
      state: this.state,
      repIncrement: 0,
      hasFormFault: formIssues.some(i => i.severity === 'critical'),
      formFault: this.lastFormIssue || undefined,
      formScore: this.isComplete ? this.currentFormScore : undefined
    };
  }

  protected getRequiredLandmarks(): number[] {
    return [];
  }

  protected updateState(landmarks: NormalizedLandmark[]): void {
  }

  protected validateForm(landmarks?: NormalizedLandmark[]): FormIssue[] {
    const issues: FormIssue[] = [];
    
    if (this.isRunning && this.gpsPositions.length > 5) {
      const avgPace = this.getAverageMovement();
      
      if (avgPace < this.runningConfig.minPaceMetersPerSecond!) {
        issues.push({
          severity: 'moderate',
          message: 'Pick up the pace - running too slow',
          joints: []
        });
      }
      
      if (avgPace > this.runningConfig.maxPaceMetersPerSecond!) {
        issues.push({
          severity: 'minor',
          message: 'Maintain a sustainable pace',
          joints: []
        });
      }
      
      if (this.elapsedTimeSeconds > this.runningConfig.maxDurationSeconds!) {
        issues.push({
          severity: 'critical',
          message: 'Time limit exceeded',
          joints: []
        });
      }
    }
    
    return issues;
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000;
    const phi1 = lat1 * Math.PI / 180;
    const phi2 = lat2 * Math.PI / 180;
    const deltaPhi = (lat2 - lat1) * Math.PI / 180;
    const deltaLambda = (lon2 - lon1) * Math.PI / 180;
    
    const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
              Math.cos(phi1) * Math.cos(phi2) *
              Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return R * c;
  }

  private calculateScore(): number {
    if (this.totalDistanceMeters < this.runningConfig.targetDistanceMeters! * 0.9) {
      return 0;
    }
    
    const normalizedTime = this.elapsedTimeSeconds * 
      (this.runningConfig.targetDistanceMeters! / this.totalDistanceMeters);
    
    return Math.max(0, Math.min(100, 100 - (normalizedTime - 720) / 10));
  }

  getAPFTScore(age: number, gender: 'male' | 'female'): number {
    if (!this.isComplete) return 0;
    
    const timeMinutes = Math.floor(this.elapsedTimeSeconds / 60);
    const timeSeconds = Math.round(this.elapsedTimeSeconds % 60);
    const totalSeconds = Math.round(this.elapsedTimeSeconds);
    
    return calculateRunningScore(totalSeconds);
  }

  getDistance(): number {
    return this.totalDistanceMeters;
  }

  getDuration(): number {
    return this.elapsedTimeSeconds;
  }

  getPacePerMile(): string {
    if (this.totalDistanceMeters === 0) return '00:00';
    
    const milesRun = this.totalDistanceMeters / RunningGrader.METERS_PER_MILE;
    const minutesPerMile = (this.elapsedTimeSeconds / 60) / milesRun;
    
    const minutes = Math.floor(minutesPerMile);
    const seconds = Math.round((minutesPerMile - minutes) * 60);
    
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  getProgress(): number {
    return Math.min(1, this.totalDistanceMeters / this.runningConfig.targetDistanceMeters!);
  }

  isRunComplete(): boolean {
    return this.isComplete;
  }

  getGPSPath(): GPSPosition[] {
    return this.gpsPositions;
  }
}