package com.example.ptchampion.ui.screens.camera

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.vision.core.RunningMode
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject
import androidx.camera.core.ImageProxy

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
    val isInitializing: Boolean = true // Track if PoseLandmarker is being set up
)

@HiltViewModel
class CameraViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel(), PoseLandmarkerHelper.LandmarkerListener {

    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    private lateinit var poseLandmarkerHelper: PoseLandmarkerHelper

    // Initialize the helper only once
    init {
        viewModelScope.launch(Dispatchers.IO) {
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
        }
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
        if (!::poseLandmarkerHelper.isInitialized || _uiState.value.isInitializing) {
            Log.w("CameraViewModel", "PoseLandmarkerHelper not ready, skipping frame.")
            // Need to close the proxy even if we skip processing
            try {
                imageProxy.close()
            } catch (e: IllegalStateException) {
                Log.e("CameraViewModel", "Error closing skipped ImageProxy", e)
            }
            return
        }
        
        // Ensure helper uses the correct executor if needed, but it handles internal threading for LIVE_STREAM
        poseLandmarkerHelper.detectLiveStream(imageProxy = imageProxy)

    }

    override fun onCleared() {
        super.onCleared()
        if (::poseLandmarkerHelper.isInitialized) {
            poseLandmarkerHelper.clearPoseLandmarker()
            Log.d("CameraViewModel", "PoseLandmarkerHelper cleared.")
        }
    }

    // --- PoseLandmarkerHelper.LandmarkerListener Callbacks --- //

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
        viewModelScope.launch {
            _uiState.update { 
                it.copy(poseLandmarkerResult = resultBundle, detectionError = null) // Clear previous detection error on new result
            }
            // Optional: Log result details here if needed for debugging
             // Log.d("CameraViewModel", "Pose Results Received: ${resultBundle.results.landmarks().size} landmarks")
        }
    }
} 