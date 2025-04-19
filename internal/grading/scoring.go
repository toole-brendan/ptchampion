package grading

import (
	"math"
)

// CalculateScore calculates the points (0-100) based on performance
// for a given exercise type.
func CalculateScore(exerciseType string, performanceValue float64) (int, error) {
	var score float64

	switch exerciseType {
	case ExerciseTypePushup:
		score = calculateRepScore(performanceValue, PushupMinPerfValue, PushupMidPerfValue, PushupMaxPerfValue)
	case ExerciseTypeSitup:
		score = calculateRepScore(performanceValue, SitupMinPerfValue, SitupMidPerfValue, SitupMaxPerfValue)
	case ExerciseTypePullup:
		score = calculateRepScore(performanceValue, PullupMinPerfValue, PullupMidPerfValue, PullupMaxPerfValue)
	case ExerciseTypeRun:
		score = calculateTimeScore(performanceValue, RunTimeMinScoreSec, RunTimeMidScoreSec, RunTimeMaxScoreSec)
	default:
		return 0, ErrUnknownExerciseType
	}

	// Clamp score between 0 and 100 and round to nearest integer
	clampedScore := math.Max(0, math.Min(100, score))
	return int(math.Round(clampedScore)), nil
}

// ScoreWithThresholds allows scoring with custom thresholds
// Useful for supporting different age groups or genders
func ScoreWithThresholds(exerciseType string, performanceValue float64, minPerf, midPerf, maxPerf float64) (int, error) {
	var score float64

	if performanceValue < 0 {
		return 0, ErrInvalidInput
	}

	switch exerciseType {
	case ExerciseTypePushup, ExerciseTypeSitup, ExerciseTypePullup:
		score = calculateRepScore(performanceValue, minPerf, midPerf, maxPerf)
	case ExerciseTypeRun:
		// For time-based events, we invert the thresholds since lower time is better
		score = calculateTimeScore(performanceValue, maxPerf, midPerf, minPerf)
	default:
		return 0, ErrUnknownExerciseType
	}

	// Clamp score between 0 and 100 and round to nearest integer
	clampedScore := math.Max(0, math.Min(100, score))
	return int(math.Round(clampedScore)), nil
}

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
