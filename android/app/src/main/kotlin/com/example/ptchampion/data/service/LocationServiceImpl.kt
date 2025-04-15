package com.example.ptchampion.data.service // Place in data layer

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import com.example.ptchampion.domain.model.LocationData
import com.example.ptchampion.domain.service.LocationService
import com.example.ptchampion.domain.util.Resource
import com.google.android.gms.location.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LocationServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val fusedLocationClient: FusedLocationProviderClient
) : LocationService {

    private val _locationUpdates = MutableStateFlow<Resource<Location>>(Resource.Loading())

    // Callback for continuous updates
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let {
                _locationUpdates.value = Resource.Success(it)
            }
        }

        override fun onLocationAvailability(locationAvailability: LocationAvailability) {
            if (!locationAvailability.isLocationAvailable) {
                _locationUpdates.value = Resource.Error("Location services are unavailable.")
            }
        }
    }

    @SuppressLint("MissingPermission") // Permissions checked before calling
    @OptIn(ExperimentalCoroutinesApi::class)
    override fun getCurrentLocation(): Flow<Resource<LocationData>> = callbackFlow {
        // Check permissions first
        if (!hasLocationPermission()) {
            trySend(Resource.Error("Location permission denied."))
            awaitClose { }
            return@callbackFlow
        }
        // Check if location services are enabled
        if (!isLocationEnabled()) {
            trySend(Resource.Error("Location services disabled."))
            awaitClose { }
            return@callbackFlow
        }

        trySend(Resource.Loading())

        // Try getting last known location first (faster)
        var currentLocation: Location? = null
        try {
            currentLocation = fusedLocationClient.lastLocation.await()
        } catch (e: Exception) {
            // Ignore error, proceed to request current location
        }

        if (currentLocation != null) {
            trySend(Resource.Success(LocationData(currentLocation.latitude, currentLocation.longitude)))
            awaitClose { }
            return@callbackFlow
        }

        // If last location is null, request a fresh one
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000) // 5 sec timeout
            .setWaitForAccurateLocation(true)
            .setMaxUpdates(1)
            .build()

        val singleUpdateCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let {
                    trySend(Resource.Success(LocationData(it.latitude, it.longitude)))
                    close()
                } ?: run {
                    trySend(Resource.Error("Failed to get current location."))
                    close()
                }
            }
            override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                if (!locationAvailability.isLocationAvailable) {
                    trySend(Resource.Error("Location not available after request."))
                    close()
                }
            }
        }

        try {
             fusedLocationClient.requestLocationUpdates(
                locationRequest,
                singleUpdateCallback,
                Looper.getMainLooper() // Use main looper for callback
            )
        } catch (e: Exception) {
             trySend(Resource.Error("Error requesting location update: ${e.message}"))
             close()
        }

        awaitClose { fusedLocationClient.removeLocationUpdates(singleUpdateCallback) }
    }

    // Implementation for continuous updates (if needed)
    override fun getLocationUpdates(): Flow<Resource<Location>> {
        // This should ideally use callbackFlow as well for proper lifecycle management
        // and permission checks within the flow emission.
        // Returning the simple MutableStateFlow for now, assuming start/stop are called.
        return _locationUpdates
    }

    @SuppressLint("MissingPermission") // Permissions checked before calling
    override suspend fun startLocationUpdates() {
        if (!hasLocationPermission()) {
            _locationUpdates.value = Resource.Error("Location permission denied.")
            return
        }
        if (!isLocationEnabled()) {
            _locationUpdates.value = Resource.Error("Location services disabled.")
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10000)
            .setMinUpdateIntervalMillis(5000)
            .build()

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            _locationUpdates.value = Resource.Loading() // Indicate loading started
        } catch (e: Exception) {
             _locationUpdates.value = Resource.Error("Error starting location updates: ${e.message}")
        }
    }

    override suspend fun stopLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            _locationUpdates.value = Resource.Error("Updates stopped") // Or a specific state
        } catch (e: Exception) {
            // Handle potential exception during removal
             _locationUpdates.value = Resource.Error("Error stopping updates: ${e.message}")
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

    private fun isLocationEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }
} 