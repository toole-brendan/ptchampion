package com.example.ptchampion.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.Image
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.nio.ByteBuffer

/**
 * Processor for MediaPipe Pose Detection
 * Simplified with stubs to avoid MediaPipe compatibility issues
 */
class PoseDetectorProcessor(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.LIVE_STREAM,
    private val showConfidence: Boolean = true,
    private val poseProcessorListener: PoseProcessor.PoseProcessorListener
) : PoseProcessor, PoseLandmarkerHelper.LandmarkerListener {

    companion object {
        private const val TAG = "PoseDetectorProcessor"
    }

    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null
    private var initialized = false
    private var lensFacing = 0 // Default camera direction

    override fun initialize() {
        try {
            poseLandmarkerHelper = PoseLandmarkerHelper(
                context = context,
                runningMode = runningMode,
                minPoseDetectionConfidence = 0.5f,
                minPoseTrackingConfidence = 0.5f,
                minPosePresenceConfidence = 0.5f,
                currentModel = PoseLandmarkerHelper.MODEL_FULL,
                resultListener = this
            )
            initialized = true
            Log.d(TAG, "Model initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing pose landmarker: ${e.message}")
            poseProcessorListener.onError("Error initializing pose detector: ${e.message}", -1)
            initialized = false
        }
    }

    override fun isInitialized(): Boolean = initialized

    override fun processImageProxy(imageProxy: ImageProxy, rotationDegrees: Int) {
        if (!initialized || poseLandmarkerHelper == null) {
            imageProxy.close()
            return
        }

        try {
            poseLandmarkerHelper?.detectLiveStream(imageProxy)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing image: ${e.message}")
            poseProcessorListener.onError("Error processing image: ${e.message}", -1)
            imageProxy.close()
        }
    }

    override fun setLensFacing(lensFacing: Int) {
        this.lensFacing = lensFacing
    }

    override fun close() {
        try {
            poseLandmarkerHelper?.clearPoseLandmarker()
            initialized = false
        } catch (e: Exception) {
            Log.e(TAG, "Error closing pose landmarker: ${e.message}")
        }
    }

    // PoseLandmarkerHelper.LandmarkerListener implementation
    override fun onError(error: String, errorCode: Int) {
        poseProcessorListener.onError(error, errorCode)
    }

    override fun onResults(resultBundle: PoseLandmarkerHelper.ResultBundle) {
        // Forward the results to the PoseProcessor listener
        poseProcessorListener.onPoseDetected(resultBundle.results, System.currentTimeMillis())
    }
} 