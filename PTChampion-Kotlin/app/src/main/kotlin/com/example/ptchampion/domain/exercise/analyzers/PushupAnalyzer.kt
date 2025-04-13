package com.example.ptchampion.domain.exercise.analyzers

import com.example.ptchampion.domain.exercise.AnalysisResult
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer
import com.example.ptchampion.domain.exercise.ExerciseState
import com.example.ptchampion.domain.exercise.utils.AngleCalculator
import com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark
import com.example.ptchampion.domain.exercise.utils.PoseLandmark
import com.example.ptchampion.domain.exercise.utils.landmarks
import com.example.ptchampion.domain.exercise.utils.visibility
import com.example.ptchampion.domain.exercise.utils.worldLandmarks
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import kotlin.math.abs
import kotlin.math.min

/**
 * Concrete implementation of [ExerciseAnalyzer] for push-ups.
 */
class PushupAnalyzer : ExerciseAnalyzer {

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var minElbowAngle = 180f  // Track minimum angle during a rep for depth check
    private var formIssues = mutableListOf<String>()

    // Constants for form analysis - These can be tuned
    private val MIN_ELBOW_ANGLE_THRESHOLD = 80f  // Arms should bend significantly at the bottom
    private val FULL_EXTENSION_THRESHOLD = 160f  // Arms nearly straight at top
    private val SHOULDER_ALIGNMENT_THRESHOLD = 0.15f // X-axis alignment tolerance
    private val HIP_SAG_THRESHOLD = 0.08f // Y-axis difference threshold
    private val REQUIRED_VISIBILITY = 0.5f       // Minimum visibility for a landmark to be considered

    override fun analyze(result: PoseLandmarkerHelper.ResultBundle): AnalysisResult {
        formIssues.clear()

        // Ensure pose data is available
        if (result.results.landmarks.isEmpty()) {
            return AnalysisResult(repCount, "No pose detected", ExerciseState.INVALID)
        }

        val landmarks = result.results.landmarks

        // Check if key landmarks are visible before proceeding
        if (!areKeyLandmarksVisible(landmarks)) {
            return AnalysisResult(repCount, "Position yourself fully in frame", ExerciseState.INVALID, 0f)
        }

        // Get key landmarks
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

        // Calculate angles
        val leftElbowAngle = AngleCalculator.calculateAngle(leftShoulder, leftElbow, leftWrist)
        val rightElbowAngle = AngleCalculator.calculateAngle(rightShoulder, rightElbow, rightWrist)

        // Use the average or the minimum angle, depending on desired strictness
        val avgElbowAngle = if (leftElbowAngle > 0 && rightElbowAngle > 0) {
            (leftElbowAngle + rightElbowAngle) / 2
        } else {
             -1f // Indicate error or insufficient data
        }

        if (avgElbowAngle < 0) {
            return AnalysisResult(repCount, "Cannot calculate elbow angle", ExerciseState.INVALID)
        }

        // Update minimum elbow angle reached during the down phase
        if (currentState == ExerciseState.DOWN || (currentState == ExerciseState.STARTING && previousState == ExerciseState.UP)) {
            minElbowAngle = min(minElbowAngle, avgElbowAngle)
        }

        // Form Checks
        checkShoulderAlignment(leftShoulder, rightShoulder)
        checkHipSag(leftShoulder, rightShoulder, leftHip, rightHip)

        // State machine logic
        previousState = currentState
        currentState = determineState(avgElbowAngle)

        // Rep counting logic
        if (previousState == ExerciseState.DOWN && currentState == ExerciseState.UP) {
            repCount++
            // Check depth after completing the rep
            if (minElbowAngle > MIN_ELBOW_ANGLE_THRESHOLD) {
                formIssues.add("Go deeper (elbow angle: ${minElbowAngle.toInt()}°)")
            }
            // Reset min angle for the next rep
            minElbowAngle = 180f
        }

        // Handle transition from IDLE or INVALID to STARTING
        if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
            (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN) ) {
            currentState = ExerciseState.STARTING
        }

        // Generate feedback string
        val feedback = if (formIssues.isNotEmpty()) formIssues.joinToString(". ") else null

        // Calculate form score (placeholder)
        val formScore = calculateFormScore(
            minElbowAngleAchieved = minElbowAngle,
            shoulders = Pair(leftShoulder, rightShoulder),
            hips = Pair(leftHip, rightHip)
        )

        // Use overall pose confidence from MediaPipe results
        val confidence = result.results.worldLandmarks.map { it.visibility }.average().toFloat()

        return AnalysisResult(
            repCount = repCount,
            feedback = feedback,
            state = currentState,
            confidence = confidence,
            formScore = formScore
        )
    }

    /**
     * Determines the current state based on the average elbow angle.
     */
    private fun determineState(elbowAngle: Float): ExerciseState {
        return when {
            elbowAngle < MIN_ELBOW_ANGLE_THRESHOLD * 1.2 -> ExerciseState.DOWN // Arms significantly bent
            elbowAngle > FULL_EXTENSION_THRESHOLD * 0.9 -> ExerciseState.UP // Arms nearly straight
            currentState == ExerciseState.IDLE -> ExerciseState.STARTING // Initial movement detected
            else -> currentState // Maintain current state if in transition zone
        }
    }

    /**
     * Checks if the shoulders are aligned horizontally.
     * Adds form issues if misalignment exceeds the threshold.
     */
    private fun checkShoulderAlignment(leftShoulder: MockNormalizedLandmark, rightShoulder: MockNormalizedLandmark) {
        val horizontalOffset = abs(leftShoulder.y - rightShoulder.y)
        if (horizontalOffset > SHOULDER_ALIGNMENT_THRESHOLD) {
            formIssues.add("Keep shoulders level")
        }
    }

    /**
     * Checks if the hips are sagging.
     * Adds form issues if the hips are significantly lower than the shoulders.
     */
    private fun checkHipSag(
        leftShoulder: MockNormalizedLandmark,
        rightShoulder: MockNormalizedLandmark,
        leftHip: MockNormalizedLandmark,
        rightHip: MockNormalizedLandmark
    ) {
        // Average Y positions
        val avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2
        val avgHipY = (leftHip.y + rightHip.y) / 2

        // Check if hips are significantly lower than shoulders
        // Note: In normalized coordinates, y increases downwards in the image
        val hipSag = abs(avgHipY - avgShoulderY)
        if (hipSag > HIP_SAG_THRESHOLD) {
            formIssues.add("Keep your core tight, hips are sagging")
        }
    }

    /**
     * Calculates a basic form score (0-100).
     * Deducts points for insufficient depth and hip sag.
     */
    private fun calculateFormScore(
        minElbowAngleAchieved: Float,
        shoulders: Pair<MockNormalizedLandmark, MockNormalizedLandmark>,
        hips: Pair<MockNormalizedLandmark, MockNormalizedLandmark>
    ): Int {
        var score = 100

        // Deduct points for insufficient depth
        if (minElbowAngleAchieved > MIN_ELBOW_ANGLE_THRESHOLD) {
            // More deduction for larger deviation
            val depthPenalty = ((minElbowAngleAchieved - MIN_ELBOW_ANGLE_THRESHOLD) * 1.5).toInt().coerceAtMost(40)
            score -= depthPenalty
        }

        // Deduct for poor shoulder alignment
        val horizontalOffset = abs(shoulders.first.y - shoulders.second.y)
        if (horizontalOffset > SHOULDER_ALIGNMENT_THRESHOLD) {
            val alignmentPenalty = (horizontalOffset * 200).toInt().coerceAtMost(30)
            score -= alignmentPenalty
        }

        // Deduct for hip sag
        val avgShoulderY = (shoulders.first.y + shoulders.second.y) / 2
        val avgHipY = (hips.first.y + hips.second.y) / 2
        val hipSag = abs(avgHipY - avgShoulderY)
        
        if (hipSag > HIP_SAG_THRESHOLD) {
            val sagPenalty = (hipSag * 300).toInt().coerceAtMost(30)
            score -= sagPenalty 
        }

        // TODO: Add deductions for other factors like elbow flare if implemented

        return score.coerceIn(0, 100)
    }

    /**
     * Checks if all essential landmarks for pushup analysis are visible.
     */
    private fun areKeyLandmarksVisible(landmarks: List<MockNormalizedLandmark>): Boolean {
        val keyPoints = listOf(
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.LEFT_WRIST,
            PoseLandmark.RIGHT_WRIST,
            PoseLandmark.LEFT_HIP,
            PoseLandmark.RIGHT_HIP
        )

        return keyPoints.all { landmarks.getOrNull(it)?.visibility ?: 0f >= REQUIRED_VISIBILITY }
    }

    /**
     * Checks if the detected pose is suitable for starting analysis.
     * Requires key landmarks to be visible.
     */
    override fun isValidPose(result: PoseLandmarkerHelper.ResultBundle): Boolean {
        if (result.results.landmarks.isEmpty()) {
            return false
        }
        return areKeyLandmarksVisible(result.results.landmarks)
    }

    override fun start() {
        reset()
        currentState = ExerciseState.STARTING // Move to starting state when explicitly started
    }

    override fun stop() {
        currentState = ExerciseState.FINISHED
    }

    override fun reset() {
        repCount = 0
        currentState = ExerciseState.IDLE
        previousState = ExerciseState.IDLE
        minElbowAngle = 180f
        formIssues.clear()
    }
} 