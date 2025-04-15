package com.example.ptchampion.domain.exercise

import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Base interface for analyzing exercises based on pose landmark results.
 */
interface ExerciseAnalyzer {
    /**
     * Analyzes a single frame of pose landmark data from a PoseLandmarkerHelper.ResultBundle.
     * This is the original method for backward compatibility.
     *
     * @param result The pose landmark data bundle for the current frame.
     * @return An [AnalysisResult] containing rep count, feedback, and state.
     */
    fun analyze(result: PoseLandmarkerHelper.ResultBundle): AnalysisResult

    /**
     * Analyzes a single frame of pose landmark data directly from a PoseLandmarkerResult.
     * This is the direct method using MediaPipe results.
     *
     * @param result The pose landmark result from MediaPipe.
     * @return An [AnalysisResult] containing rep count, feedback, and state.
     */
    fun analyze(result: PoseLandmarkerResult): AnalysisResult {
        // Create a simple ResultBundle wrapper
        val bundle = PoseLandmarkerHelper.ResultBundle(
            results = result,
            inputImageWidth = 0,
            inputImageHeight = 0,
            inferenceTime = 0
        )
        return analyze(bundle)
    }

    /**
     * Checks if the detected pose is valid for starting the exercise analysis.
     *
     * @param result The pose landmark data bundle.
     * @return True if the pose is valid, false otherwise.
     */
    fun isValidPose(result: PoseLandmarkerHelper.ResultBundle): Boolean

    /**
     * Starts the exercise analysis session, resetting any internal state.
     */
    fun start()

    /**
     * Stops the exercise analysis session.
     */
    fun stop()

    /**
     * Resets the analyzer's state (e.g., rep count).
     */
    fun reset()
} 