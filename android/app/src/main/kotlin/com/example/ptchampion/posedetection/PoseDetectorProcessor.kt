package com.example.ptchampion.posedetection

import android.content.Context
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Processor for MediaPipe Pose Detection using the PoseLandmarker Task API
 */
class PoseDetectorProcessor(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.LIVE_STREAM,
    override var listener: PoseProcessor.PoseProcessorListener?
) : PoseProcessor, PoseLandmarkerHelper.LandmarkerListener {

    companion object {
        private const val TAG = "PoseDetectorProcessor"
        private const val DEFAULT_POSE_DETECTION_CONFIDENCE = 0.5f
        private const val DEFAULT_POSE_TRACKING_CONFIDENCE = 0.5f
        private const val DEFAULT_POSE_PRESENCE_CONFIDENCE = 0.5f
    }

    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null
    private val isInitialized = AtomicBoolean(false)
    private var lensFacing = 0

    init {
        initialize()
    }

    override fun initialize() {
        try {
            poseLandmarkerHelper = PoseLandmarkerHelper(
                context = context,
                runningMode = runningMode,
                minPoseDetectionConfidence = DEFAULT_POSE_DETECTION_CONFIDENCE,
                minPoseTrackingConfidence = DEFAULT_POSE_TRACKING_CONFIDENCE,
                minPosePresenceConfidence = DEFAULT_POSE_PRESENCE_CONFIDENCE,
                resultListener = this
            )
            isInitialized.set(true)
            Log.d(TAG, "PoseDetectorProcessor initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing PoseDetectorProcessor: ${e.message}", e)
        }
    }

    override fun isInitialized(): Boolean = isInitialized.get()

    override fun processImageProxy(imageProxy: ImageProxy, rotationDegrees: Int) {
        if (!isInitialized()) {
            Log.w(TAG, "Not initialized yet, skipping frame")
            imageProxy.close()
            return
        }

        try {
            poseLandmarkerHelper?.detectLiveStream(imageProxy)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing image: ${e.message}", e)
            // Make sure we close the image if there's an error
            try { imageProxy.close() } catch (ignored: Exception) {}
            // Notify listeners of error
            listener?.onError("Error processing image for pose detection", 0)
        }
    }

    override fun setLensFacing(lensFacing: Int) {
        this.lensFacing = lensFacing
        Log.d(TAG, "Lens facing set to: $lensFacing")
    }

    override fun close() {
        try {
            poseLandmarkerHelper?.clearPoseLandmarker()
            poseLandmarkerHelper = null
            isInitialized.set(false)
            Log.d(TAG, "PoseDetectorProcessor closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing PoseDetectorProcessor: ${e.message}", e)
        }
    }

    // PoseLandmarkerHelper.LandmarkerListener implementation
    override fun onResults(resultBundle: PoseLandmarkerHelper.ResultBundle) {
        // Forward results to the listener if available
        listener?.onPoseDetected(resultBundle.results, System.currentTimeMillis())
    }

    override fun onError(error: String, errorCode: Int) {
        Log.e(TAG, "PoseLandmarker error: $error ($errorCode)")
        listener?.onError("PoseLandmarker error: $error", errorCode)
    }
} 