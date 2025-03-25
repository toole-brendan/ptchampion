package com.ptchampion.data.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseDetector
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.SitupState
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.atan2
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Service for pose detection and exercise tracking
 */
@Singleton
class PoseDetectionService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "PoseDetectionService"
        private const val MIN_CONFIDENCE = 0.3
    }
    
    // ML Kit pose detector
    private val poseDetector: PoseDetector by lazy {
        val options = PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
            .setPerformanceMode(PoseDetectorOptions.PERFORMANCE_MODE_FAST)
            .build()
        PoseDetection.getClient(options)
    }
    
    /**
     * Detect pose in an image
     */
    fun detectPose(bitmap: Bitmap): Pose? {
        val image = InputImage.fromBitmap(bitmap, 0)
        var detectedPose: Pose? = null
        
        try {
            poseDetector.process(image)
                .addOnSuccessListener { pose ->
                    detectedPose = pose
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Pose detection failed", e)
                }
                .await() // Wait for the result
                
        } catch (e: Exception) {
            Log.e(TAG, "Error processing pose", e)
        }
        
        return detectedPose
    }
    
    /**
     * Detect pushup motion from pose
     */
    fun detectPushup(pose: Pose, prevState: PushupState): PushupState {
        // Get key landmarks
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
        val rightElbow = pose.getPoseLandmark(PoseLandmark.RIGHT_ELBOW)
        val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
        val rightWrist = pose.getPoseLandmark(PoseLandmark.RIGHT_WRIST)
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val rightHip = pose.getPoseLandmark(PoseLandmark.RIGHT_HIP)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftElbow == null || rightElbow == null ||
            leftWrist == null || rightWrist == null ||
            leftHip == null || rightHip == null) {
            return prevState.copy(
                feedback = "Position your full body in view"
            )
        }
        
        // Calculate angles for both arms
        val leftArmAngle = calculateAngle(
            leftShoulder.position,
            leftElbow.position,
            leftWrist.position
        )
        
        val rightArmAngle = calculateAngle(
            rightShoulder.position,
            rightElbow.position,
            rightWrist.position
        )
        
        // Calculate body alignment angle (should be straight in a pushup)
        val bodyAngle = calculateAngle(
            rightShoulder.position,
            rightHip.position,
            PointF(rightHip.position.x, rightHip.position.y + 100f) // Point below hip
        )
        
        // Average arm angle
        val armAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Check if in up position (arms extended)
        val isUp = armAngle > 150
        
        // Check if in down position (arms bent)
        val isDown = armAngle < 90
        
        // Calculate form score based on body alignment
        // A proper pushup should have the body straight (bodyAngle close to 180)
        val alignmentScore = when {
            bodyAngle > 160 -> 100 // Great alignment
            bodyAngle > 140 -> 80  // Good alignment
            bodyAngle > 120 -> 60  // Fair alignment
            else -> 40             // Poor alignment
        }
        
        // Generate feedback
        val feedback = when {
            !isUp && !isDown -> "Bend your arms to start"
            isDown -> "Push up to complete the rep"
            isUp && prevState.isDown -> "Good! Keep going"
            isUp -> "Lower your body to start the rep"
            else -> "Keep your body straight"
        }
        
        // Count rep if we were down and now we're up
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        return PushupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = alignmentScore,
            feedback = feedback
        )
    }
    
    /**
     * Detect pullup motion from pose
     */
    fun detectPullup(pose: Pose, prevState: PullupState): PullupState {
        // Get key landmarks
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
        val rightElbow = pose.getPoseLandmark(PoseLandmark.RIGHT_ELBOW)
        val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
        val rightWrist = pose.getPoseLandmark(PoseLandmark.RIGHT_WRIST)
        val nose = pose.getPoseLandmark(PoseLandmark.NOSE)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftElbow == null || rightElbow == null ||
            leftWrist == null || rightWrist == null || nose == null) {
            return prevState.copy(
                feedback = "Position your full body in view"
            )
        }
        
        // For pullups, we need to check if the chin is above the hands
        val chinY = nose.position.y
        val handsY = (leftWrist.position.y + rightWrist.position.y) / 2
        
        // Also check arm angles
        val leftArmAngle = calculateAngle(
            leftShoulder.position,
            leftElbow.position,
            leftWrist.position
        )
        
        val rightArmAngle = calculateAngle(
            rightShoulder.position,
            rightElbow.position,
            rightWrist.position
        )
        
        // Average arm angle
        val armAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Check if in up position (chin above hands, arms bent)
        val isUp = chinY < handsY && armAngle < 100
        
        // Check if in down position (arms extended)
        val isDown = armAngle > 150
        
        // Calculate form score based on symmetry and body position
        val symmetryScore = (100 - min(30.0, abs(leftArmAngle - rightArmAngle))).toInt()
        
        // Generate feedback
        val feedback = when {
            !isDown && !isUp -> "Hang with arms extended to start"
            isDown -> "Pull up until your chin is over the bar"
            isUp && prevState.isDown -> "Good! Now lower yourself"
            isUp -> "Lower yourself to start the next rep"
            else -> "Keep your body straight"
        }
        
        // Count rep if we were down and now we're up
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        return PullupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = symmetryScore,
            feedback = feedback
        )
    }
    
    /**
     * Detect situp motion from pose
     */
    fun detectSitup(pose: Pose, prevState: SitupState): SitupState {
        // Get key landmarks
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val rightHip = pose.getPoseLandmark(PoseLandmark.RIGHT_HIP)
        val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
        val rightKnee = pose.getPoseLandmark(PoseLandmark.RIGHT_KNEE)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftHip == null || rightHip == null ||
            leftKnee == null || rightKnee == null) {
            return prevState.copy(
                feedback = "Position your full body in view"
            )
        }
        
        // For situps, we need to check the angle between shoulders, hips, and knees
        val leftSitupAngle = calculateAngle(
            leftShoulder.position,
            leftHip.position,
            leftKnee.position
        )
        
        val rightSitupAngle = calculateAngle(
            rightShoulder.position,
            rightHip.position,
            rightKnee.position
        )
        
        // Average situp angle
        val situpAngle = (leftSitupAngle + rightSitupAngle) / 2
        
        // Check if in up position (smaller angle, torso is up)
        val isUp = situpAngle < 80
        
        // Check if in down position (larger angle, lying flat)
        val isDown = situpAngle > 160
        
        // Calculate form score based on symmetry
        val symmetryScore = (100 - min(30.0, abs(leftSitupAngle - rightSitupAngle))).toInt()
        
        // Generate feedback
        val feedback = when {
            !isDown && !isUp -> "Lie flat to start"
            isDown -> "Sit up until your torso is upright"
            isUp && prevState.isDown -> "Good! Now lower yourself"
            isUp -> "Lower yourself to start the next rep"
            else -> "Keep your movement controlled"
        }
        
        // Count rep if we were down and now we're up
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        return SitupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = symmetryScore,
            feedback = feedback
        )
    }
    
    /**
     * Calculate angle between three points
     */
    private fun calculateAngle(
        p1: PointF,
        p2: PointF,
        p3: PointF
    ): Double {
        // Calculate vectors
        val v1x = p1.x - p2.x
        val v1y = p1.y - p2.y
        val v2x = p3.x - p2.x
        val v2y = p3.y - p2.y
        
        // Calculate angle using the dot product
        val dot = v1x * v2x + v1y * v2y
        val mag1 = sqrt(v1x * v1x + v1y * v1y)
        val mag2 = sqrt(v2x * v2x + v2y * v2y)
        
        // Calculate angle in degrees
        val angle = Math.toDegrees(
            atan2(
                p1.y - p2.y,
                p1.x - p2.x
            ) - atan2(
                p3.y - p2.y,
                p3.x - p2.x
            )
        )
        
        // Ensure angle is positive
        return abs(angle)
    }
    
    /**
     * Calculate distance between two points
     */
    private fun getDistance(p1: PointF, p2: PointF): Float {
        val dx = p1.x - p2.x
        val dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /**
     * Absolute value
     */
    private fun abs(value: Double): Double {
        return if (value < 0) -value else value
    }
    
    /**
     * Clean up resources
     */
    fun close() {
        poseDetector.close()
    }
}