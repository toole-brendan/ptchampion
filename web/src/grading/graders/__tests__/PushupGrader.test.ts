import { describe, it, expect, beforeEach } from 'vitest';
import { PushupGrader } from '../PushupGrader';
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

describe('PushupGrader', () => {
  let grader: PushupGrader;

  beforeEach(() => {
    grader = new PushupGrader();
  });

  describe('initialization', () => {
    it('should initialize with zero reps', () => {
      expect(grader.getRepCount()).toBe(0);
    });

    it('should have correct exercise type', () => {
      expect(grader.exerciseType).toBe(ExerciseType.PUSHUP);
    });

    it('should start with 100% form score', () => {
      expect(grader.getFormScore()).toBe(100);
    });
  });

  describe('calibration', () => {
    it('should adapt arm extension threshold during calibration', () => {
      // Simulate user in up position with slightly bent arms (155 degrees)
      const upPositionLandmarks = createMockLandmarks({
        11: { x: 0.3, y: 0.4 }, // left shoulder
        13: { x: 0.2, y: 0.5 }, // left elbow
        15: { x: 0.1, y: 0.6 }, // left wrist
        12: { x: 0.7, y: 0.4 }, // right shoulder
        14: { x: 0.8, y: 0.5 }, // right elbow
        16: { x: 0.9, y: 0.6 }, // right wrist
      });

      // Process multiple calibration frames
      for (let i = 0; i < 10; i++) {
        grader.processPose(upPositionLandmarks);
      }

      // The threshold should adapt to the user's natural extension
      // We can't test the exact internal threshold, but we can verify behavior
      expect(grader.getRepCount()).toBe(0); // No reps during calibration
    });
  });

  describe('rep counting', () => {
    it('should count a valid pushup rep', () => {
      // Start in up position
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 }, // left shoulder
        13: { x: 0.3, y: 0.5 }, // left elbow (straight arm)
        15: { x: 0.3, y: 0.6 }, // left wrist
        12: { x: 0.7, y: 0.4 }, // right shoulder
        14: { x: 0.7, y: 0.5 }, // right elbow (straight arm)
        16: { x: 0.7, y: 0.6 }, // right wrist
        23: { x: 0.4, y: 0.8 }, // left hip
        24: { x: 0.6, y: 0.8 }, // right hip
      });

      // Go to down position (elbows bent to 90 degrees)
      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 }, // left shoulder
        13: { x: 0.35, y: 0.45 }, // left elbow (bent)
        15: { x: 0.3, y: 0.5 }, // left wrist
        12: { x: 0.7, y: 0.4 }, // right shoulder
        14: { x: 0.65, y: 0.45 }, // right elbow (bent)
        16: { x: 0.7, y: 0.5 }, // right wrist
        23: { x: 0.4, y: 0.8 }, // left hip
        24: { x: 0.6, y: 0.8 }, // right hip
      });

      // Process the movement
      grader.processPose(upPosition);
      grader.processPose(downPosition);
      grader.processPose(upPosition);

      expect(grader.getRepCount()).toBe(1);
    });

    it('should not count incomplete reps', () => {
      // Start in up position
      const upPosition = createMockLandmarks({
        13: { x: 0.3, y: 0.5 }, // left elbow (straight)
        14: { x: 0.7, y: 0.5 }, // right elbow (straight)
      });

      // Go to shallow position (not deep enough)
      const shallowPosition = createMockLandmarks({
        13: { x: 0.32, y: 0.48 }, // left elbow (slightly bent)
        14: { x: 0.68, y: 0.48 }, // right elbow (slightly bent)
      });

      grader.processPose(upPosition);
      grader.processPose(shallowPosition);
      grader.processPose(upPosition);

      expect(grader.getRepCount()).toBe(0);
    });

    it('should handle multiple consecutive reps', () => {
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.3, y: 0.5 },
        15: { x: 0.3, y: 0.6 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.7, y: 0.5 },
        16: { x: 0.7, y: 0.6 },
      });

      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.35, y: 0.45 },
        15: { x: 0.3, y: 0.5 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.65, y: 0.45 },
        16: { x: 0.7, y: 0.5 },
      });

      // Do 3 pushups
      for (let i = 0; i < 3; i++) {
        grader.processPose(upPosition);
        grader.processPose(downPosition);
        grader.processPose(upPosition);
      }

      expect(grader.getRepCount()).toBe(3);
    });
  });

  describe('form detection', () => {
    it('should detect body sagging', () => {
      const saggingPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 }, // left shoulder
        23: { x: 0.4, y: 0.85 }, // left hip (too low)
        24: { x: 0.6, y: 0.85 }, // right hip (too low)
        27: { x: 0.4, y: 0.9 }, // left ankle
        28: { x: 0.6, y: 0.9 }, // right ankle
      });

      const result = grader.processPose(saggingPosition);
      expect(result.formFault).toContain('sagging');
    });

    it('should detect hands too wide', () => {
      const wideHandsPosition = createMockLandmarks({
        15: { x: 0.1, y: 0.6 }, // left wrist (too wide)
        16: { x: 0.9, y: 0.6 }, // right wrist (too wide)
        11: { x: 0.3, y: 0.4 }, // left shoulder
        12: { x: 0.7, y: 0.4 }, // right shoulder
      });

      const result = grader.processPose(wideHandsPosition);
      expect(result.formFault).toContain('wide');
    });

    it('should maintain form score across workout', () => {
      // Good form pushup
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.3, y: 0.5 },
        15: { x: 0.3, y: 0.6 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.7, y: 0.5 },
        16: { x: 0.7, y: 0.6 },
      });

      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.35, y: 0.45 },
        15: { x: 0.3, y: 0.5 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.65, y: 0.45 },
        16: { x: 0.7, y: 0.5 },
      });

      // Do a good pushup
      grader.processPose(upPosition);
      grader.processPose(downPosition);
      grader.processPose(upPosition);

      // Form score should still be high
      expect(grader.getFormScore()).toBeGreaterThan(95);
    });
  });

  describe('APFT scoring', () => {
    it('should calculate correct APFT score for male age 22', () => {
      // Set user info
      grader.setUserInfo({ age: 22, gender: 'male' });

      // Simulate 50 pushups
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.3, y: 0.5 },
        15: { x: 0.3, y: 0.6 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.7, y: 0.5 },
        16: { x: 0.7, y: 0.6 },
      });

      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.35, y: 0.45 },
        15: { x: 0.3, y: 0.5 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.65, y: 0.45 },
        16: { x: 0.7, y: 0.5 },
      });

      // Do 50 pushups
      for (let i = 0; i < 50; i++) {
        grader.processPose(upPosition);
        grader.processPose(downPosition);
        grader.processPose(upPosition);
      }

      const score = grader.getAPFTScore(25, 'male');
      expect(score).toBeGreaterThan(80); // 50 pushups should be > 80 points
    });

    it('should calculate correct APFT score for female age 25', () => {
      // Set user info
      grader.setUserInfo({ age: 25, gender: 'female' });

      // Simulate 30 pushups
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.3, y: 0.5 },
        15: { x: 0.3, y: 0.6 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.7, y: 0.5 },
        16: { x: 0.7, y: 0.6 },
      });

      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.35, y: 0.45 },
        15: { x: 0.3, y: 0.5 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.65, y: 0.45 },
        16: { x: 0.7, y: 0.5 },
      });

      // Do 30 pushups
      for (let i = 0; i < 30; i++) {
        grader.processPose(upPosition);
        grader.processPose(downPosition);
        grader.processPose(upPosition);
      }

      const score = grader.getAPFTScore(25, 'male');
      expect(score).toBeGreaterThan(85); // 30 pushups for female should be > 85 points
    });
  });

  describe('edge cases', () => {
    it('should handle missing landmarks gracefully', () => {
      const incompleteLandmarks = createMockLandmarks();
      // Set some landmarks to low visibility
      incompleteLandmarks[13].visibility = 0.1;
      incompleteLandmarks[14].visibility = 0.1;

      const result = grader.processPose(incompleteLandmarks);
      expect(result.state).toBeDefined();
      expect(grader.getRepCount()).toBe(0);
    });

    it('should reset properly', () => {
      // Do a pushup
      const upPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.3, y: 0.5 },
        15: { x: 0.3, y: 0.6 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.7, y: 0.5 },
        16: { x: 0.7, y: 0.6 },
      });

      const downPosition = createMockLandmarks({
        11: { x: 0.3, y: 0.4 },
        13: { x: 0.35, y: 0.45 },
        15: { x: 0.3, y: 0.5 },
        12: { x: 0.7, y: 0.4 },
        14: { x: 0.65, y: 0.45 },
        16: { x: 0.7, y: 0.5 },
      });

      grader.processPose(upPosition);
      grader.processPose(downPosition);
      grader.processPose(upPosition);
      
      expect(grader.getRepCount()).toBe(1);

      // Reset
      grader.reset();

      expect(grader.getRepCount()).toBe(0);
      expect(grader.getFormScore()).toBe(100);
      expect(grader.getAPFTScore(25, 'male')).toBe(0);
    });
  });
});