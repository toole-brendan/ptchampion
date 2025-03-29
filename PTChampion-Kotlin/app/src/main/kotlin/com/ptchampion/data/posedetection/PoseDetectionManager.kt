package com.ptchampion.data.posedetection

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.pose.Pose
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.SitupState
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manager that coordinates between ML Kit and MediaPipe pose detection
 */
@Singleton
class PoseDetectionManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val mlKitService: PoseDetectionService,
    private val mediaPipeService: MediaPipePoseDetectionService
) {
    companion object {
        private const val TAG = "PoseDetectionManager"
        private const val PREFS_NAME = "pose_detection_prefs"
        private const val KEY_USE_MEDIAPIPE = "use_mediapipe_detection"
    }
    
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * Whether to use MediaPipe for pose detection
     */
    var useMediaPipe: Boolean
        get() = prefs.getBoolean(KEY_USE_MEDIAPIPE, false)
        set(value) {
            prefs.edit().putBoolean(KEY_USE_MEDIAPIPE, value).apply()
        }
    
    /**
     * Toggle between ML Kit and MediaPipe pose detection
     * @return true if MediaPipe is now being used, false otherwise
     */
    fun toggleDetectionSystem(): Boolean {
        useMediaPipe = !useMediaPipe
        Log.d(TAG, "Toggled pose detection system. Using MediaPipe: $useMediaPipe")
        return useMediaPipe
    }
    
    /**
     * Detect pose using the current detection system
     */
    fun detectPose(bitmap: Bitmap): Any? {
        return if (useMediaPipe) {
            try {
                mediaPipeService.detectPose(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "MediaPipe detection failed, falling back to ML Kit", e)
                useMediaPipe = false
                mlKitService.detectPose(bitmap)
            }
        } else {
            mlKitService.detectPose(bitmap)
        }
    }
    
    /**
     * Detect pushup using the current detection system
     */
    fun detectPushup(poseResult: Any?, prevState: PushupState): PushupState {
        return if (useMediaPipe && poseResult is PoseLandmarkerResult) {
            try {
                mediaPipeService.detectPushup(poseResult, prevState)
            } catch (e: Exception) {
                Log.e(TAG, "MediaPipe pushup detection failed, falling back to ML Kit", e)
                useMediaPipe = false
                
                // Try to get a new pose with ML Kit
                val bitmap = getCurrentFrameBitmap() 
                if (bitmap != null) {
                    val mlkitPose = mlKitService.detectPose(bitmap)
                    if (mlkitPose != null) {
                        mlKitService.detectPushup(mlkitPose, prevState)
                    } else {
                        prevState.copy(feedback = "Detection failed. Please try again.")
                    }
                } else {
                    prevState.copy(feedback = "Detection failed. Please try again.")
                }
            }
        } else if (poseResult is Pose) {
            mlKitService.detectPushup(poseResult, prevState)
        } else {
            prevState.copy(feedback = "Detection system error")
        }
    }
    
    /**
     * Detect pullup using the current detection system
     */
    fun detectPullup(poseResult: Any?, prevState: PullupState): PullupState {
        return if (useMediaPipe && poseResult is PoseLandmarkerResult) {
            try {
                mediaPipeService.detectPullup(poseResult, prevState)
            } catch (e: Exception) {
                Log.e(TAG, "MediaPipe pullup detection failed, falling back to ML Kit", e)
                useMediaPipe = false
                
                // Try to get a new pose with ML Kit and similar recovery logic as in detectPushup
                prevState.copy(feedback = "Detection failed. Please try again.")
            }
        } else if (poseResult is Pose) {
            mlKitService.detectPullup(poseResult, prevState)
        } else {
            prevState.copy(feedback = "Detection system error")
        }
    }
    
    /**
     * Detect situp using the current detection system
     */
    fun detectSitup(poseResult: Any?, prevState: SitupState): SitupState {
        return if (useMediaPipe && poseResult is PoseLandmarkerResult) {
            try {
                mediaPipeService.detectSitup(poseResult, prevState)
            } catch (e: Exception) {
                Log.e(TAG, "MediaPipe situp detection failed, falling back to ML Kit", e)
                useMediaPipe = false
                
                // Try to get a new pose with ML Kit and similar recovery logic as in detectPushup
                prevState.copy(feedback = "Detection failed. Please try again.")
            }
        } else if (poseResult is Pose) {
            mlKitService.detectSitup(poseResult, prevState)
        } else {
            prevState.copy(feedback = "Detection system error")
        }
    }
    
    /**
     * Helper method to get the current camera frame as bitmap
     * This would need to be implemented based on your camera handling
     */
    private fun getCurrentFrameBitmap(): Bitmap? {
        // This is a placeholder - in a real app, you'd get the bitmap from the camera preview
        // You might need to inject a reference to your camera handler class
        return null
    }
    
    /**
     * Clean up resources
     */
    fun close() {
        mlKitService.close()
        mediaPipeService.close()
    }
}
