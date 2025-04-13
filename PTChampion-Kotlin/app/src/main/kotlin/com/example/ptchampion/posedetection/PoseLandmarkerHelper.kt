package com.example.ptchampion.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.annotation.VisibleForTesting
import androidx.camera.core.ImageProxy
import com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark
/* // Temporarily comment out MediaPipe imports
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker.PoseLandmarkerOptions
*/
import java.lang.IllegalStateException

// Dummy RunningMode enum for compilation
enum class RunningMode { LIVE_STREAM }
// Dummy PoseLandmarkerResult class for compilation
class PoseLandmarkerResult {
    val landmarks: List<MockNormalizedLandmark> = List(33) { MockNormalizedLandmark() }
    val worldLandmarks: List<MockNormalizedLandmark> = List(33) { MockNormalizedLandmark() }
}
// Dummy MPImage class for compilation
class MPImage { val timestamp: Long = 0L; val height: Int = 0; val width: Int = 0 }

class PoseLandmarkerHelper(
    var minPoseDetectionConfidence: Float = DEFAULT_POSE_DETECTION_CONFIDENCE,
    var minPoseTrackingConfidence: Float = DEFAULT_POSE_TRACKING_CONFIDENCE,
    var minPosePresenceConfidence: Float = DEFAULT_POSE_PRESENCE_CONFIDENCE,
    var currentDelegate: Int = DELEGATE_CPU,
    var runningMode: RunningMode = RunningMode.LIVE_STREAM, // Use dummy enum
    val context: Context,
    val poseLandmarkerHelperListener: LandmarkerListener? = null
) {

    // private var poseLandmarker: PoseLandmarker? = null // Comment out PoseLandmarker instance

    init {
        // setupPoseLandmarker() // Comment out setup call
        Log.i(TAG, "PoseLandmarker setup bypassed temporarily.")
        // Simulate async initialization complete after a delay
        // In a real scenario without MediaPipe, you might remove the listener pattern entirely
        // or adapt it based on the alternative pose detection used.
         poseLandmarkerHelperListener?.onResults(ResultBundle(
             results = PoseLandmarkerResult(), // Dummy result
             inferenceTime = 10L,
             inputImageHeight = 480,
             inputImageWidth = 640
         ))
    }

    fun clearPoseLandmarker() {
        // poseLandmarker?.close()
        // poseLandmarker = null
        Log.i(TAG, "clearPoseLandmarker bypassed.")
    }

    // Initialize the PoseLandmarker instance
    private fun setupPoseLandmarker() {
        // Comment out entire setup logic
        /*
        val baseOptionBuilder = BaseOptions.builder()
            .setModelAssetPath(MP_POSE_LANDMARKER_TASK)
        // ... rest of the setup logic ...
        poseLandmarker = PoseLandmarker.createFromOptions(context, options)
        Log.d(TAG, "PoseLandmarker initialized successfully.")
        */
         Log.w(TAG, "setupPoseLandmarker called but is bypassed.")
         // Simulate initialization error for testing if needed
         // poseLandmarkerHelperListener?.onError("Bypassed initialization", ERROR_INIT_FAILED)
    }

     // Convert ImageProxy to MPImage and run pose landmark detection
     fun detectLiveStream(
         imageProxy: ImageProxy,
         isFrontCamera: Boolean
     ) {
         if (runningMode != RunningMode.LIVE_STREAM) {
             throw IllegalArgumentException("Only LIVE_STREAM is supported (Bypassed)")
         }
         // Skip all processing and just close the proxy
         Log.d(TAG, "detectLiveStream called but bypassed. Closing proxy.")
         imageProxy.close()
         // Simulate results if needed for testing UI flow
         /*
         poseLandmarkerHelperListener?.onResults(
             ResultBundle(
                 results = PoseLandmarkerResult(), // Dummy result
                 inferenceTime = (50..100).random().toLong(), // Simulate varying inference time
                 inputImageHeight = imageProxy.height,
                 inputImageWidth = imageProxy.width
             )
         )
         */
     }

    // Run pose landmark detection using MediaPipe SDK
    @VisibleForTesting
    fun detectAsync(mpImage: MPImage, frameTime: Long) {
        // Skip detection as PoseLandmarker is commented out
        Log.w(TAG, "detectAsync called but is bypassed.")
        /*
        if (poseLandmarker == null) {
             Log.w(TAG, "PoseLandmarker not initialized, skipping detection.")
             return
        }
        poseLandmarker?.detectAsync(mpImage, frameTime)
        Log.d(TAG, "Pose detection request submitted for timestamp: $frameTime")
        */
    }

    // Return the landmark result to this PoseLandmarkerHelper's caller
    private fun returnLivestreamResult(
        // result: PoseLandmarkerResult, // Use dummy class
        // input: MPImage // Use dummy class
    ) {
         Log.w(TAG, "returnLivestreamResult called but is bypassed.")
        /*
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
         */
    }

    // Return errors thrown during detection to this PoseLandmarkerHelper's caller
    private fun returnLivestreamError(error: RuntimeException) {
         Log.w(TAG, "returnLivestreamError called but is bypassed.")
        /*
        poseLandmarkerHelperListener?.onError(
            error.message ?: "An unknown error has occurred", ERROR_RUNTIME
        )
         Log.e(TAG, "Pose detection error: ${error.message}")
         */
    }

    // Defines listeners interfaces
    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = 0)
        fun onResults(resultBundle: ResultBundle)
    }

    companion object {
        const val TAG = "PoseLandmarkerHelper"

        // Name of the model file stored in the assets folder
        // private const val MP_POSE_LANDMARKER_TASK = "pose_landmarker_lite.task" // Commented out

        const val DELEGATE_CPU = 0
        const val DELEGATE_GPU = 1
        const val DEFAULT_POSE_DETECTION_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_TRACKING_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_PRESENCE_CONFIDENCE = 0.5F
        const val OTHER_ERROR = 0
        const val ERROR_RUNTIME = 1
        const val ERROR_INIT_FAILED = 2 // Custom error code for init failure
        const val ERROR_GPU_DELEGATE = 3 // Custom error code for GPU delegate failure
    }

    // Wraps results from PoseLandmarkerListener
    data class ResultBundle(
        val results: PoseLandmarkerResult, // Uses dummy class
        val inferenceTime: Long,
        val inputImageHeight: Int,
        val inputImageWidth: Int
    )
}