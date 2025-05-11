/**
 * Utility functions for mathematical calculations in exercise form analysis
 */

/**
 * Calculate the angle between three points in 2D space
 * Returns the angle in degrees
 * 
 * @param x1 X-coordinate of the first point (e.g., shoulder)
 * @param y1 Y-coordinate of the first point
 * @param x2 X-coordinate of the second point (e.g., elbow - the vertex)
 * @param y2 Y-coordinate of the second point
 * @param x3 X-coordinate of the third point (e.g., wrist)
 * @param y3 Y-coordinate of the third point
 * @returns Angle in degrees between the three points
 */
export function calculateAngle(
  x1: number, y1: number,
  x2: number, y2: number,
  x3: number, y3: number
): number {
  // Calculate vectors
  const vector1 = {
    x: x1 - x2,
    y: y1 - y2
  };
  
  const vector2 = {
    x: x3 - x2,
    y: y3 - y2
  };
  
  // Calculate dot product
  const dotProduct = vector1.x * vector2.x + vector1.y * vector2.y;
  
  // Calculate magnitudes
  const magnitude1 = Math.sqrt(vector1.x * vector1.x + vector1.y * vector1.y);
  const magnitude2 = Math.sqrt(vector2.x * vector2.x + vector2.y * vector2.y);
  
  // Calculate angle in radians and convert to degrees
  // Use Math.max/min to handle potential floating point errors that would cause acos to be out of bounds
  const cosine = Math.max(-1, Math.min(1, dotProduct / (magnitude1 * magnitude2)));
  const angleRadians = Math.acos(cosine);
  const angleDegrees = angleRadians * (180 / Math.PI);
  
  return angleDegrees;
}

/**
 * Calculate the Euclidean distance between two points in 2D space
 * 
 * @param x1 X-coordinate of the first point
 * @param y1 Y-coordinate of the first point
 * @param x2 X-coordinate of the second point
 * @param y2 Y-coordinate of the second point
 * @returns Euclidean distance between the points
 */
export function calculateDistance(
  x1: number, y1: number,
  x2: number, y2: number
): number {
  const dx = x2 - x1;
  const dy = y2 - y1;
  return Math.sqrt(dx * dx + dy * dy);
}

/**
 * Calculate the 3D angle between three points
 * Returns the angle in degrees
 * 
 * @param x1 X-coordinate of the first point
 * @param y1 Y-coordinate of the first point
 * @param z1 Z-coordinate of the first point
 * @param x2 X-coordinate of the second point (the vertex)
 * @param y2 Y-coordinate of the second point
 * @param z2 Z-coordinate of the second point
 * @param x3 X-coordinate of the third point
 * @param y3 Y-coordinate of the third point
 * @param z3 Z-coordinate of the third point
 * @returns Angle in degrees between the three points in 3D space
 */
export function calculate3DAngle(
  x1: number, y1: number, z1: number,
  x2: number, y2: number, z2: number,
  x3: number, y3: number, z3: number
): number {
  // Calculate vectors
  const vector1 = {
    x: x1 - x2,
    y: y1 - y2,
    z: z1 - z2
  };
  
  const vector2 = {
    x: x3 - x2,
    y: y3 - y2,
    z: z3 - z2
  };
  
  // Calculate dot product
  const dotProduct = vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z;
  
  // Calculate magnitudes
  const magnitude1 = Math.sqrt(vector1.x * vector1.x + vector1.y * vector1.y + vector1.z * vector1.z);
  const magnitude2 = Math.sqrt(vector2.x * vector2.x + vector2.y * vector2.y + vector2.z * vector2.z);
  
  // Calculate angle in radians and convert to degrees
  // Use Math.max/min to handle potential floating point errors that would cause acos to be out of bounds
  const cosine = Math.max(-1, Math.min(1, dotProduct / (magnitude1 * magnitude2)));
  const angleRadians = Math.acos(cosine);
  const angleDegrees = angleRadians * (180 / Math.PI);
  
  return angleDegrees;
}

/**
 * Calculate the 3D distance between two points
 * 
 * @param x1 X-coordinate of the first point
 * @param y1 Y-coordinate of the first point
 * @param z1 Z-coordinate of the first point
 * @param x2 X-coordinate of the second point
 * @param y2 Y-coordinate of the second point
 * @param z2 Z-coordinate of the second point
 * @returns Euclidean distance between the points in 3D space
 */
export function calculate3DDistance(
  x1: number, y1: number, z1: number,
  x2: number, y2: number, z2: number
): number {
  const dx = x2 - x1;
  const dy = y2 - y1;
  const dz = z2 - z1;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

/**
 * Linear interpolation between two values
 * 
 * @param a Start value
 * @param b End value
 * @param t Interpolation factor (0-1)
 * @returns Interpolated value
 */
export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/**
 * Maps a value from one range to another
 * 
 * @param value Value to map
 * @param inMin Input range minimum
 * @param inMax Input range maximum
 * @param outMin Output range minimum
 * @param outMax Output range maximum
 * @returns Mapped value
 */
export function mapRange(
  value: number, 
  inMin: number, 
  inMax: number, 
  outMin: number, 
  outMax: number
): number {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
} 