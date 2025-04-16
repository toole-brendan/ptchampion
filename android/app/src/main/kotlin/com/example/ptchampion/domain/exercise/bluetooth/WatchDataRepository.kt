package com.example.ptchampion.domain.exercise.bluetooth

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository interface for accessing watch fitness data
 */
interface WatchDataRepository {
    // Get current GPS data
    fun getWatchLocation(): Flow<Resource<GpsLocation>>
    
    // Get watch heart rate data
    fun getWatchHeartRate(): Flow<Resource<Int>>
    
    // Get workout metrics (pace, distance, etc.)
    fun getWorkoutMetrics(): Flow<Resource<RunningMetrics>>
    
    // Session management
    suspend fun startWorkoutSession(): Resource<WorkoutSession>
    suspend fun pauseWorkoutSession(): Resource<Unit>
    suspend fun resumeWorkoutSession(): Resource<Unit>
    suspend fun stopWorkoutSession(): Resource<WorkoutSummary>
    
    // Get current workout session if active
    val currentSession: StateFlow<WorkoutSession?>
    
    // Get connection state
    val connectionState: StateFlow<com.example.ptchampion.domain.service.ConnectionState>
    
    // Bluetooth device operations
    suspend fun startDeviceScan()
    suspend fun stopDeviceScan()
    suspend fun connectToDevice(address: String): Resource<Unit>
    suspend fun disconnectFromDevice(): Resource<Unit>
    
    // Get discovered devices
    val discoveredDevices: StateFlow<List<com.example.ptchampion.domain.service.BleDevice>>
}

/**
 * Implementation of the WatchDataRepository
 */
@Singleton
class WatchDataRepositoryImpl @Inject constructor(
    private val gpsWatchService: GpsWatchService,
    private val metricsProcessor: RunningMetricsProcessor
) : WatchDataRepository {
    
    private val TAG = "WatchDataRepository"
    
    private val repositoryScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    private val _currentSession = MutableStateFlow<WorkoutSession?>(null)
    override val currentSession: StateFlow<WorkoutSession?> = _currentSession.asStateFlow()
    
    // Maps to expose service properties
    override val connectionState = gpsWatchService.connectionState
    override val discoveredDevices = gpsWatchService.discoveredWatches
    
    init {
        // Set up data processing when location updates
        observeLocationUpdates()
    }
    
    private fun observeLocationUpdates() {
        repositoryScope.launch {
            gpsWatchService.watchGpsData.collect { location ->
                // Process location updates when we have an active session
                if (location != null && _currentSession.value?.isActive == true) {
                    updateSessionWithLocation(location)
                }
            }
        }
    }
    
    private fun updateSessionWithLocation(location: GpsLocation) {
        val session = _currentSession.value ?: return
        
        // Update the session with the new location
        // Since we're using a data class with vars, we need to create a new instance to trigger Flow updates
        val updatedLocations = session.locationPoints.toMutableList()
        updatedLocations.add(location)
        
        _currentSession.value = session.copy(locationPoints = updatedLocations)
    }
    
    override fun getWatchLocation(): Flow<Resource<GpsLocation>> = flow {
        // Start with loading state
        emit(Resource.loading())
        
        // Then map location updates to resource states
        gpsWatchService.watchGpsData.collect { location ->
            if (location != null) {
                emit(Resource.success(location))
            } else {
                emit(Resource.error("No GPS data available from watch"))
            }
        }
    }
    
    override fun getWatchHeartRate(): Flow<Resource<Int>> = flow {
        emit(Resource.loading())
        
        gpsWatchService.watchHeartRate.collect { heartRate ->
            if (heartRate != null) {
                emit(Resource.success(heartRate))
            } else {
                emit(Resource.error("No heart rate data available from watch"))
            }
        }
    }
    
    override fun getWorkoutMetrics(): Flow<Resource<RunningMetrics>> = flow {
        emit(Resource.loading())
        
        // Combine location and heart rate data
        gpsWatchService.watchGpsData
            .combine(gpsWatchService.watchHeartRate) { location, heartRate ->
                Pair(location, heartRate)
            }
            .collect { (location, heartRate) ->
                if (location != null) {
                    val metrics = metricsProcessor.processNewLocation(location, heartRate)
                    emit(Resource.success(metrics))
                } else {
                    emit(Resource.error("No location data available to calculate metrics"))
                }
            }
    }
    
    override suspend fun startWorkoutSession(): Resource<WorkoutSession> {
        // Check if a session is already in progress
        if (_currentSession.value != null && _currentSession.value?.isActive == true) {
            return Resource.error("A workout session is already in progress")
        }
        
        // Reset the metrics processor
        metricsProcessor.reset()
        
        // Create a new session
        val newSession = WorkoutSession()
        _currentSession.value = newSession
        
        Log.d(TAG, "Started new workout session: ${newSession.id}")
        return Resource.success(newSession)
    }
    
    override suspend fun pauseWorkoutSession(): Resource<Unit> {
        val session = _currentSession.value ?: return Resource.error("No active workout session")
        
        session.pause()
        // Update to trigger state flow
        _currentSession.value = session.copy()
        
        Log.d(TAG, "Paused workout session: ${session.id}")
        return Resource.success(Unit)
    }
    
    override suspend fun resumeWorkoutSession(): Resource<Unit> {
        val session = _currentSession.value ?: return Resource.error("No workout session to resume")
        
        session.resume()
        // Update to trigger state flow
        _currentSession.value = session.copy()
        
        Log.d(TAG, "Resumed workout session: ${session.id}")
        return Resource.success(Unit)
    }
    
    override suspend fun stopWorkoutSession(): Resource<WorkoutSummary> {
        val session = _currentSession.value ?: return Resource.error("No workout session to stop")
        
        // End the session
        session.end()
        
        // Generate summary
        val summary = metricsProcessor.generateWorkoutSummary(session.id)
            ?: return Resource.error("Failed to generate workout summary")
        
        // Clear current session
        _currentSession.value = null
        
        Log.d(TAG, "Stopped workout session: ${session.id}")
        return Resource.success(summary)
    }
    
    override suspend fun startDeviceScan() {
        gpsWatchService.startScan()
    }
    
    override suspend fun stopDeviceScan() {
        gpsWatchService.stopScan()
    }
    
    override suspend fun connectToDevice(address: String): Resource<Unit> {
        try {
            gpsWatchService.connectToWatch(address)
            return Resource.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to device", e)
            return Resource.error("Failed to connect: ${e.message}")
        }
    }
    
    override suspend fun disconnectFromDevice(): Resource<Unit> {
        try {
            gpsWatchService.disconnectFromWatch()
            return Resource.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from device", e)
            return Resource.error("Failed to disconnect: ${e.message}")
        }
    }
} 