/**
 * APFT (Army Physical Fitness Test) Scoring Logic
 * Based on Army standards for the 17-21 male age group
 */

// Push-Up Score Table (17-21 Male)
export const pushupScoreTable = {
  0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10,
  11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19, 20: 20,
  21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29, 30: 30,
  31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39, 40: 40,
  41: 50, 42: 60, 43: 61, 44: 62, 45: 63, 46: 64, 47: 65, 48: 66, 49: 67, 50: 68,
  51: 69, 52: 70, 53: 71, 54: 72, 55: 73, 56: 74, 57: 75, 58: 76, 59: 77, 60: 78,
  61: 79, 62: 80, 63: 81, 64: 82, 65: 83, 66: 84, 67: 85, 68: 86, 69: 87, 70: 88,
  71: 89, 72: 90, 73: 91, 74: 92, 75: 93, 76: 94, 77: 100
};

// Sit-Up Score Table (17-21 Male)
export const situpScoreTable = {
  0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10,
  11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19, 20: 20,
  21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29, 30: 30,
  31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39, 40: 40,
  41: 41, 42: 42, 43: 43, 44: 44, 45: 45, 46: 46, 47: 47, 48: 48, 49: 49, 50: 50,
  51: 52, 52: 58, 53: 60, 54: 62, 55: 64, 56: 66, 57: 68, 58: 70, 59: 72, 60: 74,
  61: 76, 62: 78, 63: 80, 64: 82, 65: 84, 66: 86, 67: 88, 68: 90, 69: 91, 70: 92,
  71: 93, 72: 94, 73: 95, 74: 96, 75: 97, 76: 98, 77: 99, 78: 100
};

// Pull-Up Score Table (Custom scale)
export const pullupScoreTable = {
  0: 0, 1: 30, 2: 34, 3: 38, 4: 42, 5: 46,
  6: 50, 7: 52, 8: 54, 9: 56, 10: 60,
  11: 64, 12: 68, 13: 72, 14: 76, 15: 80,
  16: 84, 17: 88, 18: 92, 19: 96, 20: 100
};

/**
 * Calculate score from reps using the specified scoring table
 * @param reps - Number of valid repetitions completed
 * @param table - Scoring table to use
 * @returns The point score (0-100)
 */
export function getScore(reps: number, table: Record<number, number>): number {
  const maxRep = Math.max(...Object.keys(table).map(Number));
  
  // If reps is greater than or equal to the maximum in the table, return maximum score
  if (reps >= maxRep) return table[maxRep];
  
  // Direct lookup if the exact rep count exists in the table
  if (table[reps] !== undefined) return table[reps];

  // Fallback: find the closest lower rep count
  let r = reps;
  while (r >= 0 && table[r] === undefined) r--;
  return r >= 0 ? table[r] : 0;
}

/**
 * Calculate pushup score
 * @param reps - Number of valid pushups
 * @returns Score between 0-100
 */
export function calculatePushupScore(reps: number): number {
  return getScore(reps, pushupScoreTable);
}

/**
 * Calculate situp score
 * @param reps - Number of valid situps
 * @returns Score between 0-100
 */
export function calculateSitupScore(reps: number): number {
  return getScore(reps, situpScoreTable);
}

/**
 * Calculate pullup score
 * @param reps - Number of valid pullups
 * @returns Score between 0-100
 */
export function calculatePullupScore(reps: number): number {
  return getScore(reps, pullupScoreTable);
}

/**
 * Format score for display
 * @param reps - Number of valid repetitions
 * @param score - Calculated score points
 * @returns Formatted string like "48 reps → 68 points"
 */
export function formatScoreDisplay(reps: number, score: number): string {
  return `${reps} reps → ${score} points`;
} 