//go:build js && wasm
// +build js,wasm

package main

import (
	"ptchampion/internal/grading"
	"syscall/js"
)

// calculateScoreWrapper is a thin JS-facing wrapper around grading.CalculateScore.
// It expects two arguments:
//  1. exerciseType (string) – one of "pushup", "situp", "pullup", "run".
//  2. performanceValue (number) – reps or time-in-seconds depending on the exercise.
//
// It returns the integer score (0–100) or -1 on argument error.
func calculateScoreWrapper(this js.Value, args []js.Value) interface{} {
	if len(args) != 2 {
		return js.ValueOf(-1)
	}

	exerciseType := args[0].String()
	performanceValue := args[1].Float()

	score := grading.CalculateScore(exerciseType, performanceValue)
	return js.ValueOf(score)
}

func main() {
	// Expose the wrapper as a global JS function "calculateScore".
	js.Global().Set("calculateScore", js.FuncOf(calculateScoreWrapper))

	// Prevent the Go program from exiting, which would terminate the WASM runtime.
	select {}
}
