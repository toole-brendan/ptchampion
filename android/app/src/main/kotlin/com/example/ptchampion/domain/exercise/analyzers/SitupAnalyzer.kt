package com.example.ptchampion.domain.exercise.analyzers

import android.util.Log
import com.example.ptchampion.domain.exercise.AnalysisResult
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer
import com.example.ptchampion.domain.exercise.ExerciseState
import com.example.ptchampion.domain.exercise.utils.AngleCalculator
import com.example.ptchampion.domain.exercise.utils.PoseLandmark
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import kotlin.math.abs

/**
 * SitupAnalyzer for analyzing sit-ups based on US Army APFT standards:
 * - Feet may be held by another person (not detected by pose detection)
 * - Arms crossed over chest with hands on opposite shoulders
 * - Back must curl up to touch elbows to thighs
 * - Shoulder blades must touch the ground in down position
 */
class SitupAnalyzer : ExerciseAnalyzer {

    companion object {
        private const val TAG = "SitupAnalyzer"
        
        // Constants for APFT standards
        private const val HIP_ANGLE_DOWN_THRESHOLD = 150f // Fairly straight when lying back
        private const val HIP_ANGLE_UP_THRESHOLD = 70f // Angle when sitting up properly
        private const val SHOULDER_BLADE_GROUND_THRESHOLD = 0.05f // Y-distance between shoulders and back
        private const val ELBOW_THIGH_DISTANCE_THRESHOLD = 0.10f // Threshold for elbows touching thighs
        private const val ARMS_CROSSED_THRESHOLD = 0.15f // Threshold for detecting crossed arms
        private const val REQUIRED_STABILITY_FRAMES = 3 // Frames required for state change
        private const val REQUIRED_VISIBILITY = 0.6f // Landmark visibility threshold
        
        // Key landmarks required for proper situp analysis
        private val KEY_LANDMARKS = listOf(
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.LEFT_WRIST,
            PoseLandmark.RIGHT_WRIST,
            PoseLandmark.LEFT_HIP,
            PoseLandmark.RIGHT_HIP,
            PoseLandmark.LEFT_KNEE,
            PoseLandmark.RIGHT_KNEE,
            PoseLandmark.NOSE
        )
    }

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var maxHipAngle = 0f // Track max angle during rep (when lying flat)
    private var minHipAngle = Float.MAX_VALUE // Track min angle (when sitting up)
    private var maxShoulderToHipDistance = 0f // Track distance for shoulder blade check
    private val formIssues = mutableListOf<String>()
    private var consecutiveValidFrames = 0 // For state stability
    private var armPositionCorrect = false // Track if arms are properly crossed

    override fun analyze(resultBundle: PoseLandmarkerHelper.ResultBundle): AnalysisResult {
        formIssues.clear()
        
        // Extract MediaPipe results
        val results = resultBundle.results
        
        // Ensure we have landmarks
        if (results.landmarks().isEmpty()) {
            return AnalysisResult(
                repCount = repCount,
                feedback = "No pose detected",
                state = ExerciseState.INVALID,
                confidence = 0f,
                formScore = 0.0
            )
        }
        
        // Get the first person's landmarks
        val landmarks = results.landmarks()[0]
        
        // Check if we have necessary landmarks with good visibility
        if (!areKeyLandmarksVisible(landmarks)) {
            return AnalysisResult(
                repCount = repCount,
                feedback = "Position yourself fully in frame",
                state = ExerciseState.INVALID,
                confidence = getAverageConfidence(landmarks),
                formScore = 0.0
            )
        }

        try {
            // Extract key landmarks for analysis
            val leftShoulder = landmarks[PoseLandmark.LEFT_SHOULDER]
            val rightShoulder = landmarks[PoseLandmark.RIGHT_SHOULDER]
            val leftElbow = landmarks[PoseLandmark.LEFT_ELBOW]
            val rightElbow = landmarks[PoseLandmark.RIGHT_ELBOW]
            val leftWrist = landmarks[PoseLandmark.LEFT_WRIST]
            val rightWrist = landmarks[PoseLandmark.RIGHT_WRIST]
            val leftHip = landmarks[PoseLandmark.LEFT_HIP]
            val rightHip = landmarks[PoseLandmark.RIGHT_HIP]
            val leftKnee = landmarks[PoseLandmark.LEFT_KNEE]
            val rightKnee = landmarks[PoseLandmark.RIGHT_KNEE]
            val nose = landmarks[PoseLandmark.NOSE] // Used to verify sitting up posture

            // Calculate hip angles (torso to legs angle)
            val leftHipAngle = AngleCalculator.calculateAngle(leftShoulder, leftHip, leftKnee)
            val rightHipAngle = AngleCalculator.calculateAngle(rightShoulder, rightHip, rightKnee)
            val avgHipAngle = if (leftHipAngle > 0 && rightHipAngle > 0) {
                (leftHipAngle + rightHipAngle) / 2
            } else {
                -1f
            }

            if (avgHipAngle < 0) {
                return AnalysisResult(
                    repCount = repCount,
                    feedback = "Cannot calculate hip angle",
                    state = ExerciseState.INVALID,
                    confidence = getAverageConfidence(landmarks),
                    formScore = 0.0
                )
            }

            // Check if arms are properly crossed over chest
            checkArmPosition(leftElbow, rightElbow, leftWrist, rightWrist, leftShoulder, rightShoulder)

            // Calculate shoulder blade to ground distance approximation
            // In MediaPipe, Y increases downward in the image
            val avgShoulderY = (leftShoulder.y() + rightShoulder.y()) / 2
            val avgHipY = (leftHip.y() + rightHip.y()) / 2
            
            // Calculate approx. distance of elbows to thighs to detect up position
            val avgElbowY = (leftElbow.y() + rightElbow.y()) / 2
            val avgKneeY = (leftKnee.y() + rightKnee.y()) / 2
            val elbowToThighYDist = abs(avgElbowY - avgKneeY)

            // Update tracking values
            if (currentState == ExerciseState.DOWN || previousState == ExerciseState.DOWN) {
                // When in down position, track maximum hip angle (should be large/flat)
                maxHipAngle = kotlin.math.max(maxHipAngle, avgHipAngle)
                // Track max shoulder-to-hip distance for shoulder blade touching ground
                maxShoulderToHipDistance = kotlin.math.max(maxShoulderToHipDistance, abs(avgShoulderY - avgHipY))
            }
            
            if (currentState == ExerciseState.UP || previousState == ExerciseState.UP) {
                // When in up position, track minimum hip angle (should be small/bent)
                minHipAngle = kotlin.math.min(minHipAngle, avgHipAngle)
            }

            // Determine state with stability check
            val detectedState = determineState(avgHipAngle, elbowToThighYDist)
            
            if (detectedState == currentState) {
                consecutiveValidFrames++
            } else {
                consecutiveValidFrames = 0
            }
            
            // Only change state if stable for a few frames
            if (consecutiveValidFrames >= REQUIRED_STABILITY_FRAMES) {
                previousState = currentState
                currentState = detectedState
                
                // Rep counting logic
                if (previousState == ExerciseState.UP && currentState == ExerciseState.DOWN) {
                    // A rep is completed when transitioning from UP to DOWN
                    repCount++
                    
                    // Check form for completed rep
                    if (maxHipAngle < HIP_ANGLE_DOWN_THRESHOLD) {
                        formIssues.add("Back not flat in down position")
                    }
                    
                    if (minHipAngle > HIP_ANGLE_UP_THRESHOLD) {
                        formIssues.add("Not curling up enough")
                    }
                    
                    if (!armPositionCorrect) {
                        formIssues.add("Arms should be crossed over chest")
                    }
                    
                    // Reset tracking values for next rep
                    maxHipAngle = 0f
                    minHipAngle = Float.MAX_VALUE
                    maxShoulderToHipDistance = 0f
                }
            }

            // Handle transition from IDLE or INVALID to STARTING
            if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
                (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN)) {
                currentState = ExerciseState.STARTING
            }

            // Generate feedback - current position feedback
            val positionFeedback = when (currentState) {
                ExerciseState.UP -> "Up position"
                ExerciseState.DOWN -> "Down position"
                ExerciseState.STARTING -> "Starting position"
                ExerciseState.IDLE -> "Get in starting position"
                ExerciseState.INVALID -> "Position not recognized"
                ExerciseState.FINISHED -> "Exercise complete"
            }

            // Generate feedback string
            val feedback = if (formIssues.isNotEmpty()) {
                "${positionFeedback}. ${formIssues.joinToString(". ")}"
            } else {
                positionFeedback
            }

            // Calculate form score
            val formScore = calculateFormScore(
                maxHipAngle, 
                minHipAngle, 
                armPositionCorrect
            )

            // Calculate average confidence from landmark visibility
            val confidence = getAverageConfidence(landmarks)

            return AnalysisResult(
                repCount = repCount,
                feedback = feedback,
                state = currentState,
                confidence = confidence,
                formScore = formScore
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error during sit-up analysis: ${e.message}", e)
            return AnalysisResult(
                repCount = repCount,
                feedback = "Error during analysis",
                state = ExerciseState.INVALID,
                confidence = 0f,
                formScore = 0.0
            )
        }
    }

    /**
     * Determines the current state based on body position.
     */
    private fun determineState(hipAngle: Float, elbowToThighDistance: Float): ExerciseState {
        return when {
            // DOWN position: Nearly straight hip angle (lying flat)
            hipAngle > 130f -> ExerciseState.DOWN
            
            // UP position: Bent at hips and elbows near thighs
            hipAngle < 90f && elbowToThighDistance < ELBOW_THIGH_DISTANCE_THRESHOLD -> ExerciseState.UP
            
            // Default state if in transition or not clearly in UP/DOWN
            else -> {
                if (currentState == ExerciseState.IDLE) ExerciseState.STARTING 
                else currentState
            }
        }
    }

    /**
     * Checks if arms are properly crossed over chest according to APFT standards.
     */
    private fun checkArmPosition(
        leftElbow: NormalizedLandmark,
        rightElbow: NormalizedLandmark,
        leftWrist: NormalizedLandmark,
        rightWrist: NormalizedLandmark,
        leftShoulder: NormalizedLandmark,
        rightShoulder: NormalizedLandmark
    ) {
        // Check if arms are crossed over chest (APFT standard)
        // This is an approximation as MediaPipe may not clearly show crossed arms
        
        // Check if wrists are near opposite shoulders
        val leftWristToRightShoulder = AngleCalculator.calculateDistance(leftWrist, rightShoulder)
        val rightWristToLeftShoulder = AngleCalculator.calculateDistance(rightWrist, leftShoulder)
        
        // Check if elbows are relatively close to the body
        val leftElbowToLeftHip = AngleCalculator.calculateDistance(leftElbow, leftShoulder)
        val rightElbowToRightHip = AngleCalculator.calculateDistance(rightElbow, rightShoulder)
        
        // Set the arm position flag
        armPositionCorrect = (leftWristToRightShoulder < ARMS_CROSSED_THRESHOLD || 
                             rightWristToLeftShoulder < ARMS_CROSSED_THRESHOLD) &&
                             leftElbowToLeftHip < 0.3f &&
                             rightElbowToRightHip < 0.3f
    }

    /**
     * Calculates form score based on APFT standards.
     * Returns 0-100 where 100 is perfect form.
     */
    private fun calculateFormScore(
        maxHipAngleAchieved: Float,
        minHipAngleAchieved: Float,
        armsCorrect: Boolean
    ): Double {
        var score = 100.0
        
        // Deduct for insufficient back flatness in down position
        if (maxHipAngleAchieved < HIP_ANGLE_DOWN_THRESHOLD) {
            val backFlatnessPenalty = ((HIP_ANGLE_DOWN_THRESHOLD - maxHipAngleAchieved) * 0.5).toInt()
            score -= backFlatnessPenalty.coerceAtMost(30)
        }
        
        // Deduct for insufficient curl in up position
        if (minHipAngleAchieved > HIP_ANGLE_UP_THRESHOLD) {
            val curlPenalty = ((minHipAngleAchieved - HIP_ANGLE_UP_THRESHOLD) * 0.8).toInt()
            score -= curlPenalty.coerceAtMost(40)
        }
        
        // Deduct for incorrect arm position
        if (!armsCorrect) {
            score -= 20.0
        }
        
        return score.coerceIn(0.0, 100.0)
    }

    /**
     * Gets the average confidence across all landmarks.
     */
    private fun getAverageConfidence(landmarks: List<NormalizedLandmark>): Float {
        if (landmarks.isEmpty()) return 0f
        // Use the getVisibility extension function to safely handle Optional<Float> values
        val visibilities = landmarks.map { it.getVisibility() }
        return if (visibilities.isNotEmpty()) visibilities.average().toFloat() else 0f
    }

    /**
     * Checks if all key landmarks needed for situp analysis are visible.
     */
    private fun areKeyLandmarksVisible(landmarks: List<NormalizedLandmark>): Boolean {
        if (landmarks.size < 33) return false // Full pose has 33 landmarks
        
        return KEY_LANDMARKS.all { landmarkIndex ->
            val landmark = landmarks.getOrNull(landmarkIndex)
            // Use the getVisibility extension function for consistent handling
            landmark != null && landmark.getVisibility() >= REQUIRED_VISIBILITY 
        }
    }

    override fun isValidPose(resultBundle: PoseLandmarkerHelper.ResultBundle): Boolean {
        if (resultBundle.results.landmarks().isEmpty()) return false
        return areKeyLandmarksVisible(resultBundle.results.landmarks()[0])
    }

    override fun start() {
        reset()
        currentState = ExerciseState.STARTING
    }

    override fun stop() {
        currentState = ExerciseState.FINISHED
    }

    override fun reset() {
        repCount = 0
        currentState = ExerciseState.IDLE
        previousState = ExerciseState.IDLE
        maxHipAngle = 0f
        minHipAngle = Float.MAX_VALUE
        maxShoulderToHipDistance = 0f
        formIssues.clear()
        consecutiveValidFrames = 0
        armPositionCorrect = false
    }
} 