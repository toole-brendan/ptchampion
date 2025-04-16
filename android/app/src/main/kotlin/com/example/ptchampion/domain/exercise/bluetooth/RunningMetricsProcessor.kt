package com.example.ptchampion.domain.exercise.bluetooth

import android.util.Log
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.atan2

/**
 * Processor for calculating running metrics from GPS data
 */
@Singleton
class RunningMetricsProcessor @Inject constructor() {
    private val TAG = "RunningMetricsProcessor"
    
    // Track state for calculations
    private var lastLocation: GpsLocation? = null
    private var totalDistance = 0f
    private var startTime = 0L
    private val locationHistory = mutableListOf<GpsLocation>()
    
    // Recent pace/speed calculations (for smoothing)
    private val recentPaces = mutableListOf<Float>()
    private val maxRecentPaceSamples = 5
    
    fun reset() {
        lastLocation = null
        totalDistance = 0f
        startTime = 0L
        locationHistory.clear()
        recentPaces.clear()
    }
    
    /**
     * Process a new GPS location and calculate running metrics
     */
    fun processNewLocation(location: GpsLocation, currentHeartRate: Int? = null): RunningMetrics {
        // Initialize session if this is the first location
        if (startTime == 0L) {
            startTime = location.timestamp
        }
        
        // Save to history
        locationHistory.add(location)
        
        // Calculate incremental distance if we have a previous location
        var distanceIncrement = 0f
        lastLocation?.let { last ->
            distanceIncrement = calculateDistance(
                last.latitude, last.longitude,
                location.latitude, location.longitude
            )
            totalDistance += distanceIncrement
        }
        
        // Calculate elapsed time
        val elapsedTimeMs = location.timestamp - startTime
        
        // Calculate current pace (minutes per kilometer)
        var currentPaceMinPerKm = 0f
        
        // Use speed from GPS if available, otherwise calculate from distance increments
        val currentSpeed = if (location.speed != null && location.speed!! > 0) {
            // Use the provided speed (m/s)
            location.speed!!
        } else if (lastLocation != null) {
            // Calculate speed from last two points
            val timeDiffSeconds = (location.timestamp - lastLocation!!.timestamp) / 1000f
            if (timeDiffSeconds > 0) distanceIncrement / timeDiffSeconds else 0f
        } else {
            0f
        }
        
        // Convert speed to pace (min/km)
        currentPaceMinPerKm = if (currentSpeed > 0.2f) { // Threshold to avoid division by very small values
            // 16.6667 = 1000 / 60 (converts m/s to min/km)
            16.6667f / currentSpeed
        } else {
            0f
        }
        
        // Add to recent paces for smoothing
        if (currentPaceMinPerKm > 0) {
            recentPaces.add(currentPaceMinPerKm)
            // Keep only the most recent samples
            if (recentPaces.size > maxRecentPaceSamples) {
                recentPaces.removeAt(0)
            }
        }
        
        // Get smoothed pace
        val smoothedPace = if (recentPaces.isNotEmpty()) {
            recentPaces.sum() / recentPaces.size
        } else {
            currentPaceMinPerKm
        }
        
        // Update last location
        lastLocation = location
        
        // Calculate estimated calories
        val calories = estimateCalories(totalDistance)
        
        return RunningMetrics(
            distance = totalDistance,
            elapsedTimeMs = elapsedTimeMs,
            currentPaceMinPerKm = smoothedPace,
            currentSpeed = currentSpeed,
            currentHeartRate = currentHeartRate,
            calories = calories
        )
    }
    
    /**
     * Calculate distance between two points using the Haversine formula
     */
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        // Earth radius in meters
        val earthRadius = 6371000.0
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return (earthRadius * c).toFloat()
    }
    
    /**
     * Simple calorie estimation based on distance
     * 
     * Note: A more accurate calculation would use weight, speed, terrain, etc.
     */
    private fun estimateCalories(distanceMeters: Float): Int {
        // Simple estimation: ~70 calories per km for an average runner
        return (distanceMeters * 0.07f).toInt()
    }
    
    /**
     * Generate a workout summary from the current session
     */
    fun generateWorkoutSummary(sessionId: String): WorkoutSummary? {
        if (locationHistory.isEmpty()) return null
        
        // Calculate average pace
        val startLoc = locationHistory.first()
        val endLoc = locationHistory.last()
        val totalTimeMs = endLoc.timestamp - startLoc.timestamp
        
        // Avoid division by zero
        val avgPaceMinPerKm = if (totalDistance > 0 && totalTimeMs > 0) {
            (totalTimeMs / 60000.0) / (totalDistance / 1000)
        } else {
            0.0
        }
        
        return WorkoutSummary(
            id = sessionId,
            startTime = startLoc.timestamp,
            endTime = endLoc.timestamp,
            actualDurationMs = totalTimeMs,
            totalDistance = totalDistance,
            avgHeartRate = null, // Would need to track heart rate history
            maxHeartRate = null, // Would need to track heart rate history
            avgPaceMinPerKm = avgPaceMinPerKm.toFloat(),
            estimatedCalories = estimateCalories(totalDistance),
            locationPoints = locationHistory
        )
    }
} 