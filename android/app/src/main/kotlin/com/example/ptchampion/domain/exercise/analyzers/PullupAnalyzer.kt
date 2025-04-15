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
 * Concrete implementation of [ExerciseAnalyzer] for pull-ups.
 */
class PullupAnalyzer : ExerciseAnalyzer {

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var maxElbowAngle = 0f // Track max angle during rep for extension check
    private var formIssues = mutableListOf<String>()

    // Constants - These need tuning based on camera angle and setup
    private val FULL_EXTENSION_THRESHOLD = 160f // Angle considered 'straight arms'
    private val MIN_BEND_THRESHOLD = 90f     // Angle indicating arms are significantly bent (top position)
    private val CHIN_OVER_BAR_THRESHOLD_Y = 0.05f // Y-diff between nose/chin and wrist/bar
    private val REQUIRED_VISIBILITY = 0.6f

    override fun analyze(result: PoseLandmarkerHelper.ResultBundle): AnalysisResult {
        formIssues.clear()

        if (result.results.landmarks.isEmpty()) {
            return AnalysisResult(repCount, "No pose detected", ExerciseState.INVALID)
        }

        val landmarks = result.results.landmarks

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
        val nose = landmarks[PoseLandmark.NOSE]
        // Optional: Hips/Knees for kipping detection
        // val leftHip = landmarks[PoseLandmarker.PoseLandmarkName.LEFT_HIP.ordinal()]

        // Calculate elbow angles
        val leftElbowAngle = AngleCalculator.calculateAngle(leftShoulder, leftElbow, leftWrist)
        val rightElbowAngle = AngleCalculator.calculateAngle(rightShoulder, rightElbow, rightWrist)
        val avgElbowAngle = if (leftElbowAngle > 0 && rightElbowAngle > 0) {
            (leftElbowAngle + rightElbowAngle) / 2
        } else {
            -1f
        }

        if (avgElbowAngle < 0) {
            return AnalysisResult(repCount, "Cannot calculate elbow angle", ExerciseState.INVALID)
        }

        // Track maximum elbow angle for full extension check
        if (currentState == ExerciseState.DOWN || (currentState == ExerciseState.STARTING && previousState == ExerciseState.UP)) {
            maxElbowAngle = kotlin.math.max(maxElbowAngle, avgElbowAngle)
        }

        // State machine logic
        previousState = currentState
        currentState = determineState(avgElbowAngle)

        // Rep counting logic
        if (previousState == ExerciseState.DOWN && currentState == ExerciseState.UP) {
            repCount++

            // Check for full extension at the bottom
            if (maxElbowAngle < FULL_EXTENSION_THRESHOLD) {
                formIssues.add("Arms not fully extended at bottom (Elbow: ${maxElbowAngle.toInt()})")
            }
            // Check if chin cleared the bar (simplified)
            checkChinOverBar(nose, leftWrist, rightWrist)

            // Reset max angle for next rep
            maxElbowAngle = 0f
        }

         // Handle transition from IDLE or INVALID to STARTING
        if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
            (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN) ) {
            currentState = ExerciseState.STARTING
        }

        // Generate feedback string
        val feedback = if (formIssues.isNotEmpty()) formIssues.joinToString(". ") else null

        // Calculate form score (placeholder)
        val formScore = calculateFormScore(maxElbowAngle, nose, leftWrist, rightWrist)

        val confidence = result.results.worldLandmarks.map { it.visibility }.average().toFloat()

        return AnalysisResult(
            repCount = repCount,
            feedback = feedback,
            state = currentState,
            confidence = confidence,
            formScore = formScore
        )
    }

    private fun determineState(elbowAngle: Float): ExerciseState {
        // Pull-up states are reversed compared to push-up based on angle
        return when {
            elbowAngle > FULL_EXTENSION_THRESHOLD * 0.95 -> ExerciseState.DOWN // Arms nearly straight
            elbowAngle < MIN_BEND_THRESHOLD -> ExerciseState.UP // Arms significantly bent
            currentState == ExerciseState.IDLE -> ExerciseState.STARTING
            else -> currentState
        }
    }

    private fun checkChinOverBar(nose: MockNormalizedLandmark, leftWrist: MockNormalizedLandmark, rightWrist: MockNormalizedLandmark) {
        // Simplified: Check if nose Y is above average wrist Y
        // Assumes camera is relatively level and wrists represent bar height
        val avgWristY = (leftWrist.y + rightWrist.y) / 2
        if (nose.y > avgWristY + CHIN_OVER_BAR_THRESHOLD_Y) { // Y decreases upwards in image coordinates
            formIssues.add("Chin may not be over bar")
        }
    }

    private fun calculateFormScore(maxElbowAngleAchieved: Float, nose: MockNormalizedLandmark, leftWrist: MockNormalizedLandmark, rightWrist: MockNormalizedLandmark): Int {
        var score = 100

        // Deduct for lack of full extension
        if (maxElbowAngleAchieved < FULL_EXTENSION_THRESHOLD) {
            val extensionPenalty = ((FULL_EXTENSION_THRESHOLD - maxElbowAngleAchieved) * 2).toInt().coerceAtMost(40)
            score -= extensionPenalty
        }

        // Deduct if chin likely didn't clear
        val avgWristY = (leftWrist.y + rightWrist.y) / 2
        if (nose.y > avgWristY + CHIN_OVER_BAR_THRESHOLD_Y) {
            score -= 30
        }

        // TODO: Add deductions for kipping if implemented

        return score.coerceIn(0, 100)
    }

    private fun areKeyLandmarksVisible(landmarks: List<MockNormalizedLandmark>): Boolean {
        val keyPoints = listOf(
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.LEFT_WRIST,
            PoseLandmark.RIGHT_WRIST,
            PoseLandmark.NOSE // Nose is crucial for pull-up height
        )

        return keyPoints.all { landmarks.getOrNull(it)?.visibility ?: 0f >= REQUIRED_VISIBILITY }
    }

    override fun isValidPose(result: PoseLandmarkerHelper.ResultBundle): Boolean {
        if (result.results.landmarks.isEmpty()) {
            return false
        }
        return areKeyLandmarksVisible(result.results.landmarks)
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
        maxElbowAngle = 0f
        formIssues.clear()
    }
} 