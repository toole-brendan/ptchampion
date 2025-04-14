package com.example.ptchampion.ui.screens.camera

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import androidx.camera.core.ImageProxy
import com.example.ptchampion.domain.exercise.ExerciseState
import androidx.lifecycle.SavedStateHandle
import com.example.ptchampion.domain.exercise.AnalysisResult
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.PullupAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.PushupAnalyzer
import com.example.ptchampion.domain.exercise.analyzers.SitupAnalyzer
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.util.Resource
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import androidx.camera.core.CameraSelector
import com.example.ptchampion.posedetection.RunningMode

// Define string constants for exercise types
object ExerciseTypes {
    const val PUSH_UPS = "pushups"
    const val PULL_UPS = "pullups"
    const val SIT_UPS = "situps"
    const val RUNNING = "running"
}

// Represents the state of the exercise tracking session
enum class SessionState {
    IDLE,       // Waiting to start
    RUNNING,    // Actively tracking
    PAUSED,     // Tracking paused
    STOPPED     // Session finished, ready to save/discard
}

// Represents the state of camera permissions
data class PermissionState(
    val hasPermission: Boolean = false,
    val shouldShowRationale: Boolean = false
)

// Represents the overall state for the CameraScreen
data class CameraUiState(
    val permissionState: PermissionState = PermissionState(),
    val poseLandmarkerResult: PoseLandmarkerHelper.ResultBundle? = null,
    val initializationError: String? = null,
    val detectionError: String? = null,
    val isInitializing: Boolean = true, // Track if PoseLandmarker is being set up
    val sessionState: SessionState = SessionState.IDLE,
    val repCount: Int = 0,
    val exerciseFeedback: String? = null,
    val formScore: Int = 0,
    val currentExerciseState: ExerciseState = ExerciseState.IDLE,
    val isSaving: Boolean = false, // Add saving state
    val saveError: String? = null, // Add save error state
    val saveSuccess: Boolean = false, // Add save success state
    val cameraSelectorSelected: Int = CameraSelector.LENS_FACING_BACK // Track current camera lens
)

// Define navigation events
sealed class CameraNavigationEvent {
    object NavigateBack : CameraNavigationEvent()
}

// @HiltViewModel // Remove Hilt annotation
class CameraViewModel constructor(
    // @ApplicationContext private val context: Context, // Remove context injection
    private val savedStateHandle: SavedStateHandle,
    // private val workoutRepository: WorkoutRepository // Remove repo injection
// ) : ViewModel(), PoseLandmarkerHelper.LandmarkerListener { // Remove listener interface
) : ViewModel() { // Simplify class signature

    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    // Channel for navigation events
    private val _navigationEvent = Channel<CameraNavigationEvent>()
    val navigationEvent = _navigationEvent.receiveAsFlow()

    // private lateinit var poseLandmarkerHelper: PoseLandmarkerHelper // Comment out MediaPipe Helper
    private var exerciseAnalyzer: ExerciseAnalyzer? = null
    private var sessionStartTime: Instant? = null

    // Extract arguments from SavedStateHandle
    private val exerciseTypeString: String? = savedStateHandle.get<String>("exerciseType")
    private val exerciseId: Int? = savedStateHandle.get<Int>("exerciseId")

    // Initialize the helper only once
    init {
        viewModelScope.launch(Dispatchers.IO) {
            // Initialize PoseLandmarkerHelper first
            // initializePoseLandmarker() // Comment out MediaPipe init
            _uiState.update { it.copy(isInitializing = false) } // Simulate initialization done

            // Then initialize the correct analyzer based on the exercise type
            if (exerciseTypeString != null) {
                exerciseAnalyzer = when (exerciseTypeString.lowercase()) {
                    ExerciseTypes.PUSH_UPS -> PushupAnalyzer()
                    ExerciseTypes.PULL_UPS -> PullupAnalyzer()
                    ExerciseTypes.SIT_UPS -> SitupAnalyzer()
                    else -> {
                        _uiState.update { it.copy(initializationError = "Unsupported exercise type: $exerciseTypeString") }
                        null
                    }
                }
                Log.d("CameraViewModel", "Initialized analyzer for: $exerciseTypeString")
            } else {
                _uiState.update {
                    it.copy(initializationError = "Exercise type not specified or invalid.")
                }
                Log.e("CameraViewModel", "Failed to initialize analyzer: Exercise type missing or invalid.")
            }
        }
    }

    // Extracted PoseLandmarker initialization logic
    private fun initializePoseLandmarker() {
        // TODO: Re-enable when MediaPipe dependencies are fixed
        /*
        try {
            poseLandmarkerHelper = PoseLandmarkerHelper(
                context = context,
                runningMode = RunningMode.LIVE_STREAM,
                poseLandmarkerHelperListener = this@CameraViewModel
            )
            _uiState.update {
                it.copy(isInitializing = false, initializationError = null)
            }
            Log.d("CameraViewModel", "PoseLandmarkerHelper initialized on IO thread.")
        } catch (e: Exception) {
            Log.e("CameraViewModel", "Error initializing PoseLandmarkerHelper", e)
            _uiState.update {
                it.copy(isInitializing = false, initializationError = "Failed to initialize pose detection.")
            }
        }
        */
    }

    fun onPermissionResult(granted: Boolean, shouldShowRationale: Boolean) {
        _uiState.update {
            it.copy(
                permissionState = PermissionState(
                    hasPermission = granted,
                    shouldShowRationale = !granted && shouldShowRationale
                )
            )
        }
        // TODO: Handle case where permission is permanently denied (!granted && !shouldShowRationale)
        //      Maybe navigate back or show a message directing to settings.
    }

    // Function to be called by the CameraScreen with each frame
    fun processFrame(imageProxy: ImageProxy) {
        // TODO: Re-enable when MediaPipe dependencies are fixed
        /*
        if (!::poseLandmarkerHelper.isInitialized || _uiState.value.isInitializing || exerciseAnalyzer == null) {
            Log.w("CameraViewModel", "Dependencies not ready, skipping frame. Initializing: ${_uiState.value.isInitializing}, Analyzer: ${exerciseAnalyzer == null}")
            closeImageProxy(imageProxy)
            return
        }

        // Only analyze if the session is running
        if (_uiState.value.sessionState == SessionState.RUNNING) {
            // Determine if the front camera is currently selected
            val isFrontCamera = _uiState.value.cameraSelectorSelected == CameraSelector.LENS_FACING_FRONT
            poseLandmarkerHelper.detectLiveStream(
                imageProxy = imageProxy,
                isFrontCamera = isFrontCamera // Pass the camera facing info
            )
        } else {
            // Close the proxy if not analyzing to prevent buffer buildup
            closeImageProxy(imageProxy)
        }
        */
        // Close proxy immediately since we are not processing
        closeImageProxy(imageProxy)
    }

    private fun closeImageProxy(imageProxy: ImageProxy) {
        try {
            imageProxy.close()
        } catch (e: IllegalStateException) {
            Log.e("CameraViewModel", "Error closing ImageProxy", e)
        }
    }

    // --- Session Control --- //

    fun startSession() {
        if (_uiState.value.sessionState == SessionState.IDLE || _uiState.value.sessionState == SessionState.PAUSED) {
             exerciseAnalyzer?.start() // Reset analyzer state
             sessionStartTime = Instant.now() // Record start time
            _uiState.update {
                it.copy(
                    sessionState = SessionState.RUNNING,
                    repCount = 0, // Reset UI state as well
                    exerciseFeedback = null,
                    formScore = 0,
                    currentExerciseState = ExerciseState.STARTING
                )
            }
            Log.i("CameraViewModel", "Exercise session started.")
        }
    }

    fun pauseSession() {
        if (_uiState.value.sessionState == SessionState.RUNNING) {
            _uiState.update { it.copy(sessionState = SessionState.PAUSED) }
            Log.i("CameraViewModel", "Exercise session paused.")
        }
    }

    fun stopSession() {
        if (_uiState.value.sessionState == SessionState.RUNNING || _uiState.value.sessionState == SessionState.PAUSED) {
            exerciseAnalyzer?.stop()
            val endTime = Instant.now()
            val startTime = sessionStartTime ?: endTime // Use endTime if startTime is somehow null
            val durationSeconds = java.time.Duration.between(startTime, endTime).seconds.toInt()
            val finalRepCount = _uiState.value.repCount

            _uiState.update { it.copy(sessionState = SessionState.STOPPED) }
            Log.i("CameraViewModel", "Exercise session stopped. Reps: $finalRepCount, Duration: $durationSeconds sec")

            // Trigger workout saving logic here
            saveWorkoutSession(finalRepCount, durationSeconds, endTime)
        }
    }

    private fun saveWorkoutSession(reps: Int, duration: Int, completedAt: Instant) {
        // Use the ID obtained from navigation arguments
        val currentExerciseId = exerciseId
        if (currentExerciseId == null || currentExerciseId == -1) { // Check for null or default value from NavHost
            Log.e("CameraViewModel", "Cannot save workout: invalid exercise ID ($currentExerciseId)")
            _uiState.update { it.copy(saveError = "Invalid Exercise ID", isSaving = false) }
            return
        }

        if (reps <= 0 && duration <= 0) {
            Log.i("CameraViewModel", "Workout session not saved: No reps or duration.")
            // No need to update UI state for this non-error case
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, saveError = null, saveSuccess = false) } // Set saving state
            kotlinx.coroutines.delay(1000) // Simulate save
            // TODO: Re-enable actual saving logic when DI is setup
            /*
            val request = SaveWorkoutRequest(
                exercise_id = currentExerciseId, // Use the actual ID
                repetitions = reps.takeIf { it > 0 },
                duration_seconds = duration.takeIf { it > 0 },
                completed_at = DateTimeFormatter.ISO_INSTANT.withZone(ZoneOffset.UTC).format(completedAt)
            )

            Log.d("CameraViewModel", "Attempting to save workout: $request")

            when (val result = workoutRepository.saveWorkout(request)) {
                is Resource.Success -> {
                    Log.i("CameraViewModel", "Workout saved successfully: ${result.data}")
                    _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
                    _navigationEvent.send(CameraNavigationEvent.NavigateBack) // Send navigation event
                }
                is Resource.Error -> {
                    Log.e("CameraViewModel", "Failed to save workout: ${result.message}")
                    val errorMessage = result.message ?: "Failed to save workout"
                    _uiState.update { it.copy(isSaving = false, saveError = errorMessage) }
                }
                is Resource.Loading -> {
                    // Handled by isSaving = true above
                }
            }
            */
            Log.i("CameraViewModel", "Workout saving bypassed.")
            _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
            _navigationEvent.send(CameraNavigationEvent.NavigateBack)
        }
    }

    // Add function to toggle camera lens
    fun toggleCameraLens() {
        val currentLens = _uiState.value.cameraSelectorSelected
        val newLens = if (currentLens == CameraSelector.LENS_FACING_BACK) {
            CameraSelector.LENS_FACING_FRONT
        } else {
            CameraSelector.LENS_FACING_BACK
        }
        _uiState.update { it.copy(cameraSelectorSelected = newLens) }
        Log.d("CameraViewModel", "Toggled camera lens to: ${if (newLens == CameraSelector.LENS_FACING_FRONT) "Front" else "Back"}")
    }

    override fun onCleared() {
        super.onCleared()
        // if (::poseLandmarkerHelper.isInitialized) { // Comment out MediaPipe clear
        //     poseLandmarkerHelper.clearPoseLandmarker()
        //     Log.d("CameraViewModel", "PoseLandmarkerHelper cleared.")
        // }
    }

    // --- PoseLandmarkerHelper.LandmarkerListener Callbacks --- //

    // Comment out the listener methods as the interface is removed
    /*
    override fun onError(error: String, errorCode: Int) {
        viewModelScope.launch {
             _uiState.update {
                 // Distinguish between init error and runtime detection error
                 if(errorCode == PoseLandmarkerHelper.ERROR_INIT_FAILED) {
                     it.copy(initializationError = error)
                 } else {
                     it.copy(detectionError = error) // Show detection errors transiently
                 }
             }
             Log.e("CameraViewModel", "PoseLandmarker Error: $error (Code: $errorCode)")
        }
    }

    override fun onResults(resultBundle: PoseLandmarkerHelper.ResultBundle) {
         // Only process results if the analyzer is ready and session is running
        val analyzer = exerciseAnalyzer
        if (analyzer == null || _uiState.value.sessionState != SessionState.RUNNING) {
             // Update with raw pose data for overlay, even if not analyzing reps
             viewModelScope.launch {
                  _uiState.update {
                      it.copy(poseLandmarkerResult = resultBundle)
                  }
             }
            return
        }

        viewModelScope.launch(Dispatchers.Default) { // Use Default dispatcher for analysis
            val analysisResult = analyzer.analyze(resultBundle)
            _uiState.update {
                it.copy(
                    poseLandmarkerResult = resultBundle, // Still update pose for overlay
                    detectionError = null,
                    repCount = analysisResult.repCount,
                    exerciseFeedback = analysisResult.feedback,
                    formScore = analysisResult.formScore,
                    currentExerciseState = analysisResult.state
                )
            }
        }
    }
    */
} 