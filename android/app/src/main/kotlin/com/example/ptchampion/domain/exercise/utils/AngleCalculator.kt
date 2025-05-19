package com.example.ptchampion.domain.exercise.utils

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import kotlin.math.acos
import kotlin.math.atan2
import kotlin.math.sqrt
import kotlin.math.abs

/**
 * Utility class for calculating angles between landmarks.
 */
object AngleCalculator {
    /**
     * Calculates the angle between three landmarks in degrees.
     * @return The angle in degrees (0-180).
     */
    fun calculateAngle(
        first: NormalizedLandmark,
        middle: NormalizedLandmark,
        last: NormalizedLandmark
    ): Float {
        // Calculate vectors
        val v1x = first.x() - middle.x()
        val v1y = first.y() - middle.y()
        val v1z = first.z() - middle.z()

        val v2x = last.x() - middle.x()
        val v2y = last.y() - middle.y()
        val v2z = last.z() - middle.z()

        // Calculate dot product
        val dotProduct = v1x * v2x + v1y * v2y + v1z * v2z

        // Calculate magnitudes
        val v1Mag = sqrt(v1x * v1x + v1y * v1y + v1z * v1z)
        val v2Mag = sqrt(v2x * v2x + v2y * v2y + v2z * v2z)

        // Handle potential division by zero
        if (v1Mag < 0.0001f || v2Mag < 0.0001f) {
            return 0f
        }

        // Calculate angle in radians, clamp to [-1, 1] to avoid NaN from acos
        val cosTheta = (dotProduct / (v1Mag * v2Mag)).coerceIn(-1.0f, 1.0f)
        val angleRad = acos(cosTheta)

        // Convert to degrees
        return Math.toDegrees(angleRad.toDouble()).toFloat()
    }

    /**
     * Utility function to calculate the distance between two landmarks.
     */
    fun calculateDistance(
        first: NormalizedLandmark,
        second: NormalizedLandmark,
        useZ: Boolean = true
    ): Float {
        val dx = second.x() - first.x()
        val dy = second.y() - first.y()
        val dz = if (useZ) second.z() - first.z() else 0f
        
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    /**
     * Calculates the angle formed by a line with the vertical axis.
     * 
     * @param p1 First point of the line
     * @param p2 Second point of the line
     * @return Angle in degrees (0-180)
     */
    fun calculateVerticalAlignment(p1: NormalizedLandmark, p2: NormalizedLandmark): Float {
        val dy = p2.y() - p1.y()
        val dx = p2.x() - p1.x()
        
        // Calculate the angle with the vertical axis in radians
        val angleRad = atan2(dx, dy).toDouble()
        
        // Convert to degrees and take the absolute value
        return Math.abs(Math.toDegrees(angleRad)).toFloat()
    }
    
    /**
     * Calculates the angle formed by a line with the horizontal axis.
     * 
     * @param p1 First point of the line
     * @param p2 Second point of the line
     * @return Angle in degrees (0-180)
     */
    fun calculateHorizontalAlignment(p1: NormalizedLandmark, p2: NormalizedLandmark): Float {
        val dy = p2.y() - p1.y()
        val dx = p2.x() - p1.x()
        
        // Calculate the angle with the horizontal axis in radians
        val angleRad = atan2(dy, dx).toDouble()
        
        // Convert to degrees and take the absolute value
        return Math.abs(Math.toDegrees(angleRad)).toFloat()
    }

    // Add a threshold for visibility checks if needed
    private const val REQUIRED_VISIBILITY = 0.5f

    // Comparison helper (assuming you want to compare Double with Float with tolerance)
    fun Double.isCloseTo(other: Float, tolerance: Double = 0.00001): Boolean {
        return abs(this - other) < tolerance
    }
} 