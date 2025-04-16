package com.example.ptchampion.domain.exercise.bluetooth

/**
 * Data class representing running metrics derived from watch data
 */
data class RunningMetrics(
    val distance: Float,              // Total distance in meters
    val elapsedTimeMs: Long,          // Total elapsed time in milliseconds
    val currentPaceMinPerKm: Float,   // Current pace in minutes per kilometer
    val currentSpeed: Float,          // Current speed in meters per second
    val currentHeartRate: Int?,       // Current heart rate in BPM (if available)
    val calories: Int                 // Estimated calories burned
) {
    // Convenience getters for formatted values
    val formattedDistance: String
        get() = if (distance >= 1000) {
            String.format("%.2f km", distance / 1000)
        } else {
            String.format("%d m", distance.toInt())
        }
    
    val formattedElapsedTime: String
        get() {
            val hours = elapsedTimeMs / (1000 * 60 * 60)
            val minutes = (elapsedTimeMs / (1000 * 60)) % 60
            val seconds = (elapsedTimeMs / 1000) % 60
            
            return if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format("%02d:%02d", minutes, seconds)
            }
        }
    
    val formattedPace: String
        get() {
            if (currentPaceMinPerKm <= 0) return "--:--"
            val minutes = currentPaceMinPerKm.toInt()
            val seconds = ((currentPaceMinPerKm - minutes) * 60).toInt()
            return String.format("%d:%02d /km", minutes, seconds)
        }
} 