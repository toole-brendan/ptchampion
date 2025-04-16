package com.example.ptchampion.domain.exercise.bluetooth

/**
 * Data class representing GPS location data from a fitness watch
 */
data class GpsLocation(
    val latitude: Double,
    val longitude: Double,
    val altitude: Double?,
    val accuracy: Float?,
    val timestamp: Long,
    val speed: Float?,
    val bearing: Float?
) 