//go:build js && wasm
// +build js,wasm

package main

import (
	"encoding/json"
	"fmt"
	"syscall/js"

	"ptchampion/pkg/grading"
)

func main() {
	fmt.Println("PT Champion grading WASM initialized")

	// Register JavaScript functions
	js.Global().Set("calculateExerciseScore", js.FuncOf(calculateExerciseScore))
	js.Global().Set("gradePushupPose", js.FuncOf(gradePushupPose))

	// Keep the program running
	<-make(chan bool)
}

// calculateExerciseScore implements the score calculation for a given exercise type and performance value
func calculateExerciseScore(this js.Value, args []js.Value) interface{} {
	// Validate arguments
	if len(args) < 2 {
		return createErrorResponse("Insufficient arguments: requires exerciseType and performanceValue")
	}

	exerciseType := args[0].String()
	performanceValue := args[1].Float()

	// Call Go function
	score, err := grading.CalculateScore(exerciseType, performanceValue)
	if err != nil {
		return createErrorResponse(fmt.Sprintf("Error calculating score: %v", err))
	}

	// Return result as a JS object
	return map[string]interface{}{
		"success": true,
		"score":   score,
	}
}

// gradePushupPose analyzes pose data for push-up form and rep counting
func gradePushupPose(this js.Value, args []js.Value) interface{} {
	// Validate arguments
	if len(args) < 1 {
		return createErrorResponse("Missing pose data")
	}

	// Parse pose data from JSON
	poseJSON := args[0].String()
	pose, err := parsePose(poseJSON)
	if err != nil {
		return createErrorResponse(fmt.Sprintf("Error parsing pose: %v", err))
	}

	// Parse or create exercise state
	var state *grading.ExerciseState
	if len(args) >= 2 && !args[1].IsNull() && !args[1].IsUndefined() {
		stateJSON := args[1].String()
		state, err = parseState(stateJSON)
		if err != nil {
			return createErrorResponse(fmt.Sprintf("Error parsing state: %v", err))
		}
	} else {
		state = grading.NewExerciseState()
	}

	// Call Go grading function
	result, err := grading.GradePushup(pose, state)
	if err != nil {
		return createErrorResponse(fmt.Sprintf("Error grading pushup: %v", err))
	}

	// Convert state to JSON for persistence
	stateJSON, err := json.Marshal(state)
	if err != nil {
		return createErrorResponse(fmt.Sprintf("Error serializing state: %v", err))
	}

	// Return both the grading result and updated state
	return map[string]interface{}{
		"success": true,
		"result": map[string]interface{}{
			"isValid":    result.IsValid,
			"repCounted": result.RepCounted,
			"formScore":  result.FormScore,
			"feedback":   result.Feedback,
			"state":      result.State,
		},
		"repCount": state.RepCount,
		"state":    string(stateJSON),
	}
}

// Helper functions

// parsePose converts a JSON string to a Pose object
func parsePose(poseJSON string) (*grading.Pose, error) {
	var poseData struct {
		Keypoints []struct {
			Name       string  `json:"name"`
			X          float64 `json:"x"`
			Y          float64 `json:"y"`
			Confidence float64 `json:"confidence"`
		} `json:"keypoints"`
	}

	if err := json.Unmarshal([]byte(poseJSON), &poseData); err != nil {
		return nil, fmt.Errorf("invalid pose JSON: %w", err)
	}

	pose := grading.NewPose()
	for _, kp := range poseData.Keypoints {
		pose.Joints[kp.Name] = grading.Joint{
			X:          kp.X,
			Y:          kp.Y,
			Confidence: kp.Confidence,
		}
	}

	return pose, nil
}

// parseState converts a JSON string to an ExerciseState object
func parseState(stateJSON string) (*grading.ExerciseState, error) {
	state := grading.NewExerciseState()

	if err := json.Unmarshal([]byte(stateJSON), state); err != nil {
		return nil, fmt.Errorf("invalid state JSON: %w", err)
	}

	return state, nil
}

// createErrorResponse creates a standard error response object
func createErrorResponse(message string) map[string]interface{} {
	return map[string]interface{}{
		"success": false,
		"error":   message,
	}
}
