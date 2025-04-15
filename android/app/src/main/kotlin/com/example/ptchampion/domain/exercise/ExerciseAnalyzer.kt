package com.example.ptchampion.domain.exercise

import com.example.ptchampion.posedetection.PoseLandmarkerHelper

/**
 * Base interface for analyzing exercises based on pose landmark results.
 */
interface ExerciseAnalyzer {
    /**
     * Analyzes a single frame of pose landmark data.
     *
     * @param result The pose landmark data bundle for the current frame.
     * @return An [AnalysisResult] containing rep count, feedback, and state.
     */
    fun analyze(result: PoseLandmarkerHelper.ResultBundle): AnalysisResult

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