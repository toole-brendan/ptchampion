package com.example.ptchampion.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.media.Image
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
import java.lang.RuntimeException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Helper for MediaPipe pose detection using the PoseLandmarker Task
 */
class PoseLandmarkerHelper(
    private val context: Context,
    private val runningMode: RunningMode = RunningMode.LIVE_STREAM,
    private val minPoseDetectionConfidence: Float = 0.5f,
    private val minPoseTrackingConfidence: Float = 0.5f,
    private val minPosePresenceConfidence: Float = 0.5f,
    private val currentModel: Int = MODEL_FULL,
    private val delegate: Delegate = Delegate.CPU,
    private val resultListener: LandmarkerListener? = null,
    private val maxNumPoses: Int = 1
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
    private var defaultNumThreads = Runtime.getRuntime().availableProcessors() // Use available cores
    private var isClosing = AtomicBoolean(false)

    init {
        setupPoseLandmarker()
    }

    /**
     * Sets up the MediaPipe PoseLandmarker
     */
    private fun setupPoseLandmarker() {
        // Set up the PoseLandmarker using the appropriate model file
        val modelFile = when (currentModel) {
            MODEL_FULL -> POSE_LANDMARKER_FULL
            MODEL_LITE -> POSE_LANDMARKER_LITE
            MODEL_HEAVY -> POSE_LANDMARKER_HEAVY
            else -> POSE_LANDMARKER_FULL
        }

        // Create the PoseLandmarker options
        try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath(modelFile)
                .setDelegate(delegate)
                .setNumThreads(defaultNumThreads)

            val optionsBuilder = PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setMinTrackingConfidence(minPoseTrackingConfidence)
                .setNumPoses(maxNumPoses)
                .setOutputSegmentationMasks(false) // Don't need segmentation for PT exercises

            // Set up the landmarker based on running mode
            when (runningMode) {
                RunningMode.LIVE_STREAM -> {
                    optionsBuilder.setRunningMode(RunningMode.LIVE_STREAM)
                    optionsBuilder.setResultListener { result, input ->
                        // Convert to our result bundle format
                        val resultBundle = ResultBundle(
                            results = result,
                            inputImageWidth = input.width,
                            inputImageHeight = input.height,
                            inferenceTime = 0 // LiveStream mode doesn't provide inference time directly
                        )
                        // Forward to the application listener
                        resultListener?.onResults(resultBundle)
                    }
                    optionsBuilder.setErrorListener { error, errorCode ->
                        resultListener?.onError(error, errorCode)
                    }
                }
                else -> {
                    optionsBuilder.setRunningMode(runningMode)
                }
            }

            // Build the PoseLandmarker
            val options = optionsBuilder.build()
            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
            
            Log.d(TAG, "PoseLandmarker setup successful with model: $modelFile")
        } catch (e: IllegalStateException) {
            resultListener?.onError(
                "MediaPipe failed to initialize. See error logs for details.",
                e.hashCode()
            )
            Log.e(TAG, "MediaPipe PoseLandmarker initialization error: ${e.message}", e)
        } catch (e: RuntimeException) {
            resultListener?.onError(
                "MediaPipe failed to load model. See error logs for details. " +
                        "Common causes include missing .task files in assets.",
                e.hashCode()
            )
            Log.e(TAG, "MediaPipe PoseLandmarker failed to load model: ${e.message}", e)
        }
    }

    /**
     * Detects pose landmarks from an ImageProxy (live stream mode)
     */
    fun detectLiveStream(imageProxy: ImageProxy) {
        if (runningMode != RunningMode.LIVE_STREAM) {
            Log.e(TAG, "Attempted to run live stream detection in non-live stream mode.")
            imageProxy.close()
            return
        }
        if (isClosing.get() || poseLandmarker == null) {
            Log.w(TAG, "Skipping detection: Helper is closing or not initialized.")
            imageProxy.close()
            return
        }

        // Ensure image is valid
        val image = imageProxy.image
        if (image == null) {
            Log.e(TAG, "ImageProxy contained no image.")
            imageProxy.close()
            return
        }

        val frameTime = SystemClock.uptimeMillis() // Timestamp for detectAsync

        try {
            // Convert ImageProxy to MPImage
            val mpImage = BitmapImageBuilder(imageProxy.toBitmap()).build()
            
            // Process the image for pose landmarks
            poseLandmarker?.detectAsync(mpImage, frameTime)
        } catch (e: Exception) {
            Log.e(TAG, "Error detecting pose landmarks: ${e.message}", e)
            resultListener?.onError("Error during pose detection: ${e.message}", e.hashCode())
        } finally {
            // Always close the imageProxy
            imageProxy.close()
        }
    }
    
    /**
     * Detects pose landmarks from a bitmap synchronously
     */
    fun detectSync(imageBitmap: Bitmap): ResultBundle? {
        if (runningMode == RunningMode.LIVE_STREAM) {
            Log.e(TAG, "detectSync called on LIVE_STREAM mode helper")
            return null
        }
        if (isClosing.get() || poseLandmarker == null) {
            Log.e(TAG, "Cannot detect, helper is closing or not initialized.")
            return null
        }

        // Convert Bitmap to MPImage
        val mpImage = BitmapImageBuilder(imageBitmap).build()
        val startTime = SystemClock.uptimeMillis()
        
        return try {
            // Detect pose landmarks
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
            Log.e(TAG, "Error detecting pose landmarks: ${e.message}", e)
            resultListener?.onError("Error detecting pose landmarks: ${e.message}", e.hashCode())
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
        poseLandmarker = null
    }

    /**
     * Listener interface for pose detection results
     */
    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = 0)
        fun onResults(resultBundle: ResultBundle)
    }
    
    /**
     * Extension function to convert ImageProxy to Bitmap
     */
    private fun ImageProxy.toBitmap(): Bitmap? {
        val yBuffer = planes[0].buffer
        val uBuffer = planes[1].buffer
        val vBuffer = planes[2].buffer
        
        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()
        
        val nv21 = ByteArray(ySize + uSize + vSize)
        
        // U and V are swapped
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)
        
        val yuvImage = android.graphics.YuvImage(nv21, android.graphics.ImageFormat.NV21, width, height, null)
        val out = java.io.ByteArrayOutputStream()
        yuvImage.compressToJpeg(android.graphics.Rect(0, 0, width, height), 100, out)
        val imageBytes = out.toByteArray()
        return android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }
}