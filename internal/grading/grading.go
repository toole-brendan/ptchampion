package grading

// CalculateRunScore calculates the run score with proper handling of intermediate times
// This function addresses the issue where times between map entries weren't properly scored
func CalculateRunScore(seconds int) int {
	// Round to nearest 6-second interval for lookup
	roundedSeconds := ((seconds + 3) / 6) * 6

	if score, exists := runScoreMap[roundedSeconds]; exists {
		return score
	}

	// If exact match not found, find closest scores
	var lowerTime, upperTime int
	for time := range runScoreMap {
		if time <= seconds && time > lowerTime {
			lowerTime = time
		}
		if time >= seconds && (upperTime == 0 || time < upperTime) {
			upperTime = time
		}
	}

	// Use the score from the next slower time (conservative approach)
	if upperTime > 0 {
		return runScoreMap[upperTime]
	}

	// Fallback
	if seconds < 660 {
		return 100
	} else if seconds > 1170 {
		return 0
	}

	return 0
}

// CalculateRunScoreSeconds is an alias for CalculateRunScore for consistency
func CalculateRunScoreSeconds(seconds int) int {
	return CalculateRunScore(seconds)
}
