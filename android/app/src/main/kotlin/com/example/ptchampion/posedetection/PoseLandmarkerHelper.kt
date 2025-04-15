package com.example.ptchampion.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerOptions
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Helper for MediaPipe pose detection
 */
class PoseLandmarkerHelper(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.IMAGE,
    private val minPoseDetectionConfidence: Float = 0.5f,
    private val minPoseTrackingConfidence: Float = 0.5f,
    private val minPosePresenceConfidence: Float = 0.5f,
    private val currentModel: Int = MODEL_FULL,
    private val delegate: Delegate = Delegate.CPU,
    private val resultListener: LandmarkerListener? = null
) {
    // For pose landmarker results
    data class ResultBundle(
        val results: PoseLandmarkerResult,
        val inputImageWidth: Int,
        val inputImageHeight: Int,
        val inferenceTime: Long
    )

    companion object {
        const val TAG = "PoseLandmarkerHelper"
        const val MODEL_FULL = 0
        const val MODEL_LITE = 1
        const val MODEL_HEAVY = 2

        // Model files
        private const val POSE_LANDMARKER_FULL = "pose_landmarker_full.task"
        private const val POSE_LANDMARKER_LITE = "pose_landmarker_lite.task"
        private const val POSE_LANDMARKER_HEAVY = "pose_landmarker_heavy.task"
    }

    private var poseLandmarker: PoseLandmarker? = null
    private var defaultNumThreads = 2

    init {
        setupPoseLandmarker()
    }

    /**
     * Sets up the MediaPipe PoseLandmarker
     */
    private fun setupPoseLandmarker() {
        val modelName = when (currentModel) {
            MODEL_FULL -> POSE_LANDMARKER_FULL
            MODEL_LITE -> POSE_LANDMARKER_LITE
            MODEL_HEAVY -> POSE_LANDMARKER_HEAVY
            else -> POSE_LANDMARKER_FULL
        }

        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(modelName)
                .setDelegate(delegate)
                .setNumThreads(defaultNumThreads)
                .build()

            val options = PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setMinTrackingConfidence(minPoseTrackingConfidence)
                .setRunningMode(runningMode)
                .setOutputSegmentationMasks(false) // Set to true if needed

            if (runningMode == RunningMode.LIVE_STREAM) {
                options.setResultListener { result, inputImage ->
                    result?.let {
                        val resultBundle = ResultBundle(
                            results = result,
                            inputImageWidth = inputImage.width,
                            inputImageHeight = inputImage.height,
                            inferenceTime = 0 // Live Stream mode doesn't provide inference time
                        )
                        resultListener?.onResults(resultBundle)
                    }
                }
                .setErrorListener { error, code ->
                    resultListener?.onError(error, code)
                }
            }

            poseLandmarker = PoseLandmarker.createFromOptions(context, options.build())
            Log.d(TAG, "PoseLandmarker successfully initialized with model: $modelName")
        } catch (e: Exception) {
            resultListener?.onError("Failed to setup pose landmarker: ${e.message}")
            Log.e(TAG, "Failed to setup pose landmarker: ${e.message}")
        }
    }

    /**
     * Detect poses in a bitmap image
     */
    fun detectImage(imageBitmap: Bitmap): ResultBundle? {
        if (poseLandmarker == null) {
            setupPoseLandmarker()
        }

        val mpImage = BitmapImageBuilder(imageBitmap).build()
        return detect(mpImage, imageBitmap.width, imageBitmap.height)
    }

    /**
     * Backward compatibility method
     */
    fun detect(image: Bitmap): ResultBundle? {
        return detectImage(image)
    }

    /**
     * Process camera frame for pose detection
     */
    fun detectLiveStream(imageProxy: ImageProxy) {
        if (poseLandmarker == null) {
            setupPoseLandmarker()
        }

        val frameTime = SystemClock.uptimeMillis()
        val bitmapBuffer = Bitmap.createBitmap(
            imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888
        )

        // Convert image to bitmap and process with MediaPipe
        // (Implement the YUV to RGB conversion here)
        
        val mpImage = BitmapImageBuilder(bitmapBuffer).build()
        
        // Process the image with MediaPipe
        poseLandmarker?.detectForVideo(mpImage, frameTime)
        
        // Always close the imageProxy after use
        imageProxy.close()
    }

    /**
     * Shared detection logic
     */
    private fun detect(mpImage: MPImage, width: Int, height: Int): ResultBundle? {
        if (poseLandmarker == null) {
            setupPoseLandmarker()
        }

        try {
            val startTime = SystemClock.uptimeMillis()
            val results = poseLandmarker?.detect(mpImage)
            val inferenceTime = SystemClock.uptimeMillis() - startTime

            return results?.let {
                ResultBundle(
                    results = it,
                    inputImageWidth = width,
                    inputImageHeight = height,
                    inferenceTime = inferenceTime
                )
            }
        } catch (e: Exception) {
            resultListener?.onError("Error detecting pose: ${e.message}")
            Log.e(TAG, "Error detecting pose: ${e.message}")
        }
        return null
    }

    /**
     * Clear resources
     */
    fun clearPoseLandmarker() {
        poseLandmarker?.close()
        poseLandmarker = null
    }

    /**
     * Listener interface for pose detection results
     */
    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = 0)
        fun onResults(resultBundle: ResultBundle)
    }
}