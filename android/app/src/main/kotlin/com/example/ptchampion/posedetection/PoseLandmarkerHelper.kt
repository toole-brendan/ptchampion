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
import com.example.ptchampion.utils.YuvToRgbConverter
import java.lang.RuntimeException
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Helper for MediaPipe pose detection
 */
class PoseLandmarkerHelper(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.LIVE_STREAM,
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
        val inferenceTime: Long // Note: inferenceTime is not reliably provided by detectAsync
    )

    companion object {
        const val TAG = "PoseLandmarkerHelper"
        const val MODEL_FULL = 0
        const val MODEL_LITE = 1
        const val MODEL_HEAVY = 2 // Keep HEAVY if model file exists

        // Model files
        private const val POSE_LANDMARKER_FULL = "pose_landmarker_full.task"
        private const val POSE_LANDMARKER_LITE = "pose_landmarker_lite.task"
        private const val POSE_LANDMARKER_HEAVY = "pose_landmarker_heavy.task" // Keep if model file exists
    }

    private var poseLandmarker: PoseLandmarker? = null
    private var defaultNumThreads = Runtime.getRuntime().availableProcessors() // Use available cores
    private val yuvToRgbConverter by lazy { YuvToRgbConverter(context) }
    private var isClosing = AtomicBoolean(false)

    init {
        setupPoseLandmarker()
    }

    /**
     * Sets up the MediaPipe PoseLandmarker
     */
    private fun setupPoseLandmarker() {
        // Prevent setup if already closing
        if (isClosing.get()) {
            Log.w(TAG, "Skipping setup, helper is closing.")
            return
        }
        
        val modelName = when (currentModel) {
            MODEL_FULL -> POSE_LANDMARKER_FULL
            MODEL_LITE -> POSE_LANDMARKER_LITE
            MODEL_HEAVY -> POSE_LANDMARKER_HEAVY
            else -> POSE_LANDMARKER_FULL
        }

        try {
            // Close existing landmarker before creating a new one
            poseLandmarker?.close()
            poseLandmarker = null
            
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath(modelName)
                .setDelegate(delegate)
                // Don't set numThreads for GPU delegate
                if (delegate != Delegate.GPU) {
                    baseOptionsBuilder.setNumThreads(defaultNumThreads)
                }
            val baseOptions = baseOptionsBuilder.build()

            val optionsBuilder = PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setMinTrackingConfidence(minPoseTrackingConfidence)
                .setRunningMode(runningMode)
                .setOutputSegmentationMasks(false)

            // Configure listeners based on RunningMode
            if (runningMode == RunningMode.LIVE_STREAM) {
                optionsBuilder.setResultListener { result: PoseLandmarkerResult?, inputImage: MPImage ->
                    // Check if closing before processing result
                    if (isClosing.get()) return@setResultListener
                    
                    val finishTime = SystemClock.uptimeMillis()
                    // Calculate approximate inference time (may not be accurate)
                    val inferenceTime = finishTime - (result?.timestampMs() ?: finishTime) 

                    result?.let {
                        val resultBundle = ResultBundle(
                            results = it,
                            inputImageWidth = inputImage.width, // Use inputImage dimensions
                            inputImageHeight = inputImage.height,
                            inferenceTime = inferenceTime // Pass calculated time
                        )
                        resultListener?.onResults(resultBundle)
                    }
                }
                .setErrorListener { error: RuntimeException, errorCode: Int ->
                    // Check if closing before processing error
                    if (isClosing.get()) return@setErrorListener
                    resultListener?.onError(error.message ?: "Unknown error in Pose Landmarker", errorCode)
                }
            }

            poseLandmarker = PoseLandmarker.createFromOptions(context, optionsBuilder.build())
            Log.d(TAG, "PoseLandmarker initialized successfully with model: $modelName, mode: $runningMode, delegate: $delegate")
        } catch (e: Exception) {
             // Don't report error if closing
            if (!isClosing.get()) {
                val errorMessage = "Failed to setup pose landmarker: ${e.message}"
                Log.e(TAG, errorMessage, e)
                resultListener?.onError(errorMessage)
            }
        }
    }

    /**
     * Process camera frame for pose detection
     */
    fun detectLiveStream(imageProxy: ImageProxy) {
         // Check if closing or not initialized
        if (isClosing.get() || poseLandmarker == null) {
             if (poseLandmarker == null && !isClosing.get()) {
                Log.w(TAG, "PoseLandmarker is null, attempting setup...")
                setupPoseLandmarker() // Try to re-initialize if null but not closing
                if (poseLandmarker == null) {
                    Log.e(TAG, "Setup failed, cannot process frame.")
                    imageProxy.close()
                    return
                } 
            } else {
                imageProxy.close()
                return
            }
        }
        
        // Ensure image is valid
        val image = imageProxy.image
        if (image == null) {
            Log.e(TAG, "ImageProxy contained no image.")
            imageProxy.close()
            return
        }

        val frameTime = SystemClock.uptimeMillis() // Timestamp for detectAsync

        // Create a bitmap for conversion (consider buffer reuse later if performance bottleneck)
        val bitmap = Bitmap.createBitmap(
            imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888
        )

        // Convert YUV to RGB
        try {
            yuvToRgbConverter.yuvToRgb(image, bitmap)
        } catch (e: Exception) {
            Log.e(TAG, "Error converting YUV to RGB: ${e.message}", e)
            imageProxy.close()
            return
        }

        // Process with MediaPipe
        val mpImage = BitmapImageBuilder(bitmap).build()
        try {
            poseLandmarker?.detectAsync(mpImage, frameTime)
        } catch (e: Exception) {
             Log.e(TAG, "Error calling detectAsync: ${e.message}", e)
             // Report error via listener if needed
             resultListener?.onError("Error during pose detection: ${e.message}")
        }

        // Always close the imageProxy
        imageProxy.close()
    }
    
    // Method for non-live stream modes (IMAGE, VIDEO) - simplified
    fun detectSync(imageBitmap: Bitmap): ResultBundle? {
        if (runningMode == RunningMode.LIVE_STREAM) {
            Log.e(TAG, "detectSync called on LIVE_STREAM mode helper")
            return null
        }
        if (isClosing.get() || poseLandmarker == null) {
            Log.e(TAG, "Cannot detect, helper is closing or not initialized.")
            return null
        }

        val mpImage = BitmapImageBuilder(imageBitmap).build()
        val startTime = SystemClock.uptimeMillis()
        return try {
            val results = poseLandmarker?.detect(mpImage)
            val inferenceTime = SystemClock.uptimeMillis() - startTime
            results?.let {
                ResultBundle(
                    results = it,
                    inputImageWidth = imageBitmap.width,
                    inputImageHeight = imageBitmap.height,
                    inferenceTime = inferenceTime
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting pose in sync mode: ${e.message}", e)
            resultListener?.onError("Error detecting pose: ${e.message}")
            null
        }
    }

    /**
     * Clear resources
     */
    fun clearPoseLandmarker() {
        Log.d(TAG, "Clearing PoseLandmarkerHelper resources.")
        isClosing.set(true)
        try {
            poseLandmarker?.close() // Close MediaPipe instance
        } catch (e: Exception) {
             Log.e(TAG, "Error closing PoseLandmarker: ${e.message}", e)
        }
        try {
            yuvToRgbConverter.close() // Close RenderScript resources
        } catch (e: Exception) {
            Log.e(TAG, "Error closing YuvToRgbConverter: ${e.message}", e)
        }
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