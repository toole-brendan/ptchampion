/**
 * PoseLandmarkIndex
 * 
 * Enum to provide semantic names for MediaPipe pose landmark indices.
 * This mirrors the iOS PoseLandmarkIndex for consistent naming across platforms.
 */

export enum PoseLandmarkIndex {
  NOSE = 0,
  LEFT_EYE_INNER = 1,
  LEFT_EYE = 2,
  LEFT_EYE_OUTER = 3,
  RIGHT_EYE_INNER = 4,
  RIGHT_EYE = 5,
  RIGHT_EYE_OUTER = 6,
  LEFT_EAR = 7,
  RIGHT_EAR = 8,
  MOUTH_LEFT = 9,
  MOUTH_RIGHT = 10,
  LEFT_SHOULDER = 11,
  RIGHT_SHOULDER = 12,
  LEFT_ELBOW = 13,
  RIGHT_ELBOW = 14,
  LEFT_WRIST = 15,
  RIGHT_WRIST = 16,
  LEFT_PINKY = 17,
  RIGHT_PINKY = 18,
  LEFT_INDEX = 19,
  RIGHT_INDEX = 20,
  LEFT_THUMB = 21,
  RIGHT_THUMB = 22,
  LEFT_HIP = 23,
  RIGHT_HIP = 24,
  LEFT_KNEE = 25,
  RIGHT_KNEE = 26,
  LEFT_ANKLE = 27,
  RIGHT_ANKLE = 28,
  LEFT_HEEL = 29,
  RIGHT_HEEL = 30,
  LEFT_FOOT_INDEX = 31,
  RIGHT_FOOT_INDEX = 32
}

/**
 * Helper function to calculate angle between three points
 * This can be used to measure joint angles
 */
export function calculateAngle(
  a: { x: number; y: number },
  b: { x: number; y: number },
  c: { x: number; y: number }
): number {
  try {
    const v1 = { x: a.x - b.x, y: a.y - b.y };
    const v2 = { x: c.x - b.x, y: c.y - b.y };
    
    // Calculate dot product
    const dot = v1.x * v2.x + v1.y * v2.y;
    
    // Calculate cross product (in 2D)
    const det = v1.x * v2.y - v1.y * v2.x;
    
    // Calculate angle
    const angleRad = Math.atan2(Math.abs(det), dot);
    let angleDeg = angleRad * (180 / Math.PI);
    
    // Normalize to 0-180 range
    angleDeg = Math.max(0, Math.min(180, angleDeg));
    
    return angleDeg;
  } catch (error) {
    console.error("Error calculating angle:", error);
    return 180; // Return neutral angle on error
  }
}

/**
 * Helper function to calculate distance between two points
 */
export function calculateDistance(
  a: { x: number; y: number },
  b: { x: number; y: number }
): number {
  return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
}

export default PoseLandmarkIndex; 