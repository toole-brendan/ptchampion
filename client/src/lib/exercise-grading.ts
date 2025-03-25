// Exercise grading utilities

/**
 * Calculates pushup grade based on reps
 * - 100 points = 71 reps
 * - 50 points = 35 reps
 * @param reps Number of pushups completed
 * @returns Score from 0-100
 */
export function calculatePushupGrade(reps: number): number {
  if (reps <= 0) return 0;
  if (reps >= 71) return 100;
  
  // Linear interpolation between key points
  if (reps <= 35) {
    // Scale 0-35 reps to 0-50 points
    return Math.round((reps / 35) * 50);
  } else {
    // Scale 36-71 reps to 51-100 points
    return Math.round(50 + ((reps - 35) / 36) * 50);
  }
}

/**
 * Calculates situp grade based on reps
 * - 100 points = 78 reps
 * - 50 points = 47 reps
 * @param reps Number of situps completed
 * @returns Score from 0-100
 */
export function calculateSitupGrade(reps: number): number {
  if (reps <= 0) return 0;
  if (reps >= 78) return 100;
  
  // Linear interpolation between key points
  if (reps <= 47) {
    // Scale 0-47 reps to 0-50 points
    return Math.round((reps / 47) * 50);
  } else {
    // Scale 48-78 reps to 51-100 points
    return Math.round(50 + ((reps - 47) / 31) * 50);
  }
}

/**
 * Calculates pullup grade based on reps
 * - 100 points = 20 reps
 * - 50 points = 8 reps
 * @param reps Number of pullups completed
 * @returns Score from 0-100
 */
export function calculatePullupGrade(reps: number): number {
  if (reps <= 0) return 0;
  if (reps >= 20) return 100;
  
  // Linear interpolation between key points
  if (reps <= 8) {
    // Scale 0-8 reps to 0-50 points
    return Math.round((reps / 8) * 50);
  } else {
    // Scale 9-20 reps to 51-100 points
    return Math.round(50 + ((reps - 8) / 12) * 50);
  }
}

/**
 * Calculates 2-mile run grade based on time in seconds
 * - 100 points = 13:00 (780 seconds) or less
 * - 50 points = 16:36 (996 seconds)
 * @param timeInSeconds Time in seconds to complete 2-mile run
 * @returns Score from 0-100
 */
export function calculateRunGrade(timeInSeconds: number): number {
  if (timeInSeconds <= 0) return 0;
  
  // Convert times to seconds
  const maxScoreTime = 13 * 60; // 13:00 in seconds (780)
  const midScoreTime = 16 * 60 + 36; // 16:36 in seconds (996)
  const maxTime = 22 * 60; // 22:00 in seconds (1320) - set an upper limit
  
  if (timeInSeconds <= maxScoreTime) return 100;
  if (timeInSeconds >= maxTime) return 0;
  
  // Linear interpolation between key points
  if (timeInSeconds <= midScoreTime) {
    // Scale 780-996 seconds to 100-50 points (note: inverted scale - less time is better)
    const timeRange = midScoreTime - maxScoreTime;
    const pointRange = 50; // 100 to 50
    return Math.round(100 - ((timeInSeconds - maxScoreTime) / timeRange) * pointRange);
  } else {
    // Scale 997-1320 seconds to 49-0 points
    const timeRange = maxTime - midScoreTime;
    const pointRange = 50; // 50 to 0
    return Math.round(50 - ((timeInSeconds - midScoreTime) / timeRange) * pointRange);
  }
}

/**
 * Gets a textual rating based on a numeric score
 * @param score Numeric score 0-100
 * @returns Text rating
 */
export function getScoreRating(score: number): string {
  if (score >= 90) return "Outstanding";
  if (score >= 80) return "Excellent";
  if (score >= 65) return "Good";
  if (score >= 50) return "Satisfactory";
  if (score >= 40) return "Marginal";
  return "Unsatisfactory";
}

/**
 * Calculates overall fitness score from individual exercise scores
 * @param scores Object containing individual exercise scores
 * @returns Overall score 0-100
 */
export function calculateOverallScore(scores: {
  pushupScore?: number;
  situpScore?: number;
  pullupScore?: number;
  runScore?: number;
}): number {
  const { pushupScore, situpScore, pullupScore, runScore } = scores;
  
  let totalScore = 0;
  let count = 0;
  
  if (pushupScore !== undefined) {
    totalScore += pushupScore;
    count++;
  }
  
  if (situpScore !== undefined) {
    totalScore += situpScore;
    count++;
  }
  
  if (pullupScore !== undefined) {
    totalScore += pullupScore;
    count++;
  }
  
  if (runScore !== undefined) {
    totalScore += runScore;
    count++;
  }
  
  return count > 0 ? Math.round(totalScore / count) : 0;
}