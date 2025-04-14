package com.example.ptchampion.ui.screens.running

import android.app.Application
import android.location.Location
import android.os.SystemClock
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.domain.service.LocationService
import com.example.ptchampion.domain.service.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.time.OffsetDateTime
import java.time.Duration
import java.util.concurrent.TimeUnit
import javax.inject.Inject

// Define UI State with improved properties
data class RunningTrackingUiState(
    val isTracking: Boolean = false,
    val durationMillis: Long = 0L,
    val distanceMeters: Float = 0f, // Use Float for location calculations
    val currentPaceMinPerKm: Float = 0f,
    val averagePaceMinPerKm: Float = 0f,
    val locationError: String? = null,
    val permissionGranted: Boolean = false, // Track permission status
    val isSaving: Boolean = false,
    val saveError: String? = null
)

enum class TrackingStatus {
    IDLE,
    TRACKING,
    PAUSED,
    STOPPED // Indicates finished, ready to save or reset
}

// Placeholder for Running Exercise ID - fetch from backend or define constant
private const val RUNNING_EXERCISE_ID = 4 // Replace with your actual ID for running

@HiltViewModel
class RunningTrackingViewModel @Inject constructor(
    application: Application,
    private val locationService: LocationService,
    private val workoutRepository: WorkoutRepository
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(RunningTrackingUiState())
    val uiState: StateFlow<RunningTrackingUiState> = _uiState.asStateFlow()

    private val _trackingStatus = MutableStateFlow(TrackingStatus.IDLE)
    val trackingStatus: StateFlow<TrackingStatus> = _trackingStatus.asStateFlow()

    // Timer related state
    private var timerJob: Job? = null
    private var locationJob: Job? = null
    private var startTimeMillis: Long = 0L
    private var elapsedTimeMillis: Long = 0L // Time elapsed before pause
    private var lastTimestamp: Long = 0L

    // Location related state
    private var previousLocation: Location? = null
    private var totalDistance: Float = 0f

    init {
        // Observe permission changes reflected from the UI
        viewModelScope.launch {
            uiState.map { it.permissionGranted }.distinctUntilChanged().collect { granted ->
                if (!granted) {
                    // Reset state if permissions are revoked
                    resetTrackingState()
                }
            }
        }
    }

    fun startTracking() {
        if (!uiState.value.permissionGranted) {
            _uiState.update { it.copy(locationError = "Location permission required to start tracking.") }
            return
        }

        when (_trackingStatus.value) {
            TrackingStatus.IDLE, TrackingStatus.STOPPED -> {
                // Start new session
                resetTrackingState() // Clear previous run data
                startTimeMillis = SystemClock.elapsedRealtime()
                lastTimestamp = startTimeMillis
                _trackingStatus.value = TrackingStatus.TRACKING
                _uiState.update { it.copy(isTracking = true, locationError = null, saveError = null) }
                startTimer()
                startLocationUpdates()
            }
            TrackingStatus.PAUSED -> {
                // Resume paused session
                startTimeMillis = SystemClock.elapsedRealtime() // Reset start time for current interval
                lastTimestamp = startTimeMillis
                _trackingStatus.value = TrackingStatus.TRACKING
                _uiState.update { it.copy(isTracking = true) }
                startTimer()
                startLocationUpdates() // Resume location updates
            }
            TrackingStatus.TRACKING -> {
                // Already tracking, do nothing
            }
        }
    }

    fun pauseTracking() {
        if (_trackingStatus.value == TrackingStatus.TRACKING) {
            _trackingStatus.value = TrackingStatus.PAUSED
            _uiState.update { it.copy(isTracking = false) }
            elapsedTimeMillis += SystemClock.elapsedRealtime() - startTimeMillis // Add elapsed time from current interval
            timerJob?.cancel()
            stopLocationUpdates() // Pause location updates
        }
    }

    fun stopTracking() {
        if (_trackingStatus.value == TrackingStatus.TRACKING || _trackingStatus.value == TrackingStatus.PAUSED) {
            // If tracking, capture the last bit of elapsed time
            if (_trackingStatus.value == TrackingStatus.TRACKING) {
                elapsedTimeMillis += SystemClock.elapsedRealtime() - startTimeMillis
            }

            _trackingStatus.value = TrackingStatus.STOPPED
            _uiState.update { it.copy(isTracking = false) }
            timerJob?.cancel()
            stopLocationUpdates()

            // Calculate final results
            val finalDurationMillis = elapsedTimeMillis
            val finalDistanceMeters = totalDistance

            // Avoid division by zero for pace
            val avgPace = if (finalDistanceMeters > 0 && finalDurationMillis > 0) {
                calculatePaceMinPerKm(finalDistanceMeters.toFloat(), finalDurationMillis)
            } else 0f
            _uiState.update { it.copy(durationMillis = finalDurationMillis, averagePaceMinPerKm = avgPace) }

            // Save the workout
            saveWorkoutSession(finalDurationMillis, finalDistanceMeters.toDouble())
        }
    }

    private fun startTimer() {
        timerJob?.cancel() // Ensure previous job is cancelled
        timerJob = viewModelScope.launch {
            while (isActive && _trackingStatus.value == TrackingStatus.TRACKING) {
                val now = SystemClock.elapsedRealtime()
                val currentIntervalDuration = now - startTimeMillis
                val totalElapsed = elapsedTimeMillis + currentIntervalDuration // Add paused time + current running time
                _uiState.update { it.copy(durationMillis = totalElapsed) }
                delay(1000L) // Update every second
            }
        }
    }

    private fun startLocationUpdates() {
        locationJob?.cancel() // Ensure previous job cancelled
        locationJob = viewModelScope.launch {
            try {
                locationService.startLocationUpdates() // Ensure service starts (implementation might vary)
                locationService.getLocationUpdates().collect { resource ->
                    when (resource) {
                        is Resource.Success<*> -> {
                            val newLocation = resource.data
                            if (newLocation != null && _trackingStatus.value == TrackingStatus.TRACKING) {
                                // Calculate distance and pace
                                if (previousLocation != null) {
                                    val distanceIncrement = previousLocation!!.distanceTo(newLocation)
                                    totalDistance += distanceIncrement

                                    val timeIncrementMillis = SystemClock.elapsedRealtime() - lastTimestamp
                                    val currentPace = if (distanceIncrement > 0 && timeIncrementMillis > 0) {
                                        calculatePaceMinPerKm(distanceIncrement, timeIncrementMillis)
                                    } else uiState.value.currentPaceMinPerKm // Keep last pace if no movement

                                    // Calculate average pace based on total distance and total time
                                    val totalDuration = elapsedTimeMillis + (SystemClock.elapsedRealtime() - startTimeMillis)
                                    val averagePace = if (totalDistance > 0 && totalDuration > 0) {
                                        calculatePaceMinPerKm(totalDistance, totalDuration)
                                    } else 0f

                                    _uiState.update {
                                        it.copy(
                                            distanceMeters = totalDistance,
                                            currentPaceMinPerKm = currentPace,
                                            averagePaceMinPerKm = averagePace,
                                            locationError = null
                                        )
                                    }
                                }
                                previousLocation = newLocation
                                lastTimestamp = SystemClock.elapsedRealtime()
                            }
                        }
                        is Resource.Error<*> -> {
                            _uiState.update { it.copy(locationError = resource.message ?: "Location update error") }
                            // Optionally pause or stop tracking on persistent errors?
                        }
                        is Resource.Loading<*> -> {
                            // Optional: Indicate loading state if needed
                        }
                        else -> {
                            // Handle unexpected Resource type
                            _uiState.update { it.copy(locationError = "Unexpected Resource type") }
                        }
                    }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(locationError = "Failed to start location updates: ${e.message}") }
                Log.e("RunningViewModel", "Location update error", e)
            }
        }
    }

    private fun stopLocationUpdates() {
        locationJob?.cancel()
        // It's important that the LocationService implementation actually stops updates
        // when the collecting flow is cancelled (which happens when locationJob is cancelled).
        // Explicitly calling might be needed depending on service impl:
        viewModelScope.launch { 
            try {
                locationService.stopLocationUpdates() 
            } catch (e: Exception) {
                Log.e("RunningViewModel", "Error stopping location updates", e)
            }
        }
        previousLocation = null // Reset for next start
    }

    private fun saveWorkoutSession(durationMillis: Long, distanceMeters: Double) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, saveError = null) }

            try {
                val request = SaveWorkoutRequest(
                    exercise_id = RUNNING_EXERCISE_ID, // Use snake_case parameter name
                    repetitions = null, // Not applicable for running
                    duration_seconds = TimeUnit.MILLISECONDS.toSeconds(durationMillis).toInt(),
                    completed_at = OffsetDateTime.now().toString() // Use current time as completion time
                )

                when (val result = workoutRepository.saveWorkout(request)) {
                    is Resource.Success<*> -> {
                        _uiState.update { it.copy(isSaving = false, saveError = null) }
                        Log.d("RunningViewModel", "Workout saved successfully: ${result.data?.id}")
                        // TODO: Trigger navigation event to go back or to workout detail
                        // e.g., _navigationEvent.emit(NavigationEvent.NavigateBack)
                        resetTrackingState() // Prepare for a new run
                    }
                    is Resource.Error<*> -> {
                        _uiState.update { it.copy(isSaving = false, saveError = result.message ?: "Failed to save workout") }
                        Log.e("RunningViewModel", "Failed to save workout: ${result.message}")
                    }
                    is Resource.Loading<*> -> { /* Saving in progress, do nothing or update UI */ }
                    else -> {
                        // Handle any unexpected Resource type
                        _uiState.update { it.copy(isSaving = false, saveError = "Unexpected result type") }
                    }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isSaving = false, saveError = "Error preparing workout: ${e.message}") }
                Log.e("RunningViewModel", "Error preparing workout for save", e)
            }
        }
    }

    fun updatePermissionStatus(granted: Boolean) {
        _uiState.update { it.copy(permissionGranted = granted) }
        if (!granted) {
            _uiState.update { it.copy(locationError = "Location permission is required.") }
            // Stop tracking if permissions are revoked mid-session
            if (_trackingStatus.value == TrackingStatus.TRACKING || _trackingStatus.value == TrackingStatus.PAUSED) {
                stopTracking() // Or maybe just pause? Stop seems safer.
            }
        } else {
            // Clear permission error if granted
            if (uiState.value.locationError == "Location permission is required.") {
                _uiState.update { it.copy(locationError = null) }
            }
        }
    }

    private fun resetTrackingState() {
        timerJob?.cancel()
        locationJob?.cancel()
        startTimeMillis = 0L
        elapsedTimeMillis = 0L
        lastTimestamp = 0L
        previousLocation = null
        totalDistance = 0f
        _uiState.update {
            it.copy(
                isTracking = false,
                durationMillis = 0L,
                distanceMeters = 0f,
                currentPaceMinPerKm = 0f,
                averagePaceMinPerKm = 0f,
                // Keep permission status, clear errors
                locationError = if (it.permissionGranted) null else it.locationError,
                isSaving = false,
                saveError = null
            )
        }
        _trackingStatus.value = TrackingStatus.IDLE
    }

    // Calculate pace in minutes per kilometer
    private fun calculatePaceMinPerKm(distanceMeters: Float, durationMillis: Long): Float {
        if (distanceMeters <= 0f || durationMillis <= 0L) return 0f
        val distanceKm = distanceMeters / 1000f
        val durationMinutes = durationMillis / (1000f * 60f)
        return durationMinutes / distanceKm
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        locationJob?.cancel()
        // Ensure location service stops updates if it doesn't rely solely on flow cancellation
        viewModelScope.launch { 
            try {
                locationService.stopLocationUpdates() 
            } catch (e: Exception) {
                Log.e("RunningViewModel", "Error stopping location updates in onCleared", e)
            }
        }
        Log.d("RunningTrackingViewModel", "onCleared called, resources released")
    }
} 