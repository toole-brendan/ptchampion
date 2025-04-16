package com.example.ptchampion.utils

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

class PoseDetectionTester(
    private val context: Context
) {
    private val TAG = "PoseDetectionTester"

    /**
     * Attempts to initialize PoseLandmarkerHelper in IMAGE mode 
     * to verify model loading and basic setup.
     * @return true if initialization seems successful, false otherwise.
     */
    fun testPoseLandmarkerInitialization(): Boolean {
        var success = false
        var landmarkerHelper: PoseLandmarkerHelper? = null
        try {
            // Use a dummy listener for testing initialization
            val testListener = object : PoseLandmarkerHelper.LandmarkerListener {
                override fun onError(error: String, errorCode: Int) {
                    Log.e(TAG, "Initialization Test Error: $error (code: $errorCode)")
                    success = false // Explicitly mark as failed on error
                }

                override fun onResults(resultBundle: PoseLandmarkerHelper.ResultBundle) {
                    // We don't expect results in IMAGE mode without calling detect
                    Log.d(TAG, "Initialization Test: onResults called unexpectedly.") 
                }
            }
            
            Log.d(TAG, "Attempting to initialize PoseLandmarkerHelper (LITE model, IMAGE mode)...")
            landmarkerHelper = PoseLandmarkerHelper(
                context = context,
                runningMode = RunningMode.IMAGE, // Use IMAGE mode for sync init test
                currentModel = PoseLandmarkerHelper.MODEL_LITE,
                resultListener = testListener
            )
            // If constructor doesn't throw and returns an instance, consider it a basic success
            success = landmarkerHelper != null
            Log.d(TAG, "PoseLandmarkerHelper initialization test completed. Success: $success")

        } catch (e: Exception) {
            Log.e(TAG, "Initialization test failed with exception: ${e.message}", e)
            success = false
        } finally {
            // Clean up the test helper instance
            try {
                landmarkerHelper?.clearPoseLandmarker()
            } catch (e: Exception) { 
                Log.e(TAG, "Error cleaning up test landmarker: ${e.message}", e)
            }
        }
        return success
    }

    /**
     * Logs basic device and camera information.
     */
    fun logSystemInfo() {
        Log.d(TAG, "--- System Info ---")
        Log.d(TAG, "Device: ${Build.MANUFACTURER} ${Build.MODEL}")
        Log.d(TAG, "Android version: ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})")
        Log.d(TAG, "Available processors: ${Runtime.getRuntime().availableProcessors()}")
        
        // Check camera features
        val pm = context.packageManager
        try {
            val hasCameraFeature = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
            Log.d(TAG, "Has system feature CAMERA_ANY: $hasCameraFeature")
            val hasFrontCamera = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)
            Log.d(TAG, "Has system feature CAMERA_FRONT: $hasFrontCamera")
            val hasBackCamera = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA)
            Log.d(TAG, "Has system feature CAMERA (Back): $hasBackCamera")
        } catch (e: Exception) {
            Log.e(TAG, "Error checking camera features: ${e.message}", e)
        }
        Log.d(TAG, "-------------------")
    }
} 