package com.ptchampion.ui.exercises

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.bluetooth.BluetoothManager
import com.ptchampion.data.repository.AppRepository
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.SitupState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Exercise UI state
 */
data class ExerciseUiState(
    val isLoading: Boolean = false,
    val exercise: Exercise? = null,
    val pushupState: PushupState = PushupState(),
    val pullupState: PullupState = PullupState(),
    val situpState: SitupState = SitupState(),
    val isExerciseStarted: Boolean = false,
    val isExerciseComplete: Boolean = false,
    val saveInProgress: Boolean = false,
    val error: String? = null,
    val runTime: Int = 0,
    val runDistance: Double = 0.0,
    val heartRate: Int = 0
)

/**
 * ViewModel for exercise screens
 */
@HiltViewModel
class ExerciseViewModel @Inject constructor(
    private val repository: AppRepository,
    private val bluetoothManager: BluetoothManager,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ExerciseUiState(isLoading = true))
    val uiState: StateFlow<ExerciseUiState> = _uiState.asStateFlow()
    
    init {
        // Get exerciseId from saved state
        savedStateHandle.get<String>("exerciseId")?.toIntOrNull()?.let { exerciseId ->
            loadExercise(exerciseId)
        }
        
        // Collect Bluetooth service data
        viewModelScope.launch {
            bluetoothManager.serviceData.collect { serviceData ->
                _uiState.value = _uiState.value.copy(
                    heartRate = serviceData.heartRate,
                    runTime = serviceData.timeElapsed,
                    runDistance = serviceData.distance
                )
            }
        }
    }
    
    /**
     * Load exercise data
     */
    fun loadExercise(exerciseId: Int) {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.getExerciseById(exerciseId)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load exercise: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { exercise ->
                            _uiState.value = _uiState.value.copy(
                                exercise = exercise,
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load exercise: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Start the exercise
     */
    fun startExercise() {
        _uiState.value = _uiState.value.copy(
            isExerciseStarted = true,
            isExerciseComplete = false
        )
        
        // If this is a running exercise, start the Bluetooth connections and timer
        if (_uiState.value.exercise?.type == "run") {
            // Start run timer
            bluetoothManager.resetServiceData()
            bluetoothManager.startRunningTimer()
            
            // Start scanning for heart rate monitors
            bluetoothManager.startScan()
        }
    }
    
    /**
     * Update pushup state
     */
    fun updatePushupState(newState: PushupState) {
        _uiState.value = _uiState.value.copy(pushupState = newState)
    }
    
    /**
     * Update pullup state
     */
    fun updatePullupState(newState: PullupState) {
        _uiState.value = _uiState.value.copy(pullupState = newState)
    }
    
    /**
     * Update situp state
     */
    fun updateSitupState(newState: SitupState) {
        _uiState.value = _uiState.value.copy(situpState = newState)
    }
    
    /**
     * Complete an exercise and save the result
     */
    fun completeExercise(
        reps: Int? = null,
        timeInSeconds: Int? = null,
        distance: Double? = null
    ) {
        val exercise = _uiState.value.exercise ?: return
        
        // Calculate score based on exercise type
        val score = calculateScore(exercise.type, reps, timeInSeconds)
        
        _uiState.value = _uiState.value.copy(
            isExerciseComplete = true,
            isExerciseStarted = false,
            saveInProgress = true
        )
        
        // Save the result
        viewModelScope.launch {
            repository.createUserExercise(
                exerciseId = exercise.id,
                type = exercise.type,
                reps = reps,
                timeInSeconds = timeInSeconds,
                distance = distance,
                score = score
            )
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        saveInProgress = false,
                        error = "Failed to save exercise: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(saveInProgress = false)
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                saveInProgress = false,
                                error = "Failed to save exercise: ${e.message}"
                            )
                        }
                    )
                }
        }
        
        // Clean up Bluetooth connections if running
        if (exercise.type == "run") {
            bluetoothManager.stopScan()
            bluetoothManager.disconnectAll()
        }
    }
    
    /**
     * Calculate score based on exercise type
     */
    private fun calculateScore(
        exerciseType: String,
        reps: Int? = null,
        timeInSeconds: Int? = null
    ): Int {
        return when (exerciseType) {
            "pushup" -> calculatePushupScore(reps ?: 0)
            "pullup" -> calculatePullupScore(reps ?: 0)
            "situp" -> calculateSitupScore(reps ?: 0)
            "run" -> calculateRunScore(timeInSeconds ?: 0)
            else -> 0
        }
    }
    
    /**
     * Calculate pushup score
     * - 100 points = 77 reps
     * - 50 points = 40 reps
     */
    private fun calculatePushupScore(reps: Int): Int {
        return when {
            reps >= 77 -> 100
            reps <= 0 -> 0
            else -> ((reps - 3) * 100) / 74
        }.coerceIn(0, 100)
    }
    
    /**
     * Calculate situp score
     * - 100 points = 78 reps
     * - 50 points = 47 reps
     */
    private fun calculateSitupScore(reps: Int): Int {
        return when {
            reps >= 78 -> 100
            reps <= 0 -> 0
            else -> ((reps - 16) * 100) / 62
        }.coerceIn(0, 100)
    }
    
    /**
     * Calculate pullup score
     * - 100 points = 20 reps
     * - 50 points = 8 reps
     */
    private fun calculatePullupScore(reps: Int): Int {
        return when {
            reps >= 20 -> 100
            reps <= 0 -> 0
            else -> (reps * 100) / 20
        }.coerceIn(0, 100)
    }
    
    /**
     * Calculate run score
     * - 100 points = 13:00 (780 seconds) or less
     * - 50 points = 16:36 (996 seconds)
     */
    private fun calculateRunScore(timeInSeconds: Int): Int {
        return when {
            timeInSeconds <= 780 -> 100
            timeInSeconds >= 1212 -> 0
            else -> ((1212 - timeInSeconds) * 100) / 432
        }.coerceIn(0, 100)
    }
    
    /**
     * Connect to a Bluetooth device
     */
    fun connectToDevice(deviceId: String) {
        bluetoothManager.connectToDevice(deviceId)
    }
    
    /**
     * Disconnect from a Bluetooth device
     */
    fun disconnectDevice(deviceId: String) {
        bluetoothManager.disconnectDevice(deviceId)
    }
    
    /**
     * Get available Bluetooth devices
     */
    fun getAvailableDevices() = bluetoothManager.availableDevices
    
    /**
     * Clear error
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    override fun onCleared() {
        super.onCleared()
        // Clean up Bluetooth resources
        bluetoothManager.stopScan()
        bluetoothManager.disconnectAll()
    }
}