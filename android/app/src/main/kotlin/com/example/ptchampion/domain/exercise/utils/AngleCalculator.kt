package com.example.ptchampion.domain.exercise.utils

import kotlin.math.acos
import kotlin.math.atan2
import kotlin.math.sqrt
import kotlin.math.abs

/**
 * Utility object for calculating angles between pose landmarks.
 */
object AngleCalculator {
    /**
     * Calculates the angle between three landmarks in 3D space.
     *
     * @param first The first landmark (e.g., shoulder).
     * @param middle The middle landmark (e.g., elbow).
     * @param last The last landmark (e.g., wrist).
     * @return The angle in degrees (0-180).
     */
    fun calculateAngle(
        first: MockNormalizedLandmark,
        middle: MockNormalizedLandmark,
        last: MockNormalizedLandmark
    ): Float {
        // Ensure visibility for accurate calculations
        if (first.visibility < 0.5f ||
            middle.visibility < 0.5f ||
            last.visibility < 0.5f) {
            return -1f // Indicate insufficient visibility
        }

        // Calculate vectors
        val v1x = first.x - middle.x
        val v1y = first.y - middle.y
        val v1z = first.z - middle.z // Include Z for 3D angle

        val v2x = last.x - middle.x
        val v2y = last.y - middle.y
        val v2z = last.z - middle.z

        // Calculate dot product
        val dotProduct = v1x * v2x + v1y * v2y + v1z * v2z

        // Calculate magnitudes
        val v1Mag = sqrt(v1x * v1x + v1y * v1y + v1z * v1z)
        val v2Mag = sqrt(v2x * v2x + v2y * v2y + v2z * v2z)

        // Handle potential division by zero if magnitudes are zero
        if (v1Mag == 0f || v2Mag == 0f) {
            return 0f
        }

        // Calculate angle in radians, clamp the value to [-1, 1] to avoid NaN from acos
        val cosTheta = (dotProduct / (v1Mag * v2Mag)).coerceIn(-1.0f, 1.0f)
        val angleRad = acos(cosTheta)

        // Convert to degrees
        return Math.toDegrees(angleRad.toDouble()).toFloat()
    }

    /**
     * Calculates the vertical alignment difference between two points.
     * Positive value means p1 is below p2.
     */
    fun calculateVerticalAlignment(p1: MockNormalizedLandmark, p2: MockNormalizedLandmark): Float {
        return p1.y - p2.y
    }

    /**
     * Calculates the horizontal alignment difference between two points.
     * Positive value means p1 is to the right of p2.
     */
    fun calculateHorizontalAlignment(p1: MockNormalizedLandmark, p2: MockNormalizedLandmark): Float {
        return p1.x - p2.x
    }

    // Add a threshold for visibility checks if needed
    private const val REQUIRED_VISIBILITY = 0.5f

    // Comparison helper (assuming you want to compare Double with Float with tolerance)
    fun Double.isCloseTo(other: Float, tolerance: Double = 0.00001): Boolean {
        return abs(this - other) < tolerance
    }
} 