package com.example.ptchampion.posedetection

import android.content.Context
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Processor for MediaPipe Pose Detection
 * Simplified with stubs to avoid MediaPipe compatibility issues
 */
class PoseDetectorProcessor(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.LIVE_STREAM,
    // showConfidence is not used in this implementation, can be removed if not needed elsewhere
    // private val showConfidence: Boolean = true, 
    override var listener: PoseProcessor.PoseProcessorListener?
) : PoseProcessor, PoseLandmarkerHelper.LandmarkerListener {

    companion object {
        private const val TAG = "PoseDetectorProcessor"
    }

    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null
    private val isInitialized = AtomicBoolean(false)
    private var currentLensFacing = 0 // Store lens facing for potential re-initialization

    override fun initialize() {
        if (isInitialized.get()) {
            Log.d(TAG, "Already initialized.")
            return
        }
        try {
            // Ensure helper is null before creating a new one
            poseLandmarkerHelper?.clearPoseLandmarker()
            poseLandmarkerHelper = null
            
            poseLandmarkerHelper = PoseLandmarkerHelper(
                context = context,
                runningMode = runningMode,
                minPoseDetectionConfidence = 0.5f,
                minPoseTrackingConfidence = 0.5f, // Adjust confidence as needed
                minPosePresenceConfidence = 0.5f,
                currentModel = PoseLandmarkerHelper.MODEL_LITE, // Use LITE for performance
                resultListener = this
                // Delegate can be added here if needed (e.g., Delegate.GPU)
            )
            isInitialized.set(true)
            Log.d(TAG, "PoseDetectorProcessor initialized successfully.")
        } catch (e: Exception) {
            val errorMessage = "Error initializing PoseLandmarkerHelper: ${e.message}"
            Log.e(TAG, errorMessage, e)
            listener?.onError(errorMessage, -1)
            isInitialized.set(false)
        }
    }

    override fun isInitialized(): Boolean = isInitialized.get()

    override fun processImageProxy(imageProxy: ImageProxy, rotationDegrees: Int) {
        if (!isInitialized.get()) {
            Log.w(TAG, "Processor not initialized, cannot process image.")
            // Attempt to initialize again?
            // initialize()
            // if (!isInitialized.get()) { ... }
            imageProxy.close() // Close if not initialized
            return
        }

        if (poseLandmarkerHelper == null) {
             Log.e(TAG, "PoseLandmarkerHelper is null despite being initialized.")
             listener?.onError("Internal error: PoseLandmarkerHelper is null", -1)
             imageProxy.close()
             return
        }
        
        // rotationDegrees is not directly used by detectLiveStream in PoseLandmarkerHelper
        // but might be needed if implementing rotation logic inside the helper
        try {
            // Delegate processing to the helper
            poseLandmarkerHelper?.detectLiveStream(imageProxy) 
            // Note: imageProxy is closed inside detectLiveStream
        } catch (e: Exception) {
            val errorMessage = "Error processing image: ${e.message}"
            Log.e(TAG, errorMessage, e)
            listener?.onError(errorMessage, -1)
            // Ensure imageProxy is closed on error if detectLiveStream didn't close it
            try { imageProxy.close() } catch (ignored: Exception) {}
        }
    }

    override fun setLensFacing(lensFacing: Int) {
        // Store lens facing. Could potentially re-initialize the helper if needed 
        // based on lens facing (e.g., different model or settings)
        this.currentLensFacing = lensFacing
        // Example: If lens facing changes, re-initialize
        // if (isInitialized.get()) { 
        //     Log.d(TAG, "Lens facing changed, re-initializing...")
        //     close() // Close current helper
        //     initialize() // Initialize new one
        // }
    }

    override fun close() {
        if (isInitialized.compareAndSet(true, false)) {
            Log.d(TAG, "Closing PoseDetectorProcessor.")
            try {
                poseLandmarkerHelper?.clearPoseLandmarker()
                poseLandmarkerHelper = null
            } catch (e: Exception) {
                Log.e(TAG, "Error closing PoseLandmarkerHelper: ${e.message}", e)
            }
        } else {
             Log.d(TAG, "Processor already closed or not initialized.")
        }
    }

    // PoseLandmarkerHelper.LandmarkerListener implementation
    override fun onError(error: String, errorCode: Int) {
        // Forward errors from the helper to the processor's listener
        listener?.onError(error, errorCode)
    }

    override fun onResults(resultBundle: PoseLandmarkerHelper.ResultBundle) {
        // Forward results from the helper to the processor's listener
        // Using System.currentTimeMillis() as timestampMs, as it's not provided by detectAsync
        listener?.onPoseDetected(resultBundle.results, System.currentTimeMillis())
    }
} 