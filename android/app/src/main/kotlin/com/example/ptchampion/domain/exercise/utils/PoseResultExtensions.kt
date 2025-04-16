package com.example.ptchampion.domain.exercise.utils

import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark

/**
 * Extension functions for working with MediaPipe pose landmark results.
 */
object PoseResultExtensions {

    /**
     * Gets a specific landmark from the result bundle.
     * @param landmarkIndex The index of the landmark to get.
     * @return The normalized landmark, or null if not present.
     */
    fun PoseLandmarkerHelper.ResultBundle.getLandmark(landmarkIndex: Int): NormalizedLandmark? {
        if (results.landmarks().isEmpty()) return null
        return results.landmarks()[0].getOrNull(landmarkIndex)
    }

    /**
     * Checks if a specific landmark is visible with sufficient confidence.
     * @param landmarkIndex The index of the landmark to check.
     * @param minVisibility The minimum visibility threshold (0.0-1.0).
     * @return True if the landmark is visible with sufficient confidence.
     */
    fun PoseLandmarkerHelper.ResultBundle.isLandmarkVisible(
        landmarkIndex: Int, 
        minVisibility: Float = 0.5f
    ): Boolean {
        val landmark = getLandmark(landmarkIndex) ?: return false
        return (landmark.visibility().orElse(0f)) >= minVisibility
    }

    /**
     * Checks if all specified landmarks are visible with sufficient confidence.
     * @param landmarkIndices List of landmark indices to check.
     * @param minVisibility The minimum visibility threshold (0.0-1.0).
     * @return True if all specified landmarks are visible with sufficient confidence.
     */
    fun PoseLandmarkerHelper.ResultBundle.areAllLandmarksVisible(
        landmarkIndices: List<Int>,
        minVisibility: Float = 0.5f
    ): Boolean {
        return landmarkIndices.all { isLandmarkVisible(it, minVisibility) }
    }

    /**
     * Gets the average confidence of all landmarks in the pose.
     * @return Average visibility value across all landmarks.
     */
    fun PoseLandmarkerHelper.ResultBundle.getAverageConfidence(): Float {
        if (results.landmarks().isEmpty()) return 0f
        
        val landmarks = results.landmarks()[0]
        if (landmarks.isEmpty()) return 0f
        
        val visibilities = landmarks.mapNotNull { it.visibility().orElse(0f) }
        return if (visibilities.isNotEmpty()) visibilities.average().toFloat() else 0f
    }
} 