package com.example.ptchampion.util

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

interface LocationService {
    fun requestLocationUpdates(): Flow<Location?>
    suspend fun getLastKnownLocation(): Location?
}

class LocationServiceImpl constructor(
    private val context: Context,
    private val fusedLocationProviderClient: FusedLocationProviderClient
) : LocationService {

    @SuppressLint("MissingPermission")
    override fun requestLocationUpdates(): Flow<Location?> = callbackFlow {
        if (!hasLocationPermission()) {
            trySend(null)
            close(SecurityException("Missing location permission"))
            return@callbackFlow
        }

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY, 
            10000L // Interval: 10 seconds
        ).build()

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.locations.lastOrNull()?.let {
                    launch { send(it) } // Send the latest location
                }
            }
        }

        fusedLocationProviderClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper() // Use main looper for callbacks
        ).addOnFailureListener { e ->
            close(e) // Close the flow on failure
        }

        awaitClose { // Called when the Flow collector cancels
            fusedLocationProviderClient.removeLocationUpdates(locationCallback)
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun getLastKnownLocation(): Location? {
        if (!hasLocationPermission()) {
            return null
        }
        return try {
             fusedLocationProviderClient.lastLocation.await()
        } catch (e: Exception) {
            // Handle exceptions, e.g., security exception if permission revoked
            null
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