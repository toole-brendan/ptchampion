import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"
import { calculateRunningScore } from "../grading/APFTScoring"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Calculates the score (0-100 points) for an exercise based on performance.
 * @param exerciseType The type of exercise ('pushup', 'situp', 'pullup', 'run')
 * @param performanceValue Reps for strength exercises, time in seconds for run
 * @returns Score between 0-100
 */
export function calculateScore(exerciseType: string, performanceValue: number): number {
  let score = 0;
  
  switch (exerciseType.toLowerCase()) {
    case 'push-up':
    case 'pushup':
      score = calculatePushupScore(performanceValue);
      break;
    case 'sit-up':
    case 'situp':
      score = calculateSitupScore(performanceValue);
      break;
    case 'pull-up':
    case 'pullup':
      score = calculatePullupScore(performanceValue);
      break;
    case 'run':
    case '2-mile run':
      score = calculateRunScore(performanceValue);
      break;
    default:
      score = 0;
  }
  
  // Clamp score between 0 and 100
  return Math.max(0, Math.min(100, Math.round(score)));
}

// --- APFT-Inspired Push-up Scoring --- 

// Based on APFT standards (e.g., FM 7-22, 17-21 Male), provides a non-linear base score.
const apftPushupTable: ReadonlyArray<[number, number]> = [
  [0, 0], [5, 10], [6, 11], [7, 13], [8, 14], [9, 16], [10, 20],
  [11, 21], [12, 23], [13, 24], [14, 26], [15, 30], [16, 31], [17, 33],
  [18, 34], [19, 36], [20, 40], [21, 41], [22, 42], [23, 44], [24, 45],
  [25, 50], [26, 51], [27, 52], [28, 54], [29, 55], [30, 56], [31, 57],
  [32, 58], [33, 59], [34, 59], [35, 60], // 35 reps = 60 base points
  [36, 61], [37, 62], [38, 63], [39, 64], [40, 65], [41, 66], [42, 67],
  [43, 68], [44, 69], [45, 71], [46, 72], [47, 73], [48, 74], [49, 75],
  [50, 77], [51, 78], [52, 79], [53, 80], [54, 81], [55, 83], [56, 84],
  [57, 85], [58, 86], [59, 87], [60, 90], [61, 91], [62, 92], [63, 93],
  [64, 94], [65, 95], [66, 96], [67, 97], [68, 98], [69, 98], [70, 99], 
  [71, 100] // 71 reps = 100 base points
];

/**
 * Gets the base APFT score for a given number of push-up reps using discrete lookup.
 * @param reps Number of push-ups performed.
 * @returns The corresponding base score (0-100) based on the table.
 */
function getApftPushupScore(reps: number): number {
    if (reps <= 0) return 0;
    const maxReps = apftPushupTable[apftPushupTable.length - 1][0];
    if (reps >= maxReps) return 100;

    let score = 0;
    // Find the highest score bracket the reps fall into or exceed
    for (const [tableReps, tableScore] of apftPushupTable) {
        if (reps >= tableReps) {
            score = tableScore;
        } else {
            // Since the table is sorted, once we pass the rep count, we stop
            break;
        }
    }
    return score;
}

/**
 * Calculates the final Push-up score (0-100) using a scaled APFT-based non-linear curve.
 * Uses 35 reps = 50 points and 71 reps = 100 points as anchors.
 * @param reps Number of push-ups.
 * @returns Scaled score (0-100).
 */
function calculatePushupScore(reps: number): number {
  if (reps <= 0) return 0;
  
  const maxRepsFor100 = 71; // Reps needed for 100 points
  const repsFor50 = 35;      // Reps needed for 50 points
  const baseScoreAt50Reps = 60; // The APFT score corresponding to 35 reps
  const baseScoreAt100Reps = 100; // The APFT score corresponding to 71 reps

  if (reps >= maxRepsFor100) return 100;

  // Get the base score from the APFT-like table
  const baseApftScore = getApftPushupScore(reps);

  let finalScore = 0;

  if (reps <= repsFor50) {
    // Scale the 0-60 base score range to 0-50 final score range
    // Avoid division by zero if baseScoreAt50Reps was 0
    const scaleFactor = baseScoreAt50Reps > 0 ? 50 / baseScoreAt50Reps : 0;
    finalScore = baseApftScore * scaleFactor; 
  } else { // reps > repsFor50 and reps < maxRepsFor100
    // Scale the 61-100 base score range to 51-100 final score range
    const basePointsAboveThreshold = baseApftScore - baseScoreAt50Reps;
    const baseRangeSize = baseScoreAt100Reps - baseScoreAt50Reps; // Should be 40
    const targetRangeSize = 100 - 50; // Should be 50

    // Avoid division by zero
    const scaleFactor = baseRangeSize > 0 ? targetRangeSize / baseRangeSize : 0; // 50 / 40 = 1.25
    finalScore = 50 + basePointsAboveThreshold * scaleFactor;
  }

  // Return rounded score clamped between 0 and 100
  return Math.max(0, Math.min(100, Math.round(finalScore)));
}

function calculateSitupScore(reps: number): number {
  if (reps <= 0) {
    return 0;
  } else if (reps <= 47) {
    return reps * (50 / 47);
  } else if (reps < 78) {
    return 50 + (reps - 47) * (50 / (78 - 47));
  } else {
    return 100;
  }
}

function calculatePullupScore(reps: number): number {
  if (reps <= 0) {
    return 0;
  } else if (reps <= 8) {
    return reps * (50 / 8);
  } else if (reps < 20) {
    return 50 + (reps - 8) * (50 / (20 - 8));
  } else {
    return 100;
  }
}

/**
 * Calculates the score for a run based on time in seconds
 * Uses the official APFT scoring table for accuracy
 * @param timeSeconds Time to complete 2-mile run in seconds
 * @returns Score from 0-100
 */
function calculateRunScore(timeSeconds: number): number {
  // Use the official APFT scoring table from APFTScoring.ts
  return calculateRunningScore(timeSeconds);
}

// Format time in seconds to MM:SS or HH:MM:SS format
export function formatTime(totalSeconds: number): string {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  
  const parts: string[] = [];
  if (hours > 0) {
    parts.push(hours.toString().padStart(2, '0'));
  }
  parts.push(minutes.toString().padStart(2, '0'));
  parts.push(seconds.toString().padStart(2, '0'));
  
  return parts.join(':');
}

// Convert distance from meters to miles or kilometers
export function formatDistance(meters: number, unit: 'km' | 'mi' = 'km'): string {
  if (unit === 'km') {
    return (meters / 1000).toFixed(2) + ' km';
  } else {
    return (meters / 1609.34).toFixed(2) + ' mi';
  }
}

/**
 * Format leaderboard score based on exercise type
 */
export const formatLeaderboardScore = (
  exercise: string,
  score: number,
  boardType?: 'Global' | 'Local'
): string => {
  // The backend always returns grades/points (0-100) for leaderboard entries
  // regardless of exercise type or board type
  return `${score} pts`;
};
