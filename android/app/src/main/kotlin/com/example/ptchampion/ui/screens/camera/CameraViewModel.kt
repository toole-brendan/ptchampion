package com.example.ptchampion.ui.screens.camera

import android.app.Application
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.PushupAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.PullupAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.SitupAnalyzer
import com.example.ptchampion.domain.repository.ExerciseRepository
import com.example.ptchampion.domain.util.Resource
import com.example.ptchampion.posedetection.PoseDetectorProcessor
import com.example.ptchampion.posedetection.PoseProcessor
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class CameraViewModel @Inject constructor(
    application: Application,
    savedStateHandle: SavedStateHandle,
    private val exerciseRepository: ExerciseRepository
) : AndroidViewModel(application), PoseProcessor.PoseProcessorListener {

    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    private var _poseDetectorProcessor: PoseDetectorProcessor? = null
    val poseDetectorProcessor: PoseDetectorProcessor?
        get() = _poseDetectorProcessor

    private lateinit var exerciseAnalyzer: ExerciseAnalyzer

    private val exerciseId: Int = savedStateHandle.get<Int>("exerciseId") ?: -1
    private val exerciseTypeKey: String = savedStateHandle.get<String>("exerciseType") ?: "pushup"

    private var repCount = 0
    private var timerJob: kotlinx.coroutines.Job? = null
    
    init {
        Log.d("CameraViewModel", "Initializing for exerciseId: $exerciseId, type: $exerciseTypeKey")
        setupExerciseAnalyzer(exerciseTypeKey)
        setupPoseDetector()
        startTimer()
    }

    private fun setupExerciseAnalyzer(type: String) {
        // Create appropriate analyzer based on exercise type
        exerciseAnalyzer = when (type.lowercase()) {
            "pushup", "pushups" -> PushupAnalyzer()
            "pullup", "pullups" -> PullupAnalyzer()
            "situp", "situps" -> SitupAnalyzer()
            else -> PushupAnalyzer() // Default to pushup
        }
        
        _uiState.update { 
            it.copy(feedback = "Position yourself for ${type.replaceFirstChar { c -> c.uppercase() }}") 
        }
    }

    private fun setupPoseDetector() {
        viewModelScope.launch {
            try {
                _poseDetectorProcessor = PoseDetectorProcessor(
                    context = getApplication(),
                    runningMode = RunningMode.LIVE_STREAM,
                    listener = this@CameraViewModel
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
        timerJob?.cancel() // Cancel previous timer if any
        timerJob = viewModelScope.launch {
            while (true) {
                kotlinx.coroutines.delay(1000)
                if (!_uiState.value.isFinished) {
                    _uiState.update { it.copy(timerSeconds = it.timerSeconds + 1) }
                }
            }
        }
    }

    // Process pose detection results
    override fun onPoseDetected(result: PoseLandmarkerResult, timestampMs: Long) {
        if (_uiState.value.isFinished || _poseDetectorProcessor == null) return
        
        try {
            // Pass the result directly to the analyzer
            // The analyzer should handle conversion between PoseLandmarkerResult and MockNormalizedLandmark
            val analysisResult = exerciseAnalyzer.analyze(result)
            
            // Update UI state with analyzer results
            _uiState.update { 
                it.copy(
                    reps = analysisResult.repCount,
                    feedback = analysisResult.feedback ?: "Good form",
                    formScore = analysisResult.formScore.toFloat()
                )
            }
        } catch (e: Exception) {
            Log.e("CameraViewModel", "Error analyzing pose", e)
        }
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
        _poseDetectorProcessor?.setLensFacing(newLens)
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

            Log.d("CameraViewModel", "Saving workout - ID: $exerciseId, Reps: ${state.reps}, Duration: ${state.timerSeconds}, Form: ${state.formScore}")

            if (exerciseId == -1) {
                _uiState.update { it.copy(isLoadingSave = false, error = "Invalid Exercise ID. Cannot save.") }
                return@launch
            }

            val result = exerciseRepository.logExercise(
                exerciseId = exerciseId,
                reps = state.reps,
                duration = state.timerSeconds,
                distance = null,
                notes = null,
                formScore = state.formScore.toInt(),
                completed = true,
                deviceId = null
            )

            when (result) {
                is Resource.Success -> {
                    _uiState.update { it.copy(isLoadingSave = false, feedback = "Workout Saved Successfully!") }
                    Log.i("CameraViewModel", "Workout saved successfully: ${result.data}")
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(isLoadingSave = false, error = result.message ?: "Failed to save workout") }
                    Log.e("CameraViewModel", "Error saving workout: ${result.message}")
                }
                is Resource.Loading -> {
                    // Already handled
                }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        _poseDetectorProcessor?.close()
        timerJob?.cancel()
        Log.d("CameraViewModel", "ViewModel cleared, resources released.")
    }
}

data class CameraUiState(
    val reps: Int = 0,
    val formScore: Float = 85f,
    val timerSeconds: Int = 0,
    val feedback: String = "Ready",
    val isFinished: Boolean = false,
    val isLoadingSave: Boolean = false,
    val error: String? = null,
    val lensFacing: Int = CameraSelector.LENS_FACING_BACK
) 