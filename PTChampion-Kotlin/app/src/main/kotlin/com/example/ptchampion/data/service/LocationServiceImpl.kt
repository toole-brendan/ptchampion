package com.example.ptchampion.data.service // Place in data layer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import androidx.core.content.ContextCompat
import com.example.ptchampion.domain.service.LocationService
import com.example.ptchampion.domain.service.Resource
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.Priority
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LocationServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val fusedLocationClient: FusedLocationProviderClient
) : LocationService {

    private val _isUpdating = MutableStateFlow(false)
    private var locationCallback: LocationCallback? = null

    override fun getLocationUpdates(): Flow<Resource<Location>> = callbackFlow {
        if (!hasLocationPermission()) {
            trySend(Resource.Error("Location permission not granted."))
            awaitClose { /* Do nothing, flow already closed */ }
            return@callbackFlow
        }

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY, 10000L // Update interval 10 seconds
        ).setMinUpdateIntervalMillis(5000L) // Minimum update interval 5 seconds
          .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let {
                    trySend(Resource.Success(it))
                } ?: trySend(Resource.Error("Unable to get last location"))
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback!!,
                context.mainLooper
            )
            _isUpdating.update { true }
            trySend(Resource.Loading()) // Indicate loading until first location arrives
        } catch (e: SecurityException) {
            // This should ideally be caught by the initial permission check
            trySend(Resource.Error("Location permission missing during request."))
            awaitClose {}
            return@callbackFlow
        } catch (e: Exception) {
            trySend(Resource.Error("Failed to start location updates: ${e.message}"))
            awaitClose {}
            return@callbackFlow
        }

        // Called when the Flow collector cancels
        awaitClose { stopLocationUpdatesInternal() }
    }

    override suspend fun startLocationUpdates() {
        // The flow starts updates automatically on collection
        // This function could be used to trigger initial collection or ensure the service is ready
        // For now, it does nothing extra as the Flow handles it.
    }

    override suspend fun stopLocationUpdates() {
        stopLocationUpdatesInternal()
    }

    private fun stopLocationUpdatesInternal() {
        if (_isUpdating.value) {
            locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
            _isUpdating.update { false }
            locationCallback = null
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
} 