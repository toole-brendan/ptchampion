/**
 * APFT (Army Physical Fitness Test) Scoring Logic
 * Based on Army standards for the 17-21 male age group
 */

// Push-Up Score Table
export const pushupScoreTable = {
  68: 100,
  67: 99,
  66: 97,
  65: 96,
  64: 94,
  63: 93,
  62: 91,
  61: 90,
  60: 88,
  59: 87,
  58: 85,
  57: 84,
  56: 82,
  55: 81,
  54: 79,
  53: 78,
  52: 76,
  51: 75,
  50: 74,
  49: 72,
  48: 71,
  47: 69,
  46: 68,
  45: 66,
  44: 65,
  43: 63,
  42: 62,
  41: 60,
  40: 59,
  39: 57,
  38: 56,
  37: 54,
  36: 53,
  35: 51,
  34: 50,
  33: 48,
  32: 47,
  31: 46,
  30: 44,
  29: 43,
  28: 41,
  27: 40,
  26: 38,
  25: 37,
  24: 35,
  23: 34,
  22: 32,
  21: 31,
  20: 29,
  19: 28,
  18: 26,
  17: 25,
  16: 24,
  15: 22,
  14: 21,
  13: 19,
  12: 18,
  11: 16,
  10: 15,
   9: 13,
   8: 12,
   7: 10,
   6:  9,
   5:  7,
   4:  6,
   3:  4,
   2:  3,
   1:  1,
   0:  0
};

// Sit-Up Score Table
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

// Pull-Up Score Table  (25 reps = 100 pts → 0 reps = 0 pts)
export const pullupScoreTable = {
  25: 100,
  24:  96,
  23:  92,
  22:  88,
  21:  84,
  20:  80,
  19:  76,
  18:  72,
  17:  68,
  16:  64,
  15:  60,
  14:  56,
  13:  52,
  12:  48,
  11:  44,
  10:  40,
   9:  36,
   8:  32,
   7:  28,
   6:  24,
   5:  20,
   4:  16,
   3:  12,
   2:   8,
   1:   4,
   0:   0
};

// Running Score Table (time in seconds → points)
// 11:00 = 660 s, 19:30 = 1170 s
export const runningScoreTable: Record<number, number> = {
  660: 100, // 11:00
  666:  99, // 11:06
  672:  98, // 11:12
  678:  96, // 11:18
  684:  95, // 11:24
  690:  94, // 11:30
  696:  93, // 11:36
  702:  92, // 11:42
  708:  91, // 11:48
  714:  89, // 11:54
  720:  88, // 12:00
  726:  87, // 12:06
  732:  86, // 12:12
  738:  85, // 12:18
  744:  84, // 12:24
  750:  82, // 12:30
  756:  81, // 12:36
  762:  80, // 12:42
  768:  79, // 12:48
  774:  78, // 12:54
  780:  76, // 13:00
  786:  75, // 13:06
  792:  74, // 13:12
  798:  73, // 13:18
  804:  72, // 13:24
  810:  71, // 13:30
  816:  69, // 13:36
  822:  68, // 13:42
  828:  67, // 13:48
  834:  66, // 13:54
  840:  64, // 14:00
  846:  63, // 14:06
  852:  62, // 14:12
  858:  61, // 14:18
  864:  60, // 14:24
  870:  59, // 14:30
  876:  57, // 14:36
  882:  56, // 14:42
  888:  55, // 14:48
  894:  54, // 14:54
  900:  53, // 15:00
  906:  51, // 15:06
  912:  50, // 15:12
  918:  49, // 15:18
  924:  48, // 15:24
  930:  47, // 15:30
  936:  45, // 15:36
  942:  44, // 15:42
  948:  43, // 15:48
  954:  42, // 15:54
  960:  41, // 16:00
  966:  39, // 16:06
  972:  38, // 16:12
  978:  37, // 16:18
  984:  36, // 16:24
  990:  35, // 16:30
  996:  33, // 16:36
 1002:  32, // 16:42
 1008:  31, // 16:48
 1014:  30, // 16:54
 1020:  29, // 17:00
 1026:  28, // 17:06
 1032:  27, // 17:12
 1038:  26, // 17:18
 1044:  24, // 17:24
 1050:  23, // 17:30
 1056:  22, // 17:36
 1062:  21, // 17:42
 1068:  20, // 17:48
 1074:  19, // 17:54
 1080:  18, // 18:00
 1086:  16, // 18:06
 1092:  15, // 18:12
 1098:  14, // 18:18
 1104:  13, // 18:24
 1110:  12, // 18:30
 1116:  11, // 18:36
 1122:  10, // 18:42
 1128:   9, // 18:48
 1134:   8, // 18:54
 1140:   6, // 19:00
 1146:   5, // 19:06
 1152:   4, // 19:12
 1158:   3, // 19:18
 1164:   2, // 19:24
 1170:   0  // 19:30
  // Any time > 19:30 also yields 0 points
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
 * Calculate running score based on time in seconds
 * @param timeInSeconds - Time to complete two-mile run in seconds
 * @returns Score between 0-100
 */
export function calculateRunningScore(timeInSeconds: number): number {
  const times = Object.keys(runningScoreTable).map(Number).sort((a, b) => a - b);
  
  // If faster than the fastest time in the table (780 seconds)
  if (timeInSeconds <= times[0]) {
    return runningScoreTable[times[0].toString() as unknown as number];
  }
  
  // If slower than the slowest time in the table (1218 seconds)
  if (timeInSeconds >= times[times.length - 1]) {
    return runningScoreTable[times[times.length - 1].toString() as unknown as number];
  }
  
  // Find exact match
  if (runningScoreTable[timeInSeconds] !== undefined) {
    return runningScoreTable[timeInSeconds];
  }
  
  // Find the closest time that is less than or equal to the given time
  let bestMatch = times[times.length - 1]; // Default to slowest time
  
  for (let i = 0; i < times.length; i++) {
    const time = times[i];
    if (timeInSeconds < time) {
      if (i > 0) {
        bestMatch = times[i - 1];
      }
      break;
    }
  }
  
  return runningScoreTable[bestMatch];
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

/**
 * Format running score for display
 * @param timeInSeconds - Time in seconds
 * @param score - Calculated score points
 * @returns Formatted string like "15:30 → 66 points"
 */
export function formatRunningScoreDisplay(timeInSeconds: number, score: number): string {
  const minutes = Math.floor(timeInSeconds / 60);
  const seconds = timeInSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, '0')} → ${score} points`;
} 