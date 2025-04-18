package grading

import (
	"fmt"
	"strings"
)

// Push-up state constants
const (
	PushupStateUp       = "up"
	PushupStateDown     = "down"
	PushupStateStarting = "starting"
	PushupStateInvalid  = "invalid"
	PushupStateBetween  = "between"
)

// Required joints for push-up analysis
var PushupRequiredJoints = []string{
	"leftShoulder", "rightShoulder",
	"leftElbow", "rightElbow",
	"leftWrist", "rightWrist",
	"leftHip", "rightHip",
	"leftKnee", "rightKnee",
	"leftAnkle", "rightAnkle",
}

// GradePushup analyzes a pose for push-up form and counts repetitions
func GradePushup(pose *Pose, state *ExerciseState) (*GradingResult, error) {
	if pose == nil || state == nil {
		return nil, ErrInvalidInput
	}

	result := &GradingResult{
		IsValid:    false,
		RepCounted: false,
		FormScore:  0.0,
		Feedback:   "",
		State:      state.CurrentPhase,
	}

	// Verify required joints have sufficient confidence
	hasRequiredJoints, missingJoints := VerifyJointConfidence(pose, PushupRequiredJoints, PushupRequiredConfidence)
	if !hasRequiredJoints {
		result.Feedback = fmt.Sprintf("Cannot see clearly: %s", strings.Join(missingJoints, ", "))
		state.CurrentPhase = PushupStateInvalid
		result.State = PushupStateInvalid
		return result, nil
	}

	// Extract validated points
	leftShoulder := pose.Joints["leftShoulder"]
	rightShoulder := pose.Joints["rightShoulder"]
	leftElbow := pose.Joints["leftElbow"]
	rightElbow := pose.Joints["rightElbow"]
	leftWrist := pose.Joints["leftWrist"]
	rightWrist := pose.Joints["rightWrist"]
	leftHip := pose.Joints["leftHip"]
	rightHip := pose.Joints["rightHip"]
	leftAnkle := pose.Joints["leftAnkle"]
	rightAnkle := pose.Joints["rightAnkle"]
	// Knee joints are validated but not used in current implementation
	// They're retained for future enhancements to form checking
	_ = pose.Joints["leftKnee"]
	_ = pose.Joints["rightKnee"]

	// 1. Calculate Key Angles & Positions
	leftElbowAngle := CalculateAngle(leftWrist, leftElbow, leftShoulder)
	rightElbowAngle := CalculateAngle(rightWrist, rightElbow, rightShoulder)
	avgElbowAngle := (leftElbowAngle + rightElbowAngle) / 2.0

	// 2. Form checks - track issues in formIssues slice
	state.FormIssues = []string{}

	// 2a. Check shoulder alignment (X-axis difference)
	shoulderXDiff := abs(leftShoulder.X - rightShoulder.X)
	if shoulderXDiff > PushupShoulderAlignmentXDiff {
		state.FormIssues = append(state.FormIssues, "Keep shoulders level")
	}

	// 2b. Body straightness checks
	// Calculate average Y values for key body parts
	avgShoulderY := (leftShoulder.Y + rightShoulder.Y) / 2.0
	avgHipY := (leftHip.Y + rightHip.Y) / 2.0
	avgAnkleY := (leftAnkle.Y + rightAnkle.Y) / 2.0
	// We don't use knee position in the current implementation
	// avgKneeY := (leftKnee.Y + rightKnee.Y) / 2.0

	// Estimate body "length" (shoulder to ankle Y difference) for normalization
	bodyLengthY := abs(avgAnkleY - avgShoulderY)
	if bodyLengthY < 0.001 {
		bodyLengthY = 1.0 // Prevent division by zero
	}

	// Calculate where the hip should be on a straight line from shoulder to ankle
	shoulderAnkleLineYatHipX := InterpolateY(
		avgShoulderY, 0,
		avgAnkleY, 0,
		avgHipY,
	)

	// Calculate hip deviation (positive = sagging, negative = piking relative to straight line)
	hipDeviationRatio := (avgHipY - shoulderAnkleLineYatHipX) / bodyLengthY

	// Check for Sagging (Hips too low)
	if hipDeviationRatio > PushupHipSagThreshold {
		state.FormIssues = append(state.FormIssues, "Keep hips from sagging")
	}

	// Check for Piking (Hips too high)
	if hipDeviationRatio < -PushupHipPikeThreshold {
		state.FormIssues = append(state.FormIssues, "Avoid raising hips too high")
	}

	// If form issues exist, set state to invalid and provide feedback
	if len(state.FormIssues) > 0 {
		state.CurrentPhase = PushupStateInvalid
		result.State = PushupStateInvalid
		result.Feedback = strings.Join(state.FormIssues, ". ")
		result.IsValid = false
		return result, nil
	}

	// 3. State Machine Logic
	previousState := state.CurrentPhase

	// Determine potential next state based on elbow angle
	var potentialState string
	if avgElbowAngle <= PushupElbowAngleDownMax {
		potentialState = PushupStateDown
	} else if avgElbowAngle >= PushupElbowAngleUpMin {
		potentialState = PushupStateUp
	} else {
		potentialState = PushupStateBetween
	}

	// Update current state
	state.CurrentPhase = potentialState

	// Track minimum angle during the down phase or transition towards it
	if state.CurrentPhase == PushupStateDown || (previousState == PushupStateUp && state.CurrentPhase == PushupStateBetween) {
		state.MinElbowAngle = min(state.MinElbowAngle, avgElbowAngle)
	}

	// Check if went low enough (only relevant if currently down or moving up from down)
	if state.CurrentPhase == PushupStateDown || (previousState == PushupStateDown && (state.CurrentPhase == PushupStateBetween || state.CurrentPhase == PushupStateUp)) {
		if state.MinElbowAngle <= PushupElbowAngleDownMax {
			state.WentLowEnough = true
		}
	}

	// Check for Rep Completion
	if previousState == PushupStateDown && state.CurrentPhase == PushupStateUp {
		// Rep attempt: Transitioned from Down to Up
		if state.WentLowEnough {
			state.RepCount++
			result.RepCounted = true
			result.Feedback = fmt.Sprintf("Rep Counted! (%d)", state.RepCount)
			// Reset state for next rep
			state.MinElbowAngle = 180.0
			state.WentLowEnough = false
		} else {
			// Didn't go low enough on the previous down phase
			result.Feedback = "Push lower for rep to count"
			// Reset state for next rep attempt
			state.MinElbowAngle = 180.0
			state.WentLowEnough = false
		}
	}

	// 4. Provide general feedback based on state if no specific message already set
	if result.Feedback == "" {
		switch state.CurrentPhase {
		case PushupStateUp:
			result.Feedback = "Lower body"
		case PushupStateDown:
			result.Feedback = "Push up"
		case PushupStateStarting:
			result.Feedback = "Begin when ready"
		case PushupStateBetween:
			result.Feedback = "Keep moving"
		case PushupStateInvalid:
			result.Feedback = "Fix pose"
		}
	}

	// Calculate form score based on alignment and depth
	formScore := 1.0
	if shoulderXDiff > 0 {
		// Reduce score based on shoulder alignment (0 to 0.5 reduction)
		alignmentPenalty := min(0.5, shoulderXDiff/PushupShoulderAlignmentXDiff*0.5)
		formScore -= alignmentPenalty
	}

	if abs(hipDeviationRatio) > 0 {
		// Reduce score based on body straightness (0 to 0.5 reduction)
		straightnessPenalty := min(0.5, abs(hipDeviationRatio)/max(PushupHipSagThreshold, PushupHipPikeThreshold)*0.5)
		formScore -= straightnessPenalty
	}

	result.IsValid = true
	result.State = state.CurrentPhase
	result.FormScore = max(0, formScore) // Ensure non-negative

	return result, nil
}

// Helper functions
func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

func max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}
