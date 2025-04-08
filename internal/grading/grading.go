package grading

import (
	"log"
	"math"
)

// TODO: Consider making these thresholds configurable (e.g., via config file or DB)
//       to support different standards (e.g., age/gender brackets) in the future.

// --- Scoring Constants ---

// Thresholds represent the performance value (reps or time in seconds)
// corresponding to a specific score point (e.g., 0, 50, 100).

// Push-ups (reps)
const (
	pushupMinPerfValue float64 = 0  // Performance value for 0 points
	pushupMidPerfValue float64 = 35 // Performance value for 50 points
	pushupMaxPerfValue float64 = 71 // Performance value for 100 points
)

// Sit-ups (reps)
const (
	situpMinPerfValue float64 = 0
	situpMidPerfValue float64 = 47
	situpMaxPerfValue float64 = 78
)

// Pull-ups (reps)
const (
	pullupMinPerfValue float64 = 0
	pullupMidPerfValue float64 = 8
	pullupMaxPerfValue float64 = 20
)

// Run (time in seconds) - Lower time is better
const (
	runTimeMaxScoreSec float64 = 780  // 13:00 - Performance value for 100 points
	runTimeMidScoreSec float64 = 996  // 16:36 - Performance value for 50 points (linear calc)
	runTimeMinScoreSec float64 = 1212 // 20:12 - Performance value for 0 points (linear calc)
)

// --- Main Calculation Function ---

// TODO: Define exercise type strings as constants in a shared package
//
//	(e.g., internal/constants or internal/types) and use them here.
const (
	ExerciseTypePushup = "pushup"
	ExerciseTypeSitup  = "situp"
	ExerciseTypePullup = "pullup"
	ExerciseTypeRun    = "run"
)

// CalculateScore calculates the points (0-100) based on performance
// for a given exercise type.
func CalculateScore(exerciseType string, performanceValue float64) int {
	var score float64

	// Optional: Add explicit check for negative performance value, although clamping handles it.
	// if performanceValue < 0 {
	// 	 performanceValue = 0
	// }

	switch exerciseType {
	case ExerciseTypePushup:
		score = calculateRepScore(performanceValue, pushupMinPerfValue, pushupMidPerfValue, pushupMaxPerfValue)
	case ExerciseTypeSitup:
		score = calculateRepScore(performanceValue, situpMinPerfValue, situpMidPerfValue, situpMaxPerfValue)
	case ExerciseTypePullup:
		score = calculateRepScore(performanceValue, pullupMinPerfValue, pullupMidPerfValue, pullupMaxPerfValue)
	case ExerciseTypeRun:
		score = calculateTimeScore(performanceValue, runTimeMinScoreSec, runTimeMidScoreSec, runTimeMaxScoreSec)
	default:
		log.Printf("Warning: Unknown exercise type '%s' received for grading.", exerciseType)
		score = 0
	}

	// Clamp score between 0 and 100 and round to nearest integer
	clampedScore := math.Max(0, math.Min(100, score))
	return int(math.Round(clampedScore))
}

// --- Private Helper Functions ---

// calculateRepScore calculates score for exercises where higher reps are better.
// Assumes a piece-wise linear scale: 0->50 points, 50->100 points.
func calculateRepScore(reps, minPerf, midPerf, maxPerf float64) float64 {
	if reps <= minPerf {
		return 0
	} else if reps < midPerf {
		// Interpolate between 0 and 50 points
		return interpolate(reps, minPerf, midPerf, 0, 50)
	} else if reps < maxPerf {
		// Interpolate between 50 and 100 points
		return interpolate(reps, midPerf, maxPerf, 50, 100)
	} else { // reps >= maxPerf
		return 100
	}
}

// calculateTimeScore calculates score for exercises where lower time is better.
// Assumes a piece-wise linear scale: 0->50 points, 50->100 points based on time thresholds.
func calculateTimeScore(timeSeconds, minScoreTime, midScoreTime, maxScoreTime float64) float64 {
	if timeSeconds <= maxScoreTime { // Fastest time or better
		return 100
	} else if timeSeconds < midScoreTime {
		// Interpolate between 100 and 50 points (reverse order for time)
		return interpolate(timeSeconds, maxScoreTime, midScoreTime, 100, 50)
	} else if timeSeconds < minScoreTime {
		// Interpolate between 50 and 0 points (reverse order for time)
		return interpolate(timeSeconds, midScoreTime, minScoreTime, 50, 0)
	} else { // timeSeconds >= minScoreTime (slowest time or worse)
		return 0
	}
}

// interpolate performs linear interpolation.
// Calculates the score corresponding to a value within a given range [valueMin, valueMax],
// mapping it linearly to a score range [scoreMin, scoreMax].
func interpolate(value, valueMin, valueMax, scoreMin, scoreMax float64) float64 {
	// Avoid division by zero if min and max values are the same
	if valueMax == valueMin {
		// Return the average of scoreMin/scoreMax or one boundary? Depends on desired behavior.
		// Returning scoreMin here, assuming value must strictly exceed valueMin to score higher.
		return scoreMin
	}
	// Calculate the proportion of the value within its range
	proportion := (value - valueMin) / (valueMax - valueMin)
	// Apply the proportion to the score range
	score := scoreMin + proportion*(scoreMax-scoreMin)
	return score
}
