package com.example.ptchampion.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.annotation.VisibleForTesting
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.lang.IllegalStateException

class PoseLandmarkerHelper(
    var minPoseDetectionConfidence: Float = DEFAULT_POSE_DETECTION_CONFIDENCE,
    var minPoseTrackingConfidence: Float = DEFAULT_POSE_TRACKING_CONFIDENCE,
    var minPosePresenceConfidence: Float = DEFAULT_POSE_PRESENCE_CONFIDENCE,
    var currentDelegate: Int = DELEGATE_CPU,
    var runningMode: RunningMode = RunningMode.LIVE_STREAM, // Use LIVE_STREAM for real-time processing
    val context: Context,
    // Listener receives results and inference time
    val poseLandmarkerHelperListener: LandmarkerListener? = null
) {

    private var poseLandmarker: PoseLandmarker? = null

    init {
        setupPoseLandmarker()
    }

    fun clearPoseLandmarker() {
        poseLandmarker?.close()
        poseLandmarker = null
    }

    // Initialize the PoseLandmarker instance
    private fun setupPoseLandmarker() {
        // Configure BaseOptions, specifying the model file and delegate (CPU/GPU)
        val baseOptionBuilder = BaseOptions.builder()
        when (currentDelegate) {
            DELEGATE_CPU -> {
                baseOptionBuilder.setDelegate(Delegate.CPU)
            }
            DELEGATE_GPU -> {
                 // TODO: Consider adding GPU delegate support if needed and available
                 // Requires additional dependencies and checks
                 // baseOptionBuilder.setDelegate(Delegate.GPU)
                 baseOptionBuilder.setDelegate(Delegate.CPU) // Fallback to CPU for now
            }
        }
        // IMPORTANT: Model file name must match the one in assets
        baseOptionBuilder.setModelAssetPath(MP_POSE_LANDMARKER_TASK)

        // Check if runningMode is set to LIVE_STREAM
        if (runningMode != RunningMode.LIVE_STREAM) {
            throw IllegalArgumentException(
                "Attempting to use running mode " +
                        runningMode + ". Only LIVE_STREAM is supported"
            )
        }

        try {
            val baseOptions = baseOptionBuilder.build()
            // Build PoseLandmarker specific options
            val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
                .setMinTrackingConfidence(minPoseTrackingConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setRunningMode(runningMode)
                // Set result listener for LIVE_STREAM mode
                .setResultListener(this::returnLivestreamResult)
                .setErrorListener(this::returnLivestreamError)

            val options = optionsBuilder.build()
            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
            Log.d(TAG, "PoseLandmarker initialized successfully.")
        } catch (e: IllegalStateException) {
            poseLandmarkerHelperListener?.onError(
                "Pose Landmarker failed to initialize. See error logs for details",
                ERROR_INIT_FAILED
            )
            Log.e(
                TAG, "MediaPipe failed to load the task with error: " + e.message
            )
        } catch (e: RuntimeException) {
             poseLandmarkerHelperListener?.onError(
                "Pose Landmarker failed to initialize. See error logs for details",
                 ERROR_INIT_FAILED
             )
            Log.e(
                TAG,
                "Image classifier failed to initialize. See error logs for " +
                        "details"
            )
        }

    }

     // Convert ImageProxy to MPImage and run pose landmark detection
     fun detectLiveStream(imageProxy: ImageProxy) {
         if (runningMode != RunningMode.LIVE_STREAM) {
             throw IllegalArgumentException(
                 "Attempting to call detectLiveStream" +
                         " while not using RunningMode.LIVE_STREAM"
             )
         }
         val frameTime = SystemClock.uptimeMillis()

         // Copy out RGB bits from the ImageProxy:
         val bitmapBuffer = Bitmap.createBitmap(
                 imageProxy.width,
                 imageProxy.height,
                 Bitmap.Config.ARGB_8888
             )
         imageProxy.use { bitmapBuffer.copyPixelsFromBuffer(imageProxy.planes[0].buffer) }
         imageProxy.close() // Close the proxy immediately after use

         // Rotate the image bitmap if needed based on ImageProxy's rotation degrees.
         // CameraX rotation describes the clockwise rotation needed to correct the image.
         val matrix = Matrix().apply {
             postRotate(imageProxy.imageInfo.rotationDegrees.toFloat())
             // TODO: Handle front camera mirroring if necessary (usually requires horizontal flip)
             // if (isFrontCamera) { postScale(-1f, 1f, imageProxy.width / 2f, imageProxy.height / 2f) }
         }
         val rotatedBitmap = Bitmap.createBitmap(
             bitmapBuffer, 0, 0, bitmapBuffer.width, bitmapBuffer.height,
             matrix, true
         )

         // Convert the rotated bitmap to MPImage and feed it to PoseLandmarker.
         val mpImage = BitmapImageBuilder(rotatedBitmap).build()

         detectAsync(mpImage, frameTime)
     }

    // Run pose landmark detection using MediaPipe SDK
    @VisibleForTesting
    fun detectAsync(mpImage: MPImage, frameTime: Long) {
        // Skip detection if PoseLandmarker isn't initialized yet.
        if (poseLandmarker == null) {
             Log.w(TAG, "PoseLandmarker not initialized, skipping detection.")
             return
        }
        // Run pose landmark detection asynchronously. Inference results will be returned on the
        // resultListener thread.
        poseLandmarker?.detectAsync(mpImage, frameTime)
         Log.d(TAG, "Pose detection request submitted for timestamp: $frameTime")
    }

    // Return the landmark result to this PoseLandmarkerHelper's caller
    private fun returnLivestreamResult(
        result: PoseLandmarkerResult,
        input: MPImage
    ) {
        val finishTimeMs = SystemClock.uptimeMillis()
        val inferenceTime = finishTimeMs - input.timestamp

        poseLandmarkerHelperListener?.onResults(
            ResultBundle(
                results = result,
                inferenceTime = inferenceTime,
                inputImageHeight = input.height,
                inputImageWidth = input.width
            )
        )
         Log.d(TAG, "Pose detection result received. Inference time: $inferenceTime ms")
    }

    // Return errors thrown during detection to this PoseLandmarkerHelper's caller
    private fun returnLivestreamError(error: RuntimeException) {
        poseLandmarkerHelperListener?.onError(
            error.message ?: "An unknown error has occurred", ERROR_RUNTIME
        )
         Log.e(TAG, "Pose detection error: ${error.message}")
    }

    // Defines listeners interfaces
    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = 0)
        fun onResults(resultBundle: ResultBundle)
    }

    companion object {
        const val TAG = "PoseLandmarkerHelper"

        // Name of the model file stored in the assets folder
        private const val MP_POSE_LANDMARKER_TASK = "pose_landmarker_lite.task"

        const val DELEGATE_CPU = 0
        const val DELEGATE_GPU = 1
        const val DEFAULT_POSE_DETECTION_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_TRACKING_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_PRESENCE_CONFIDENCE = 0.5F
        const val OTHER_ERROR = 0
        const val ERROR_RUNTIME = 1
        const val ERROR_INIT_FAILED = 2 // Custom error code for init failure
    }

    // Wraps results from PoseLandmarkerListener
    data class ResultBundle(
        val results: PoseLandmarkerResult,
        val inferenceTime: Long,
        val inputImageHeight: Int,
        val inputImageWidth: Int
    )
} 