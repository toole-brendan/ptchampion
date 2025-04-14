package com.example.ptchampion.ui.screens.camera

import android.app.Application
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.ExerciseRepository
import com.example.ptchampion.domain.util.Resource
import com.example.ptchampion.posedetection.ExerciseAnalyzer
import com.example.ptchampion.posedetection.ExerciseType
import com.example.ptchampion.posedetection.PoseDetectorProcessor
import com.example.ptchampion.posedetection.PoseProcessor
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

// Data class to hold all state relevant to the Camera Screen UI
data class CameraUiState(
    val lensFacing: Int = CameraSelector.LENS_FACING_FRONT,
    val reps: Int = 0,
    val timerSeconds: Int = 0,
    val feedback: String = "Initializing...",
    val formScore: Double = 100.0, // Overall form score
    val isFinished: Boolean = false,
    val error: String? = null,
    val isLoadingSave: Boolean = false // For showing loading during save
)

@HiltViewModel
class CameraViewModel @Inject constructor(
    application: Application,
    savedStateHandle: SavedStateHandle,
    private val exerciseRepository: ExerciseRepository // Inject repository
) : AndroidViewModel(application), PoseProcessor.PoseProcessorListener {

    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    private var poseDetectorProcessor: PoseDetectorProcessor? = null
    private lateinit var exerciseAnalyzer: ExerciseAnalyzer

    private val exerciseId: Int = savedStateHandle.get<Int>("exerciseId") ?: -1
    private val exerciseApiType: String = savedStateHandle.get<String>("exerciseType") ?: "unknown"

    init {
        Log.d("CameraViewModel", "Initializing for exerciseId: $exerciseId, type: $exerciseApiType")
        setupExerciseAnalyzer(exerciseApiType)
        setupPoseDetector()
        startTimer()
    }

    private fun setupExerciseAnalyzer(type: String) {
        val exerciseType = when (type.lowercase()) {
            "pushups", "pushup" -> ExerciseType.PUSH_UPS
            "situps", "situp" -> ExerciseType.SIT_UPS
            "pullups", "pullup" -> ExerciseType.PULL_UPS
            // Add other types if needed
            else -> ExerciseType.PUSH_UPS // Default or throw error
        }
        exerciseAnalyzer = ExerciseAnalyzer(exerciseType) {
            reps, feedbackMessage, currentFormScore ->
            _uiState.update {
                it.copy(
                    reps = reps,
                    feedback = feedbackMessage,
                    formScore = currentFormScore
                )
            }
        }
        _uiState.update { it.copy(feedback = "Position yourself for ${exerciseType.name.replace('_', ' ')}") }
    }

    private fun setupPoseDetector() {
        viewModelScope.launch {
            try {
                poseDetectorProcessor = PoseDetectorProcessor(
                    context = getApplication(),
                    runningMode = RunningMode.LIVE_STREAM,
                    showConfidence = true, // Example configuration
                    poseProcessorListener = this@CameraViewModel
                ).also {
                    it.initialize()
                }
                Log.d("CameraViewModel", "PoseDetectorProcessor setup complete.")
            } catch (e: Exception) {
                Log.e("CameraViewModel", "Error setting up Pose Detector", e)
                _uiState.update { it.copy(error = "Failed to initialize pose detector: ${e.message}") }
            }
        }
    }

    private fun startTimer() {
        viewModelScope.launch {
            // Simple timer, replace with more robust implementation if needed
            while (true) {
                 kotlinx.coroutines.delay(1000)
                 if (!_uiState.value.isFinished) {
                     _uiState.update { it.copy(timerSeconds = it.timerSeconds + 1) }
                 }
            }
        }
    }

    fun processFrame(result: PoseLandmarkerResult, timestampMs: Long) {
         // Don't process if finished or detector not ready
         if (_uiState.value.isFinished || poseDetectorProcessor == null) return
         exerciseAnalyzer.processPoseResult(result)
    }

    override fun onPoseDetected(result: PoseLandmarkerResult, timestampMs: Long) {
        processFrame(result, timestampMs)
    }

    override fun onError(error: String, errorCode: Int) {
        Log.e("CameraViewModel", "Pose detection error ($errorCode): $error")
        _uiState.update { it.copy(error = "Pose detection error: $error") }
    }

    fun switchCamera() {
        val currentLens = _uiState.value.lensFacing
        val newLens = if (currentLens == CameraSelector.LENS_FACING_FRONT) {
            CameraSelector.LENS_FACING_BACK
        } else {
            CameraSelector.LENS_FACING_FRONT
        }
        _uiState.update { it.copy(lensFacing = newLens) }
        // Re-setup detector or notify CameraX view to use new lens
        // poseDetectorProcessor?.setLensFacing(newLens) // Assuming processor handles this
        Log.d("CameraViewModel", "Switching camera to: ${if (newLens == 1) "FRONT" else "BACK"}")
        // Note: Actual camera switching is handled by CameraX setup in the Composable
    }

    fun finishWorkout() {
        _uiState.update { it.copy(isFinished = true, feedback = "Workout Complete!") }
        saveWorkout()
    }

    private fun saveWorkout() {
        if (_uiState.value.isLoadingSave) return // Prevent multiple saves

        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingSave = true, error = null) }
            val state = _uiState.value

            Log.d("CameraViewModel", "Attempting to save workout - ID: $exerciseId, Reps: ${state.reps}, Duration: ${state.timerSeconds}, Form: ${state.formScore}")

            if (exerciseId == -1) {
                _uiState.update { it.copy(isLoadingSave = false, error = "Invalid Exercise ID. Cannot save.") }
                Log.e("CameraViewModel", "Invalid Exercise ID (-1) received. Cannot save.")
                return@launch
            }

            val result = exerciseRepository.logExercise(
                exerciseId = exerciseId,
                reps = state.reps,
                duration = state.timerSeconds,
                formScore = state.formScore.toInt(), // Convert form score to Int (0-100)
                completed = true,
                distance = null, // Not applicable for non-running
                notes = "Logged from Android App", // Optional notes
                deviceId = null // Optional device ID
            )

            when (result) {
                is Resource.Success -> {
                    _uiState.update { it.copy(isLoadingSave = false, feedback = "Workout Saved Successfully!") }
                    Log.i("CameraViewModel", "Workout saved successfully: ${result.data}")
                    // Consider adding a small delay before navigating back or triggering navigation via effect
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(isLoadingSave = false, error = result.message ?: "Failed to save workout") }
                    Log.e("CameraViewModel", "Error saving workout: ${result.message}")
                }
                else -> {
                    // Loading state handled by isLoadingSave
                }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        poseDetectorProcessor?.close()
        Log.d("CameraViewModel", "ViewModel cleared, PoseDetectorProcessor closed.")
    }
} 