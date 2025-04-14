package com.example.ptchampion.domain.service

import android.location.Location
import com.example.ptchampion.domain.model.LocationData
import com.example.ptchampion.util.Resource
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

// Assuming you have a Resource wrapper like this:
sealed class Resource<T>(val data: T? = null, val message: String? = null) {
    class Success<T>(data: T) : Resource<T>(data)
    class Error<T>(message: String, data: T? = null) : Resource<T>(data, message)
    class Loading<T>(data: T? = null) : Resource<T>(data)
} 