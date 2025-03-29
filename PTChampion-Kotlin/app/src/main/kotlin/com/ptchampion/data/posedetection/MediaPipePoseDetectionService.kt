package com.ptchampion.data.posedetection

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
import android.util.Log
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerOptions
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.Delegate
import com.ptchampion.domain.model.PullupState
import com.ptchampion.domain.model.PushupState
import com.ptchampion.domain.model.SitupState
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Service for MediaPipe pose detection and exercise tracking
 */
@Singleton
class MediaPipePoseDetectionService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "MediaPipePoseService"
        private const val MODEL_FILE = "pose_landmarker_full.task"
        private const val MIN_CONFIDENCE = 0.3f
        
        // MediaPipe landmarks map
        const val NOSE = 0
        const val LEFT_EYE_INNER = 1
        const val LEFT_EYE = 2
        const val LEFT_EYE_OUTER = 3
        const val RIGHT_EYE_INNER = 4
        const val RIGHT_EYE = 5
        const val RIGHT_EYE_OUTER = 6
        const val LEFT_EAR = 7
        const val RIGHT_EAR = 8
        const val MOUTH_LEFT = 9
        const val MOUTH_RIGHT = 10
        const val LEFT_SHOULDER = 11
        const val RIGHT_SHOULDER = 12
        const val LEFT_ELBOW = 13
        const val RIGHT_ELBOW = 14
        const val LEFT_WRIST = 15
        const val RIGHT_WRIST = 16
        const val LEFT_PINKY = 17
        const val RIGHT_PINKY = 18
        const val LEFT_INDEX = 19
        const val RIGHT_INDEX = 20
        const val LEFT_THUMB = 21
        const val RIGHT_THUMB = 22
        const val LEFT_HIP = 23
        const val RIGHT_HIP = 24
        const val LEFT_KNEE = 25
        const val RIGHT_KNEE = 26
        const val LEFT_ANKLE = 27
        const val RIGHT_ANKLE = 28
        const val LEFT_HEEL = 29
        const val RIGHT_HEEL = 30
        const val LEFT_FOOT_INDEX = 31
        const val RIGHT_FOOT_INDEX = 32
    }
    
    // MediaPipe pose landmarker
    private val poseLandmarker: PoseLandmarker by lazy {
        val modelFile = File(context.filesDir, MODEL_FILE)
        
        // Create options for the pose landmarker
        val options = PoseLandmarkerOptions.builder()
            .setBaseOptions(
                BaseOptions.builder()
                    .setModelAssetPath(MODEL_FILE)
                    .setDelegate(Delegate.GPU) // GPU acceleration
                    .build()
            )
            .setRunningMode(RunningMode.IMAGE)
            .setNumPoses(1) // Single person tracking
            .build()
        
        PoseLandmarker.createFromOptions(context, options)
    }
    
    /**
     * Detect pose in an image using MediaPipe
     */
    fun detectPose(bitmap: Bitmap): PoseLandmarkerResult? {
        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            return poseLandmarker.detect(mpImage)
        } catch (e: Exception) {
            Log.e(TAG, "MediaPipe pose detection failed", e)
            return null
        }
    }
    
    /**
     * Detect pushup motion with enhanced form analysis
     */
    fun detectPushup(poseResult: PoseLandmarkerResult, prevState: PushupState): PushupState {
        // Check if we have landmarks
        if (poseResult.landmarks().isEmpty()) {
            return prevState.copy(feedback = "Position your full body in view")
        }
        
        val landmarks = poseResult.landmarks()[0]
        
        // Extract key points with confidence check
        val leftShoulder = getPointIfValid(landmarks, LEFT_SHOULDER)
        val rightShoulder = getPointIfValid(landmarks, RIGHT_SHOULDER)
        val leftElbow = getPointIfValid(landmarks, LEFT_ELBOW)
        val rightElbow = getPointIfValid(landmarks, RIGHT_ELBOW)
        val leftWrist = getPointIfValid(landmarks, LEFT_WRIST)
        val rightWrist = getPointIfValid(landmarks, RIGHT_WRIST)
        val leftHip = getPointIfValid(landmarks, LEFT_HIP)
        val rightHip = getPointIfValid(landmarks, RIGHT_HIP)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftElbow == null || rightElbow == null ||
            leftWrist == null || rightWrist == null ||
            leftHip == null || rightHip == null) {
            return prevState.copy(feedback = "Position your full body in view")
        }
        
        // Calculate arm angles
        val leftArmAngle = calculateAngle(leftShoulder, leftElbow, leftWrist)
        val rightArmAngle = calculateAngle(rightShoulder, rightElbow, rightWrist)
        val avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Calculate body alignment
        val bodyLineAngle = calculateBodyLineAngle(
            PointF((leftShoulder.x + rightShoulder.x) / 2, (leftShoulder.y + rightShoulder.y) / 2),
            PointF((leftHip.x + rightHip.x) / 2, (leftHip.y + rightHip.y) / 2)
        )
        
        // Enhanced detection of positions
        val isUp = avgArmAngle > 150 // Arms extended
        val isDown = avgArmAngle < 90 // Arms bent
        
        // Form analysis - significantly enhanced with MediaPipe
        var formScore = 100
        var formFeedback = ""
        
        // Body alignment check
        if (abs(bodyLineAngle - 180) > 15) {
            formScore -= 20
            formFeedback += "Keep your body straight. "
        }
        
        // Arm symmetry check
        if (abs(leftArmAngle - rightArmAngle) > 15) {
            formScore -= 15
            formFeedback += "Keep arms evenly aligned. "
        }
        
        // Hand placement check using additional landmarks
        val leftIndex = getPointIfValid(landmarks, LEFT_INDEX)
        val rightIndex = getPointIfValid(landmarks, RIGHT_INDEX)
        
        if (leftIndex != null && rightIndex != null) {
            // Hand width (distance between hands)
            val handWidth = abs(leftIndex.x - rightIndex.x)
            
            // Shoulder width
            val shoulderWidth = abs(leftShoulder.x - rightShoulder.x)
            
            // Check if hands are properly positioned
            if (handWidth < shoulderWidth * 0.7f) {
                formScore -= 15
                formFeedback += "Hands too close together. "
            } else if (handWidth > shoulderWidth * 1.5f) {
                formScore -= 15
                formFeedback += "Hands too far apart. "
            }
            
            // Check hands under shoulders
            val leftHandAlign = abs(leftWrist.x - leftShoulder.x)
            val rightHandAlign = abs(rightWrist.x - rightShoulder.x)
            
            if (leftHandAlign > shoulderWidth * 0.25f || rightHandAlign > shoulderWidth * 0.25f) {
                formScore -= 10
                formFeedback += "Position hands under shoulders. "
            }
        }
        
        // Depth check - enhanced with MediaPipe
        if (isDown) {
            val shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2
            val wristHeight = (leftWrist.y + rightWrist.y) / 2
            
            if (shoulderHeight - wristHeight < 0.05f) {
                formScore -= 15
                formFeedback += "Lower your chest closer to the ground. "
            }
        }
        
        // Rep counting logic - same as original
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        // Default feedback if none provided
        if (formFeedback.isEmpty()) {
            formFeedback = when {
                isUp && prevState.isDown -> "Good! Keep going"
                isUp -> "Lower your body to start the rep"
                isDown -> "Push up to complete the rep"
                else -> "Keep your body straight"
            }
        }
        
        // Result
        return PushupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = formFeedback
        )
    }
    
    /**
     * Detect pullup motion from pose with enhanced form analysis
     */
    fun detectPullup(poseResult: PoseLandmarkerResult, prevState: PullupState): PullupState {
        // Check if we have landmarks
        if (poseResult.landmarks().isEmpty()) {
            return prevState.copy(feedback = "Position your upper body in view")
        }
        
        val landmarks = poseResult.landmarks()[0]
        
        // Extract key points
        val leftShoulder = getPointIfValid(landmarks, LEFT_SHOULDER)
        val rightShoulder = getPointIfValid(landmarks, RIGHT_SHOULDER)
        val leftElbow = getPointIfValid(landmarks, LEFT_ELBOW)
        val rightElbow = getPointIfValid(landmarks, RIGHT_ELBOW)
        val leftWrist = getPointIfValid(landmarks, LEFT_WRIST)
        val rightWrist = getPointIfValid(landmarks, RIGHT_WRIST)
        val nose = getPointIfValid(landmarks, NOSE)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftElbow == null || rightElbow == null ||
            leftWrist == null || rightWrist == null || nose == null) {
            return prevState.copy(feedback = "Position your upper body in view")
        }
        
        // For pullups, we need to check if the chin is above the hands
        val chinY = nose.y
        val handsY = (leftWrist.y + rightWrist.y) / 2
        
        // Calculate arm angles
        val leftArmAngle = calculateAngle(leftShoulder, leftElbow, leftWrist)
        val rightArmAngle = calculateAngle(rightShoulder, rightElbow, rightWrist)
        val avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Check if in up position (chin above hands, arms bent)
        val isUp = chinY < handsY + 0.05f && avgArmAngle < 100
        
        // Check if in down position (arms extended)
        val isDown = avgArmAngle > 150
        
        // Form analysis
        var formScore = 100
        var formFeedback = ""
        
        // Arm symmetry check
        if (abs(leftArmAngle - rightArmAngle) > 15) {
            formScore -= 15
            formFeedback += "Keep arms evenly aligned. "
        }
        
        // Enhanced chin position check with MediaPipe's nose landmark
        if (isUp && chinY > handsY) {
            formScore -= 20
            formFeedback += "Pull up until your chin is over the bar. "
        }
        
        // Check shoulder activation - new with MediaPipe
        if (isUp) {
            val shoulderDistance = abs(leftShoulder.y - rightShoulder.y)
            if (shoulderDistance > 0.1f) {
                formScore -= 15
                formFeedback += "Keep shoulders level. "
            }
        }
        
        // Rep counting logic
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        // Default feedback if none provided
        if (formFeedback.isEmpty()) {
            formFeedback = when {
                isUp && prevState.isDown -> "Good! Now lower yourself"
                isUp -> "Lower yourself to start the next rep"
                isDown -> "Pull up until your chin is over the bar"
                else -> "Hang with arms extended to start"
            }
        }
        
        return PullupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = formFeedback
        )
    }
    
    /**
     * Detect situp motion from pose with enhanced form analysis
     */
    fun detectSitup(poseResult: PoseLandmarkerResult, prevState: SitupState): SitupState {
        // Check if we have landmarks
        if (poseResult.landmarks().isEmpty()) {
            return prevState.copy(feedback = "Position your body in view")
        }
        
        val landmarks = poseResult.landmarks()[0]
        
        // Extract key points
        val leftShoulder = getPointIfValid(landmarks, LEFT_SHOULDER)
        val rightShoulder = getPointIfValid(landmarks, RIGHT_SHOULDER)
        val leftHip = getPointIfValid(landmarks, LEFT_HIP)
        val rightHip = getPointIfValid(landmarks, RIGHT_HIP)
        val leftKnee = getPointIfValid(landmarks, LEFT_KNEE)
        val rightKnee = getPointIfValid(landmarks, RIGHT_KNEE)
        
        // If critical landmarks are missing, return previous state with feedback
        if (leftShoulder == null || rightShoulder == null || 
            leftHip == null || rightHip == null ||
            leftKnee == null || rightKnee == null) {
            return prevState.copy(feedback = "Position your body in view")
        }
        
        // For situps, we need to check the angle between shoulders, hips, and knees
        val leftSitupAngle = calculateAngle(leftShoulder, leftHip, leftKnee)
        val rightSitupAngle = calculateAngle(rightShoulder, rightHip, rightKnee)
        val avgSitupAngle = (leftSitupAngle + rightSitupAngle) / 2
        
        // Check if in up position (smaller angle, torso is up)
        val isUp = avgSitupAngle < 80
        
        // Check if in down position (larger angle, lying flat)
        val isDown = avgSitupAngle > 160
        
        // Form analysis
        var formScore = 100
        var formFeedback = ""
        
        // Symmetry check
        if (abs(leftSitupAngle - rightSitupAngle) > 15) {
            formScore -= 15
            formFeedback += "Keep your torso centered. "
        }
        
        // Knee position check - enhanced with MediaPipe's additional landmarks
        val leftAnkle = getPointIfValid(landmarks, LEFT_ANKLE)
        val rightAnkle = getPointIfValid(landmarks, RIGHT_ANKLE)
        
        if (leftAnkle != null && rightAnkle != null) {
            val leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle)
            val rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle)
            val avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
            
            if (avgKneeAngle > 110) {
                formScore -= 15
                formFeedback += "Bend your knees more. "
            }
        }
        
        // Rep counting logic
        val newCount = if (prevState.isDown && isUp && !prevState.isUp) {
            prevState.count + 1
        } else {
            prevState.count
        }
        
        // Default feedback if none provided
        if (formFeedback.isEmpty()) {
            formFeedback = when {
                isUp && prevState.isDown -> "Good! Now lower yourself"
                isUp -> "Lower yourself to start the next rep"
                isDown -> "Sit up until your torso is upright"
                else -> "Lie flat to start"
            }
        }
        
        return SitupState(
            isUp = isUp,
            isDown = isDown,
            count = newCount,
            formScore = formScore,
            feedback = formFeedback
        )
    }
    
    /**
     * Get a landmark point if its confidence is above threshold
     */
    private fun getPointIfValid(landmarks: List<NormalizedLandmark>, index: Int): PointF? {
        return if (landmarks.size > index && landmarks[index].visibility() > MIN_CONFIDENCE) {
            PointF(landmarks[index].x(), landmarks[index].y())
        } else null
    }
    
    /**
     * Calculate angle between three points
     */
    private fun calculateAngle(p1: PointF, p2: PointF, p3: PointF): Float {
        // Calculate vectors
        val v1x = p1.x - p2.x
        val v1y = p1.y - p2.y
        val v2x = p3.x - p2.x
        val v2y = p3.y - p2.y
        
        // Calculate angle using atan2
        val angle = Math.toDegrees(
            atan2(
                p1.y - p2.y,
                p1.x - p2.x
            ) - atan2(
                p3.y - p2.y,
                p3.x - p2.x
            )
        ).toFloat()
        
        // Ensure angle is positive
        return abs(angle)
    }
    
    /**
     * Calculate body line angle for pushup form analysis
     */
    private fun calculateBodyLineAngle(shoulders: PointF, hips: PointF): Float {
        // Calculate angle against vertical
        val dx = shoulders.x - hips.x
        val dy = shoulders.y - hips.y
        
        return (atan2(dy, dx) * 180 / Math.PI).toFloat() + 90 // Add 90 to get angle from vertical
    }
    
    /**
     * Clean up resources
     */
    fun close() {
        poseLandmarker.close()
    }
}
