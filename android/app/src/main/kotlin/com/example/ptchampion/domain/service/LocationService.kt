package com.example.ptchampion.domain.service

import android.location.Location
import com.example.ptchampion.domain.model.LocationData
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow

/**
 * Interface for providing device location services.
 */
interface LocationService {

    /**
     * Gets the current device location once.
     * Emits Resource.Loading, then Resource.Success with LocationData, or Resource.Error.
     * Errors could be due to permissions, disabled location services, or timeouts.
     */
    fun getCurrentLocation(): Flow<Resource<LocationData>>

    /**
     * A flow emitting the user's current location.
     * Emits errors if location cannot be obtained (e.g., permissions denied, GPS off).
     */
    fun getLocationUpdates(): Flow<Resource<Location>> // Use your Resource wrapper

    /**
     * Starts requesting location updates.
     * Should handle permission checks internally or assume they are granted.
     */
    suspend fun startLocationUpdates()

    /**
     * Stops requesting location updates.
     */
    suspend fun stopLocationUpdates()
} 