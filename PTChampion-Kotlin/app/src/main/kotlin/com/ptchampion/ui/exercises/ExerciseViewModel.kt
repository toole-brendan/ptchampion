package com.ptchampion.ui.exercises

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.repository.AppRepository
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.RunData
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
 * UI state for exercise screen
 */
data class ExerciseUiState(
    val isLoading: Boolean = false,
    val exercise: Exercise? = null,
    val isExerciseStarted: Boolean = false,
    val isExerciseComplete: Boolean = false,
    val pushupState: PushupState = PushupState(),
    val pullupState: PullupState = PullupState(),
    val situpState: SitupState = SitupState(),
    val runData: RunData = RunData(),
    val useMediaPipeDetection: Boolean = false,
    val error: String? = null
)

/**
 * ViewModel for exercise screens
 */
@HiltViewModel
class ExerciseViewModel @Inject constructor(
    private val repository: AppRepository,
    private val poseDetectionManager: PoseDetectionManager
) : ViewModel() {
    
    init {
        // Initialize with current detection system setting
        _uiState.value = _uiState.value.copy(
            useMediaPipeDetection = poseDetectionManager.useMediaPipe
        )
    }
    
    private val _uiState = MutableStateFlow(ExerciseUiState(isLoading = true))
    val uiState: StateFlow<ExerciseUiState> = _uiState.asStateFlow()
    
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
                                isLoading = false,
                                exercise = exercise
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
     * Start exercise
     */
    fun startExercise() {
        _uiState.value = _uiState.value.copy(
            isExerciseStarted = true,
            isExerciseComplete = false
        )
    }
    
    /**
     * Update pushup state
     */
    fun updatePushupState(newState: PushupState) {
        _uiState.value = _uiState.value.copy(
            pushupState = newState
        )
    }
    
    /**
     * Update pullup state
     */
    fun updatePullupState(newState: PullupState) {
        _uiState.value = _uiState.value.copy(
            pullupState = newState
        )
    }
    
    /**
     * Update situp state
     */
    fun updateSitupState(newState: SitupState) {
        _uiState.value = _uiState.value.copy(
            situpState = newState
        )
    }
    
    /**
     * Update run data
     */
    fun updateRunData(newData: RunData) {
        _uiState.value = _uiState.value.copy(
            runData = newData
        )
    }
    
    /**
     * Complete exercise
     */
    fun completeExercise(exerciseType: String, reps: Int? = null, timeInSeconds: Int? = null, distance: Double? = null) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        
        viewModelScope.launch {
            repository.saveUserExercise(
                exerciseType = exerciseType,
                reps = reps,
                timeInSeconds = timeInSeconds,
                distance = distance
            )
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to save exercise: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isExerciseComplete = true
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to save exercise: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Clear error
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    /**
     * Toggle between ML Kit and MediaPipe pose detection
     */
    fun togglePoseDetection() {
        val useMediaPipe = poseDetectionManager.toggleDetectionSystem()
        _uiState.value = _uiState.value.copy(
            useMediaPipeDetection = useMediaPipe
        )
    }
}
