package com.example.ptchampion.domain.exercise.bluetooth

import java.util.UUID

/**
 * Represents an active workout session
 */
data class WorkoutSession(
    val id: String = UUID.randomUUID().toString(),
    val startTime: Long = System.currentTimeMillis(),
    var endTime: Long? = null,
    var pausedTime: Long = 0,
    var pauseStartTime: Long? = null,
    var isActive: Boolean = true,
    var totalDistance: Float = 0f,
    var maxHeartRate: Int? = null,
    var avgHeartRate: Int? = null,
    var locationPoints: List<GpsLocation> = emptyList()
) {
    
    val elapsedTimeMs: Long
        get() {
            val end = endTime ?: System.currentTimeMillis()
            val pauseExtra = if (pauseStartTime != null && isActive) {
                System.currentTimeMillis() - pauseStartTime!!
            } else {
                0
            }
            return (end - startTime) - (pausedTime + pauseExtra)
        }
    
    fun pause() {
        if (isActive && pauseStartTime == null) {
            pauseStartTime = System.currentTimeMillis()
            isActive = false
        }
    }
    
    fun resume() {
        if (!isActive && pauseStartTime != null) {
            pausedTime += (System.currentTimeMillis() - pauseStartTime!!)
            pauseStartTime = null
            isActive = true
        }
    }
    
    fun end() {
        if (pauseStartTime != null) {
            // If session was paused, account for that time
            pausedTime += (System.currentTimeMillis() - pauseStartTime!!)
            pauseStartTime = null
        }
        endTime = System.currentTimeMillis()
        isActive = false
    }
}

/**
 * Represents a workout summary after completion
 */
data class WorkoutSummary(
    val id: String,
    val startTime: Long,
    val endTime: Long,
    val actualDurationMs: Long,
    val totalDistance: Float,
    val avgHeartRate: Int?,
    val maxHeartRate: Int?,
    val avgPaceMinPerKm: Float,
    val estimatedCalories: Int,
    val locationPoints: List<GpsLocation>
) 