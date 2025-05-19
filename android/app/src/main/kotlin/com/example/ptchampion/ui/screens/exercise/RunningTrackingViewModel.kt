package com.example.ptchampion.ui.screens.exercise

import android.app.Application
import android.location.Location
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.exercise.bluetooth.GpsLocation
import com.example.ptchampion.domain.exercise.bluetooth.ResourceHelpers
import com.example.ptchampion.domain.util.Resource
import com.example.ptchampion.domain.exercise.bluetooth.WatchDataRepository
import com.example.ptchampion.domain.service.ConnectionState
import com.example.ptchampion.domain.service.LocationService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import kotlin.math.roundToInt

/**
 * Tracking status for the running session
 */
enum class TrackingStatus {
    IDLE, RUNNING, PAUSED
}

/**
 * ViewModel for the running tracking screen
 */
@HiltViewModel
class RunningTrackingViewModel @Inject constructor(
    application: Application,
    private val locationService: LocationService,
    private val watchDataRepository: WatchDataRepository
) : AndroidViewModel(application) {
    
    private val TAG = "RunningTrackingViewModel"
    
    // UI state for the running tracking screen
    data class RunningUiState(
        val durationMillis: Long = 0L,
        val distanceMeters: Float = 0f,
        val currentPace: Float = 0f,
        val calories: Int = 0,
        val locationError: String? = null,
        val formattedDuration: String = "00:00",
        val formattedDistance: String = "0.00 km",
        val formattedPace: String = "--:--",
        val isSaving: Boolean = false,
        val saveError: String? = null
    )
    
    private val _uiState = MutableStateFlow(RunningUiState())
    val uiState: StateFlow<RunningUiState> = _uiState.asStateFlow()
    
    private val _trackingStatus = MutableStateFlow(TrackingStatus.IDLE)
    val trackingStatus: StateFlow<TrackingStatus> = _trackingStatus.asStateFlow()
    
    // Watch-specific state
    private val _watchConnectionState = MutableStateFlow(false)
    val watchConnectionState: StateFlow<Boolean> = _watchConnectionState.asStateFlow()
    
    private val _connectedWatchName = MutableStateFlow<String?>(null)
    val connectedWatchName: StateFlow<String?> = _connectedWatchName.asStateFlow()
    
    private val _watchBatteryLevel = MutableStateFlow<Int?>(null)
    val watchBatteryLevel: StateFlow<Int?> = _watchBatteryLevel.asStateFlow()
    
    private val _currentHeartRate = MutableStateFlow<Int?>(null)
    val currentHeartRate: StateFlow<Int?> = _currentHeartRate.asStateFlow()
    
    // Collection to store heart rate readings during exercise
    private val heartRateReadings = mutableListOf<Int>()
    
    // Tracking variables
    private var startTime: Long = 0
    private var lastUpdateTime: Long = 0
    private var elapsedTime: Long = 0
    private var pauseStartTime: Long = 0
    private var locations = mutableListOf<Location>()
    private var useWatchGpsData = false
    
    // Jobs for cancelable coroutines
    private var locationJob: Job? = null
    private var durationJob: Job? = null
    
    init {
        // Check if a watch is connected
        viewModelScope.launch {
            watchDataRepository.connectionState.collectLatest { state ->
                _watchConnectionState.value = state == ConnectionState.CONNECTED
                
                if (state == ConnectionState.CONNECTED) {
                    // Initialize watch data
                    // Fix: Comment out unresolved connectedDevice access
                    // watchDataRepository.connectedDevice.value?.let { device ->
                    //     _connectedWatchName.value = device.name
                    // }
                    checkWatchBatteryLevel()
                    
                    // Set data source preference
                    useWatchGpsData = true
                } else {
                    _connectedWatchName.value = null
                    _watchBatteryLevel.value = null
                    _currentHeartRate.value = null
                    useWatchGpsData = false
                }
            }
        }
    }
    
    private fun checkWatchBatteryLevel() {
        if (watchDataRepository.connectionState.value == ConnectionState.CONNECTED) {
            // In a real app, this would be retrieved from the watch
            // For now, just set a placeholder value
            _watchBatteryLevel.value = 75
        }
    }
    
    /**
     * Start tracking a running session
     */
    fun startTracking() {
        if (_trackingStatus.value != TrackingStatus.IDLE) return
        
        Log.d(TAG, "Starting running tracking")
        reset()
        
        startTime = System.currentTimeMillis()
        lastUpdateTime = startTime
        _trackingStatus.value = TrackingStatus.RUNNING
        
        // Start collecting heart rate data if a watch is connected
        if (_watchConnectionState.value) {
            startHeartRateCollection()
        }
        
        // Start tracking location
        startLocationUpdates()
        
        // Start tracking duration
        startDurationUpdates()
    }
    
    /**
     * Pause the running session
     */
    fun pauseTracking() {
        if (_trackingStatus.value != TrackingStatus.RUNNING) return
        
        Log.d(TAG, "Pausing running tracking")
        
        _trackingStatus.value = TrackingStatus.PAUSED
        pauseStartTime = System.currentTimeMillis()
        
        // Stop tracking location temporarily
        locationJob?.cancel()
        locationJob = null
    }
    
    /**
     * Resume the running session
     */
    fun resumeTracking() {
        if (_trackingStatus.value != TrackingStatus.PAUSED) return
        
        Log.d(TAG, "Resuming running tracking")
        
        // Calculate paused time
        val pauseDuration = System.currentTimeMillis() - pauseStartTime
        lastUpdateTime += pauseDuration
        
        _trackingStatus.value = TrackingStatus.RUNNING
        
        // Restart tracking location
        startLocationUpdates()
    }
    
    /**
     * Stop the running session
     */
    fun stopTracking() {
        if (_trackingStatus.value == TrackingStatus.IDLE) return
        
        Log.d(TAG, "Stopping running tracking")
        
        val wasRunning = _trackingStatus.value == TrackingStatus.RUNNING
        _trackingStatus.value = TrackingStatus.IDLE
        
        // Calculate final duration
        val endTime = System.currentTimeMillis()
        val finalDuration = if (wasRunning) {
            endTime - lastUpdateTime + elapsedTime
        } else {
            elapsedTime
        }
        
        // Cancel tracking jobs
        durationJob?.cancel()
        durationJob = null
        locationJob?.cancel()
        locationJob = null
        
        // Update UI with final values
        _uiState.update { 
            it.copy(
                durationMillis = finalDuration,
                formattedDuration = formatDuration(finalDuration)
            )
        }
        
        // Save workout data
        saveWorkoutSession(finalDuration, _uiState.value.distanceMeters.toDouble())
    }
    
    /**
     * Start tracking duration
     */
    private fun startDurationUpdates() {
        durationJob?.cancel()
        durationJob = viewModelScope.launch {
            while (true) {
                if (_trackingStatus.value == TrackingStatus.RUNNING) {
                    val currentTime = System.currentTimeMillis()
                    elapsedTime = currentTime - lastUpdateTime
                    
                    val totalDuration = elapsedTime
                    _uiState.update { 
                        it.copy(
                            durationMillis = totalDuration,
                            formattedDuration = formatDuration(totalDuration)
                        )
                    }
                }
                
                kotlinx.coroutines.delay(1000) // Update every second
            }
        }
    }
    
    /**
     * Start location updates - chooses between watch and phone GPS
     */
    private fun startLocationUpdates() {
        if (useWatchGpsData && _watchConnectionState.value) {
            startWatchLocationUpdates()
        } else {
            startPhoneLocationUpdates()
        }
    }
    
    /**
     * Start location updates from the watch
     */
    private fun startWatchLocationUpdates() {
        locationJob?.cancel()
        locationJob = viewModelScope.launch {
            watchDataRepository.getWatchLocation().collect { resource ->
                when (resource) {
                    is Resource.Success -> {
                        resource.data?.let { watchLocation ->
                            // Process location data for distance/pace calculations
                            processWatchLocation(watchLocation)
                        }
                    }
                    is Resource.Error -> {
                        // Fall back to phone GPS if watch GPS fails
                        if (useWatchGpsData) {
                            Log.d(TAG, "Watch GPS unavailable, falling back to phone")
                            useWatchGpsData = false
                            _uiState.update { 
                                it.copy(locationError = "Watch GPS unavailable, using phone") 
                            }
                            startPhoneLocationUpdates()
                        }
                    }
                    is Resource.Loading -> {
                        // Handle loading state
                    }
                }
            }
        }
    }
    
    /**
     * Start location updates from the phone
     */
    private fun startPhoneLocationUpdates() {
        locationJob?.cancel()
        locationJob = viewModelScope.launch {
            locationService.getLocationUpdates().collect { resource ->
                when (resource) {
                    is Resource.Success -> {
                        // No need for star projection or type casting since we know it's Resource<Location>
                        resource.data?.let { location -> 
                            processLocationUpdate(location)
                        }
                    }
                    is Resource.Error -> { 
                        Log.e(TAG, "Phone location error: ${resource.message}")
                        _uiState.update { 
                            it.copy(locationError = "Phone GPS error: ${resource.message}") 
                        }
                    }
                    is Resource.Loading -> {
                        // Handle loading state
                    }
                }
            }
        }
    }
    
    /**
     * Process watch location data
     */
    private fun processWatchLocation(watchLocation: GpsLocation) {
        // Convert watch location to Android Location object
        val location = Location("watch").apply {
            latitude = watchLocation.latitude
            longitude = watchLocation.longitude
            altitude = watchLocation.altitude ?: 0.0
            time = watchLocation.timestamp
            if (watchLocation.speed != null) {
                speed = watchLocation.speed
            }
        }
        
        processLocationUpdate(location)
    }
    
    /**
     * Process a location update
     */
    private fun processLocationUpdate(location: Location) {
        if (_trackingStatus.value != TrackingStatus.RUNNING) return
        
        // Add location to list
        locations.add(location)
        
        // Calculate distance
        if (locations.size > 1) {
            val lastLocation = locations[locations.size - 2]
            val distance = location.distanceTo(lastLocation)
            
            // Update total distance
            val totalDistance = _uiState.value.distanceMeters + distance
            
            // Calculate pace (min/km)
            val pace = calculatePace(totalDistance, elapsedTime)
            
            // Calculate calories (simple estimation)
            val calories = calculateCalories(totalDistance)
            
            // Update UI
            _uiState.update { 
                it.copy(
                    distanceMeters = totalDistance,
                    currentPace = pace,
                    calories = calories,
                    formattedDistance = formatDistance(totalDistance),
                    formattedPace = formatPace(pace)
                )
            }
        }
    }
    
    /**
     * Start collecting heart rate data from the watch
     */
    private fun startHeartRateCollection() {
        viewModelScope.launch {
            watchDataRepository.getWatchHeartRate().collect { resource ->
                if (resource is Resource.Success) {
                    val heartRate = resource.data
                    _currentHeartRate.value = heartRate
                    
                    // Store for later calculation
                    heartRate?.let { hr ->
                        heartRateReadings.add(hr)
                    }
                }
            }
        }
    }
    
    /**
     * Save a workout session
     */
    private fun saveWorkoutSession(durationMillis: Long, distanceMeters: Double) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, saveError = null) }
            
            try {
                // Start a workout session in the repository
                val result = watchDataRepository.startWorkoutSession()
                when (result) {
                    is Resource.Success -> {
                        val session = result.data
                        if (session != null) {
                            Log.d(TAG, "Started workout session: ${session.id}")
                            
                            // Stop the session to generate summary
                            val summaryResult = watchDataRepository.stopWorkoutSession()
                            when (summaryResult) {
                                is Resource.Success -> {
                                    Log.d(TAG, "Workout saved successfully")
                                }
                                is Resource.Error -> {
                                    Log.e(TAG, "Error saving workout: ${summaryResult.message}")
                                    _uiState.update { it.copy(saveError = summaryResult.message) }
                                }
                                is Resource.Loading -> {
                                    // Ignore loading state for stopWorkoutSession
                                }
                            }
                        } else {
                            Log.e(TAG, "Error: Started session was null")
                            _uiState.update { it.copy(saveError = "Error: Started session was null") }
                        }
                    }
                    is Resource.Error -> {
                        Log.e(TAG, "Error starting workout session: ${result.message}")
                        _uiState.update { it.copy(saveError = result.message) }
                    }
                    is Resource.Loading -> {
                        // Ignore loading state for startWorkoutSession
                    }
                }
                
                _uiState.update { it.copy(isSaving = false) }
            } catch (e: Exception) {
                Log.e(TAG, "Error saving workout", e)
                _uiState.update { 
                    it.copy(
                        isSaving = false,
                        saveError = "Error saving workout: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * Reset all tracking data
     */
    private fun reset() {
        startTime = 0
        lastUpdateTime = 0
        elapsedTime = 0
        pauseStartTime = 0
        locations.clear()
        heartRateReadings.clear()
        
        _uiState.update { 
            RunningUiState(
                formattedDuration = formatDuration(0),
                formattedDistance = formatDistance(0f),
                formattedPace = formatPace(0f)
            )
        }
    }
    
    /**
     * Calculate pace in minutes per kilometer
     */
    private fun calculatePace(distanceMeters: Float, durationMillis: Long): Float {
        if (distanceMeters <= 0 || durationMillis <= 0) return 0f
        
        val distanceKm = distanceMeters / 1000f
        val durationMinutes = durationMillis / 60000f
        
        return durationMinutes / distanceKm
    }
    
    /**
     * Calculate calories burned
     */
    private fun calculateCalories(distanceMeters: Float): Int {
        // Simple estimation: ~70 calories per km for an average runner
        return (distanceMeters * 0.07f).roundToInt()
    }
    
    /**
     * Calculate average heart rate from readings
     */
    private fun calculateAverageHeartRate(): Int? {
        return heartRateReadings.takeIf { it.isNotEmpty() }?.average()?.toInt()
    }
    
    /**
     * Calculate maximum heart rate from readings
     */
    private fun calculateMaxHeartRate(): Int? {
        return heartRateReadings.takeIf { it.isNotEmpty() }?.maxOrNull()
    }
    
    /**
     * Format duration in milliseconds to a string
     */
    private fun formatDuration(durationMillis: Long): String {
        val hours = TimeUnit.MILLISECONDS.toHours(durationMillis)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(durationMillis) % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(durationMillis) % 60
        
        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }
    }
    
    /**
     * Format distance in meters to a string
     */
    private fun formatDistance(distanceMeters: Float): String {
        return if (distanceMeters >= 1000) {
            String.format("%.2f km", distanceMeters / 1000)
        } else {
            String.format("%d m", distanceMeters.roundToInt())
        }
    }
    
    /**
     * Format pace in minutes per kilometer to a string
     */
    private fun formatPace(paceMinPerKm: Float): String {
        if (paceMinPerKm <= 0) return "--:--"
        
        val minutes = paceMinPerKm.toInt()
        val seconds = ((paceMinPerKm - minutes) * 60).toInt()
        
        return String.format("%d:%02d /km", minutes, seconds)
    }
    
    override fun onCleared() {
        super.onCleared()
        
        durationJob?.cancel()
        locationJob?.cancel()
    }
} 