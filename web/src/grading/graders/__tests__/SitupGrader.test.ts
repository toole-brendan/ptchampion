import { describe, it, expect, beforeEach } from 'vitest';
import { SitupGrader } from '../SitupGrader';
import { NormalizedLandmark } from '@mediapipe/tasks-vision';
import { ExerciseType } from '../../ExerciseType';

// Helper function to create mock landmarks
function createMockLandmarks(overrides: Partial<Record<number, Partial<NormalizedLandmark>>> = {}): NormalizedLandmark[] {
  const landmarks: NormalizedLandmark[] = [];
  
  // Create 33 default landmarks
  for (let i = 0; i < 33; i++) {
    landmarks.push({
      x: 0.5,
      y: 0.5,
      z: 0,
      visibility: 1
    });
  }
  
  // Apply overrides
  Object.entries(overrides).forEach(([index, landmark]) => {
    landmarks[parseInt(index)] = { ...landmarks[parseInt(index)], ...landmark };
  });
  
  return landmarks;
}

describe('SitupGrader', () => {
  let grader: SitupGrader;

  beforeEach(() => {
    grader = new SitupGrader();
  });

  describe('initialization', () => {
    it('should initialize with zero reps', () => {
      expect(grader.getRepCount()).toBe(0);
    });

    it('should have correct exercise type', () => {
      expect(grader.exerciseType).toBe(ExerciseType.SITUP);
    });

    it('should start with 100% form score', () => {
      expect(grader.getFormScore()).toBe(100);
    });
  });

  describe('calibration', () => {
    it('should calibrate to user body in down position', () => {
      // Simulate user lying down
      const downPositionLandmarks = createMockLandmarks({
        11: { x: 0.4, y: 0.7 }, // left shoulder (on ground)
        12: { x: 0.6, y: 0.7 }, // right shoulder (on ground)
        23: { x: 0.4, y: 0.8 }, // left hip
        24: { x: 0.6, y: 0.8 }, // right hip
        25: { x: 0.4, y: 0.85 }, // left knee
        26: { x: 0.6, y: 0.85 }, // right knee
        27: { x: 0.4, y: 0.9 }, // left ankle
        28: { x: 0.6, y: 0.9 }, // right ankle
      });

      // Process calibration frames
      for (let i = 0; i < 10; i++) {
        grader.processPose(downPositionLandmarks);
      }

      // Should still have no reps during calibration
      expect(grader.getRepCount()).toBe(0);
    });
  });

  describe('rep counting', () => {
    it('should count a valid situp rep', () => {
      // Start in down position (shoulders on ground)
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 }, // left shoulder
        12: { x: 0.6, y: 0.7 }, // right shoulder
        13: { x: 0.35, y: 0.65 }, // left elbow
        14: { x: 0.65, y: 0.65 }, // right elbow
        23: { x: 0.4, y: 0.8 }, // left hip
        24: { x: 0.6, y: 0.8 }, // right hip
        25: { x: 0.4, y: 0.85 }, // left knee (90 degrees)
        26: { x: 0.6, y: 0.85 }, // right knee (90 degrees)
      });

      // Go to up position (torso vertical, elbows to knees)
      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 }, // left shoulder (raised)
        12: { x: 0.6, y: 0.5 }, // right shoulder (raised)
        13: { x: 0.35, y: 0.55 }, // left elbow (near knee)
        14: { x: 0.65, y: 0.55 }, // right elbow (near knee)
        23: { x: 0.4, y: 0.8 }, // left hip (stays on ground)
        24: { x: 0.6, y: 0.8 }, // right hip (stays on ground)
        25: { x: 0.4, y: 0.55 }, // left knee
        26: { x: 0.6, y: 0.55 }, // right knee
      });

      // Process the movement
      grader.processPose(downPosition);
      grader.processPose(upPosition);
      grader.processPose(downPosition);

      expect(grader.getRepCount()).toBe(1);
    });

    it('should not count incomplete reps', () => {
      // Start in down position
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
      });

      // Go to partial up position (not high enough)
      const partialUpPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.6 }, // shoulders only partially raised
        12: { x: 0.6, y: 0.6 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
      });

      grader.processPose(downPosition);
      grader.processPose(partialUpPosition);
      grader.processPose(downPosition);

      expect(grader.getRepCount()).toBe(0);
    });

    it('should handle multiple consecutive reps', () => {
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        13: { x: 0.35, y: 0.65 },
        14: { x: 0.65, y: 0.65 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.85 },
        26: { x: 0.6, y: 0.85 },
      });

      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 },
        12: { x: 0.6, y: 0.5 },
        13: { x: 0.35, y: 0.55 },
        14: { x: 0.65, y: 0.55 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.55 },
        26: { x: 0.6, y: 0.55 },
      });

      // Do 3 situps
      for (let i = 0; i < 3; i++) {
        grader.processPose(downPosition);
        grader.processPose(upPosition);
        grader.processPose(downPosition);
      }

      expect(grader.getRepCount()).toBe(3);
    });
  });

  describe('form detection', () => {
    it('should detect incorrect knee angle', () => {
      const straightLegsPosition = createMockLandmarks({
        23: { x: 0.4, y: 0.8 }, // left hip
        24: { x: 0.6, y: 0.8 }, // right hip
        25: { x: 0.4, y: 0.88 }, // left knee (too straight)
        26: { x: 0.6, y: 0.88 }, // right knee (too straight)
        27: { x: 0.4, y: 0.95 }, // left ankle
        28: { x: 0.6, y: 0.95 }, // right ankle
      });

      const result = grader.processPose(straightLegsPosition);
      expect(result.formFault).toContain('knee');
    });

    it('should detect hip lifting', () => {
      const hipLiftPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 }, // left shoulder (up)
        12: { x: 0.6, y: 0.5 }, // right shoulder (up)
        23: { x: 0.4, y: 0.65 }, // left hip (lifted off ground)
        24: { x: 0.6, y: 0.65 }, // right hip (lifted off ground)
      });

      const result = grader.processPose(hipLiftPosition);
      expect(result.formFault).toContain('hip');
    });

    it('should detect hands not behind head', () => {
      const handsDownPosition = createMockLandmarks({
        15: { x: 0.3, y: 0.7 }, // left wrist (too low)
        16: { x: 0.7, y: 0.7 }, // right wrist (too low)
        11: { x: 0.4, y: 0.5 }, // left shoulder
        12: { x: 0.6, y: 0.5 }, // right shoulder
        0: { x: 0.5, y: 0.4 }, // nose/head
      });

      const result = grader.processPose(handsDownPosition);
      expect(result.formFault).toContain('hands');
    });

    it('should maintain form score across workout', () => {
      // Good form situp
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        15: { x: 0.45, y: 0.35 }, // hands behind head
        16: { x: 0.55, y: 0.35 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.85 },
        26: { x: 0.6, y: 0.85 },
        0: { x: 0.5, y: 0.4 }, // head
      });

      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 },
        12: { x: 0.6, y: 0.5 },
        15: { x: 0.45, y: 0.45 }, // hands still behind head
        16: { x: 0.55, y: 0.45 },
        13: { x: 0.35, y: 0.55 },
        14: { x: 0.65, y: 0.55 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.55 },
        26: { x: 0.6, y: 0.55 },
        0: { x: 0.5, y: 0.5 }, // head
      });

      // Do a good situp
      grader.processPose(downPosition);
      grader.processPose(upPosition);
      grader.processPose(downPosition);

      // Form score should still be high
      expect(grader.getFormScore()).toBeGreaterThan(95);
    });
  });

  describe('APFT scoring', () => {
    it('should calculate correct APFT score for male age 22', () => {
      // Set user info
      grader.setUserInfo({ age: 22, gender: 'male' });

      // Simulate 60 situps
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
      });

      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 },
        12: { x: 0.6, y: 0.5 },
        13: { x: 0.35, y: 0.55 },
        14: { x: 0.65, y: 0.55 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.55 },
        26: { x: 0.6, y: 0.55 },
      });

      // Do 60 situps
      for (let i = 0; i < 60; i++) {
        grader.processPose(downPosition);
        grader.processPose(upPosition);
        grader.processPose(downPosition);
      }

      const score = grader.getAPFTScore();
      expect(score).toBeGreaterThan(85); // 60 situps should be > 85 points
    });

    it('should calculate correct APFT score for female age 25', () => {
      // Set user info
      grader.setUserInfo({ age: 25, gender: 'female' });

      // Simulate 50 situps
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
      });

      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 },
        12: { x: 0.6, y: 0.5 },
        13: { x: 0.35, y: 0.55 },
        14: { x: 0.65, y: 0.55 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.55 },
        26: { x: 0.6, y: 0.55 },
      });

      // Do 50 situps
      for (let i = 0; i < 50; i++) {
        grader.processPose(downPosition);
        grader.processPose(upPosition);
        grader.processPose(downPosition);
      }

      const score = grader.getAPFTScore();
      expect(score).toBeGreaterThan(80); // 50 situps for female should be > 80 points
    });
  });

  describe('edge cases', () => {
    it('should handle missing landmarks gracefully', () => {
      const incompleteLandmarks = createMockLandmarks();
      // Set some landmarks to low visibility
      incompleteLandmarks[11].visibility = 0.1;
      incompleteLandmarks[12].visibility = 0.1;

      const result = grader.processPose(incompleteLandmarks);
      expect(result.state).toBeDefined();
      expect(grader.getRepCount()).toBe(0);
    });

    it('should reset properly', () => {
      // Do a situp
      const downPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.7 },
        12: { x: 0.6, y: 0.7 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
      });

      const upPosition = createMockLandmarks({
        11: { x: 0.4, y: 0.5 },
        12: { x: 0.6, y: 0.5 },
        13: { x: 0.35, y: 0.55 },
        14: { x: 0.65, y: 0.55 },
        23: { x: 0.4, y: 0.8 },
        24: { x: 0.6, y: 0.8 },
        25: { x: 0.4, y: 0.55 },
        26: { x: 0.6, y: 0.55 },
      });

      grader.processPose(downPosition);
      grader.processPose(upPosition);
      grader.processPose(downPosition);
      
      expect(grader.getRepCount()).toBe(1);

      // Reset
      grader.reset();

      expect(grader.getRepCount()).toBe(0);
      expect(grader.getFormScore()).toBe(100);
      expect(grader.getAPFTScore()).toBe(0);
    });
  });
});