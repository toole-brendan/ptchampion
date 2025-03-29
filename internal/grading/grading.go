package grading

import (
	"math"
)

// CalculateScore calculates the points (0-100) based on performance
// for a given exercise type (e.g., "pushup", "situp", "pullup", "run").
// performanceValue is reps for pushups/situps/pullups, and time in seconds for run.
func CalculateScore(exerciseType string, performanceValue float64) int {
	var score float64

	switch exerciseType {
	case "pushup":
		score = calculatePushupScore(performanceValue)
	case "situp":
		score = calculateSitupScore(performanceValue)
	case "pullup":
		score = calculatePullupScore(performanceValue)
	case "run": // Assuming type is "run" for 2-mile run
		score = calculateRunScore(performanceValue)
	default:
		score = 0 // Or handle unknown types differently
	}

	// Clamp score between 0 and 100 and round to nearest integer
	clampedScore := math.Max(0, math.Min(100, score))
	return int(math.Round(clampedScore))
}

// --- Private helper functions for specific exercises ---

func calculatePushupScore(reps float64) float64 {
	if reps <= 0 {
		return 0
	} else if reps < 35 {
		return reps * (50.0 / 35.0)
	} else if reps < 71 {
		return 50.0 + (reps-35.0)*(50.0/(71.0-35.0))
	} else {
		return 100
	}
}

func calculateSitupScore(reps float64) float64 {
	if reps <= 0 {
		return 0
	} else if reps < 47 {
		return reps * (50.0 / 47.0)
	} else if reps < 78 {
		return 50.0 + (reps-47.0)*(50.0/(78.0-47.0))
	} else {
		return 100
	}
}

func calculatePullupScore(reps float64) float64 {
	if reps <= 0 {
		return 0
	} else if reps < 8 {
		return reps * (50.0 / 8.0)
	} else if reps < 20 {
		return 50.0 + (reps-8.0)*(50.0/(20.0-8.0))
	} else {
		return 100
	}
}

func calculateRunScore(timeSeconds float64) float64 {
	const time100 = 780.0 // 13:00
	const time0 = 1212.0  // 20:12 (derived linearly)

	if timeSeconds <= time100 {
		return 100
	} else if timeSeconds < time0 {
		return (time0 - timeSeconds) * (100.0 / (time0 - time100))
	} else {
		return 0
	}
}
