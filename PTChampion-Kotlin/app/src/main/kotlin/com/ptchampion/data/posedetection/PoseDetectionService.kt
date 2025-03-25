package com.ptchampion.data.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.accurate.AccuratePoseDetectorOptions
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.SitupState
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.math.atan2
import kotlin.math.pow
import kotlin.math.sqrt

/**
 * Service for handling pose detection using ML Kit
 */
@Singleton
class PoseDetectionService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "PoseDetectionService"
        private const val MIN_CONFIDENCE = 0.3
    }

    private val options = AccuratePoseDetectorOptions.Builder()
        .setDetectorMode(AccuratePoseDetectorOptions.STREAM_MODE)
        .build()

    private val poseDetector = PoseDetection.getClient(options)

    /**
     * Detects a pose from a bitmap
     */
    suspend fun detectPose(bitmap: Bitmap): Pose? = suspendCancellableCoroutine { continuation ->
        val image = InputImage.fromBitmap(bitmap, 0)
        
        poseDetector.process(image)
            .addOnSuccessListener { pose ->
                continuation.resume(pose)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Pose detection failed", e)
                continuation.resume(null)
            }
    }

    /**
     * Analyzes a pushup exercise from a pose
     */
    fun detectPushup(pose: Pose, prevState: PushupState): PushupState {
        // Only process if we have all required landmarks with sufficient confidence
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
        val rightElbow = pose.getPoseLandmark(PoseLandmark.RIGHT_ELBOW)
        val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
        val rightWrist = pose.getPoseLandmark(PoseLandmark.RIGHT_WRIST)
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val rightHip = pose.getPoseLandmark(PoseLandmark.RIGHT_HIP)
        val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
        val rightKnee = pose.getPoseLandmark(PoseLandmark.RIGHT_KNEE)
        val leftAnkle = pose.getPoseLandmark(PoseLandmark.LEFT_ANKLE)
        val rightAnkle = pose.getPoseLandmark(PoseLandmark.RIGHT_ANKLE)
        
        // Check if we have all landmarks with sufficient confidence
        val requiredLandmarks = listOf(
            leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist,
            leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle
        )
        
        if (requiredLandmarks.any { it == null || it.inFrameLikelihood < MIN_CONFIDENCE }) {
            return PushupState(
                isUp = false,
                isDown = false,
                count = prevState.count,
                formScore = prevState.formScore,
                feedback = "Move your entire body into the frame"
            )
        }
        
        // Calculate angles for elbows
        val leftElbowAngle = calculateAngle(
            leftShoulder!!.position,
            leftElbow!!.position,
            leftWrist!!.position
        )
        val rightElbowAngle = calculateAngle(
            rightShoulder!!.position,
            rightElbow!!.position,
            rightWrist!!.position
        )
        
        // Calculate angles for body alignment (hips-shoulders-ankles)
        val leftBodyAngle = calculateAngle(
            leftHip!!.position,
            leftShoulder.position,
            leftAnkle!!.position
        )
        val rightBodyAngle = calculateAngle(
            rightHip!!.position,
            rightShoulder.position,
            rightAnkle!!.position
        )
        
        // Average angles
        val elbowAngle = (leftElbowAngle + rightElbowAngle) / 2
        val bodyAngle = (leftBodyAngle + rightBodyAngle) / 2
        
        // Determine pushup state
        val isDown = elbowAngle < 90 // Arms bent
        val isUp = elbowAngle > 160 // Arms extended
        
        // Evaluate form
        val isBodyStraight = bodyAngle > 160
        val formScore = if (isBodyStraight) prevState.formScore else prevState.formScore.coerceAtMost(80)
        
        // Calculate new count based on state transition
        var newCount = prevState.count
        var feedback = "Good form. Keep going."
        
        if (prevState.isDown && isUp) {
            // Transitioning from down to up position - count a rep
            newCount++
            feedback = "Good job! $newCount pushups completed."
        } else if (isDown) {
            feedback = "Good, now push up."
        } else if (!isBodyStraight) {
            feedback = "Keep your body straight for better form."
        }
        
        return PushupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = feedback
        )
    }
    
    /**
     * Analyzes a pullup exercise from a pose
     */
    fun detectPullup(pose: Pose, prevState: PullupState): PullupState {
        // Only process if we have all required landmarks with sufficient confidence
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
        val rightElbow = pose.getPoseLandmark(PoseLandmark.RIGHT_ELBOW)
        val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
        val rightWrist = pose.getPoseLandmark(PoseLandmark.RIGHT_WRIST)
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val rightHip = pose.getPoseLandmark(PoseLandmark.RIGHT_HIP)
        val nose = pose.getPoseLandmark(PoseLandmark.NOSE)
        
        // Check if we have all landmarks with sufficient confidence
        val requiredLandmarks = listOf(
            leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist,
            leftHip, rightHip, nose
        )
        
        if (requiredLandmarks.any { it == null || it.inFrameLikelihood < MIN_CONFIDENCE }) {
            return PullupState(
                isUp = false,
                isDown = false,
                count = prevState.count,
                formScore = prevState.formScore,
                feedback = "Position yourself in the frame"
            )
        }
        
        // Calculate angles for elbows
        val leftElbowAngle = calculateAngle(
            leftShoulder!!.position,
            leftElbow!!.position,
            leftWrist!!.position
        )
        val rightElbowAngle = calculateAngle(
            rightShoulder!!.position,
            rightElbow!!.position,
            rightWrist!!.position
        )
        
        // Calculate vertical positions
        val chinHeight = nose!!.position.y
        val shoulderHeight = (leftShoulder.position.y + rightShoulder.position.y) / 2
        
        // Determine pullup state
        val isUp = chinHeight <= shoulderHeight // Chin above or at bar level
        val isDown = chinHeight > shoulderHeight + 30 // Chin below bar level (arms extended)
        
        // Evaluate form - elbows should be close to body
        val elbowAngle = (leftElbowAngle + rightElbowAngle) / 2
        val isGoodForm = elbowAngle < 120 // Elbows bent and close to body during pull
        val formScore = if (isGoodForm) prevState.formScore else prevState.formScore.coerceAtMost(80)
        
        // Calculate new count based on state transition
        var newCount = prevState.count
        var feedback = "Good form. Keep going."
        
        if (prevState.isDown && isUp) {
            // Transitioning from down to up position - count a rep
            newCount++
            feedback = "Great job! $newCount pullups completed."
        } else if (isDown) {
            feedback = "Now pull up until your chin is above the bar."
        } else if (!isGoodForm) {
            feedback = "Keep your elbows closer to your body."
        }
        
        return PullupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = feedback
        )
    }
    
    /**
     * Analyzes a situp exercise from a pose
     */
    fun detectSitup(pose: Pose, prevState: SitupState): SitupState {
        // Only process if we have all required landmarks with sufficient confidence
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val rightHip = pose.getPoseLandmark(PoseLandmark.RIGHT_HIP)
        val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
        val rightKnee = pose.getPoseLandmark(PoseLandmark.RIGHT_KNEE)
        
        // Check if we have all landmarks with sufficient confidence
        val requiredLandmarks = listOf(
            leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee
        )
        
        if (requiredLandmarks.any { it == null || it.inFrameLikelihood < MIN_CONFIDENCE }) {
            return SitupState(
                isUp = false,
                isDown = false,
                count = prevState.count,
                formScore = prevState.formScore,
                feedback = "Position yourself in the frame"
            )
        }
        
        // Calculate angle between shoulders, hips, and knees
        val leftAngle = calculateAngle(
            leftShoulder!!.position,
            leftHip!!.position,
            leftKnee!!.position
        )
        val rightAngle = calculateAngle(
            rightShoulder!!.position,
            rightHip!!.position,
            rightKnee!!.position
        )
        
        // Average the angles
        val hipAngle = (leftAngle + rightAngle) / 2
        
        // Determine situp state
        val isUp = hipAngle < 90 // Torso raised
        val isDown = hipAngle > 160 // Torso flat
        
        // Evaluate form - focus on full range of motion
        val formScore = if (prevState.isDown && isUp) 100 else prevState.formScore
        
        // Calculate new count based on state transition
        var newCount = prevState.count
        var feedback = "Good form. Keep going."
        
        if (prevState.isDown && isUp) {
            // Transitioning from down to up position - count a rep
            newCount++
            feedback = "Great job! $newCount situps completed."
        } else if (isDown) {
            feedback = "Now raise your torso to the up position."
        } else if (isUp) {
            feedback = "Now lower your torso to the starting position."
        }
        
        return SitupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = feedback
        )
    }
    
    /**
     * Calculates the angle between three points
     */
    private fun calculateAngle(a: PointF, b: PointF, c: PointF): Float {
        val angleAB = atan2(a.y - b.y, a.x - b.x)
        val angleBC = atan2(c.y - b.y, c.x - b.x)
        
        var angleDiff = Math.toDegrees((angleBC - angleAB).toDouble()).toFloat()
        
        // Ensure the angle is between 0 and 180
        if (angleDiff < 0) {
            angleDiff += 360
        }
        if (angleDiff > 180) {
            angleDiff = 360 - angleDiff
        }
        
        return angleDiff
    }
    
    /**
     * Calculates the distance between two points
     */
    private fun getDistance(p1: PointF, p2: PointF): Float {
        return sqrt((p1.x - p2.x).pow(2) + (p1.y - p2.y).pow(2))
    }
}