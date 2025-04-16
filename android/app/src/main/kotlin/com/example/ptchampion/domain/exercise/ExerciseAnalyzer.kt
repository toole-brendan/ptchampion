package com.example.ptchampion.domain.exercise

import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Interface for analyzing exercise form and counting reps from pose data.
 */
interface ExerciseAnalyzer {

    /**
     * Analyzes a single frame of pose landmark data provided as a ResultBundle.
     * This is the primary analysis method expected to be used.
     * 
     * @param resultBundle Contains pose landmarks, image dimensions, and inference time.
     * @return AnalysisResult containing rep count, feedback, and form score.
     */
    fun analyze(resultBundle: PoseLandmarkerHelper.ResultBundle): AnalysisResult

    /**
     * Analyzes a single frame of pose landmark data provided directly as PoseLandmarkerResult.
     * Provides a convenience wrapper around the primary analyze method.
     * 
     * @param result The raw PoseLandmarkerResult.
     * @return AnalysisResult derived from wrapping the input in a ResultBundle.
     */
    fun analyze(result: PoseLandmarkerResult): AnalysisResult {
        // Create a simple ResultBundle wrapper, dimensions might be inaccurate if not available
        // Consider if image dimensions are actually needed by analyzers or if they can be optional
        val bundle = PoseLandmarkerHelper.ResultBundle(
            results = result,
            inputImageWidth = 0, // Placeholder - update if actual width/height available
            inputImageHeight = 0, // Placeholder
            inferenceTime = 0 // Placeholder
        )
        return analyze(bundle)
    }

    /**
     * Checks if the detected pose in the ResultBundle is valid for starting 
     * or continuing the exercise analysis.
     * 
     * @param resultBundle The pose data to validate.
     * @return true if the pose is considered valid, false otherwise.
     */
    fun isValidPose(resultBundle: PoseLandmarkerHelper.ResultBundle): Boolean

    /**
     * Starts or restarts the exercise analysis session, resetting internal state like rep count
     * and tracking variables.
     */
    fun start()

    /**
     * Stops the exercise analysis session. May perform cleanup if necessary.
     */
    fun stop()

    /**
     * Resets the analyzer's state (e.g., rep count, internal counters) without 
     * necessarily stopping the session. Useful for starting a new set, for example.
     */
    fun reset()
} 