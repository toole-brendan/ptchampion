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

/**
 * Concrete implementation of [ExerciseAnalyzer] for sit-ups.
 */
class SitupAnalyzer : ExerciseAnalyzer {

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var maxHipAngle = 0f // Track max angle during rep for range of motion check
    private var minShoulderWristDist = Float.MAX_VALUE // Track min distance for full situp check
    private var formIssues = mutableListOf<String>()

    // Constants - These threshold values need tuning based on camera angle and user setup
    private val HIP_ANGLE_DOWN_THRESHOLD = 110f // Angle when lying flat should be larger
    private val HIP_ANGLE_UP_THRESHOLD = 70f // Angle when sitting up should be smaller
    private val SHOULDER_ALIGNED_THRESHOLD = 0.15f // Threshold for shoulder alignment
    private val REQUIRED_VISIBILITY = 0.5f

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
        val leftHip = landmarks[PoseLandmark.LEFT_HIP]
        val rightHip = landmarks[PoseLandmark.RIGHT_HIP]
        val leftKnee = landmarks[PoseLandmark.LEFT_KNEE]
        val rightKnee = landmarks[PoseLandmark.RIGHT_KNEE]
        // Additional landmarks may be needed

        // Calculate hip angles (similar to forward fold angle)
        val leftHipAngle = AngleCalculator.calculateAngle(leftShoulder, leftHip, leftKnee)
        val rightHipAngle = AngleCalculator.calculateAngle(rightShoulder, rightHip, rightKnee)
        val avgHipAngle = if (leftHipAngle > 0 && rightHipAngle > 0) {
            (leftHipAngle + rightHipAngle) / 2
        } else {
            -1f
        }

        if (avgHipAngle < 0) {
            return AnalysisResult(repCount, "Cannot calculate hip angle", ExerciseState.INVALID)
        }

        // Track maximum hip angle for range of motion check
        if (currentState == ExerciseState.DOWN || previousState == ExerciseState.DOWN) {
            maxHipAngle = kotlin.math.max(maxHipAngle, avgHipAngle)
        }

        // State machine logic
        previousState = currentState
        currentState = determineState(avgHipAngle)

        // Rep counting logic
        if (previousState == ExerciseState.DOWN && currentState == ExerciseState.UP) {
            repCount++

            // Form check: Sufficient range of motion
            if (maxHipAngle < HIP_ANGLE_DOWN_THRESHOLD) {
                formIssues.add("Not fully extended at the bottom")
            }

            // Check shoulder alignment
            checkShoulderAlignment(leftShoulder, rightShoulder)

            // Reset tracking variables for next rep
            maxHipAngle = 0f
            minShoulderWristDist = Float.MAX_VALUE
        }

        // Handle transition from IDLE or INVALID to STARTING
        if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
            (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN) ) {
            currentState = ExerciseState.STARTING
        }

        // Generate feedback string
        val feedback = if (formIssues.isNotEmpty()) formIssues.joinToString(". ") else null

        // Calculate form score (placeholder)
        val formScore = calculateFormScore(maxHipAngle)

        val confidence = result.results.worldLandmarks.map { it.visibility }.average().toFloat()

        return AnalysisResult(
            repCount = repCount,
            feedback = feedback,
            state = currentState,
            confidence = confidence,
            formScore = formScore
        )
    }

    private fun determineState(hipAngle: Float): ExerciseState {
        return when {
            hipAngle > HIP_ANGLE_DOWN_THRESHOLD -> ExerciseState.DOWN // Nearly flat position
            hipAngle < HIP_ANGLE_UP_THRESHOLD -> ExerciseState.UP // Sitting up position
            currentState == ExerciseState.IDLE -> ExerciseState.STARTING
            else -> currentState
        }
    }

    private fun checkShoulderAlignment(leftShoulder: MockNormalizedLandmark, rightShoulder: MockNormalizedLandmark) {
        val yDiff = abs(leftShoulder.y - rightShoulder.y)
        if (yDiff > SHOULDER_ALIGNED_THRESHOLD) {
            formIssues.add("Keep shoulders level")
        }
    }

    private fun calculateFormScore(maxHipAngleAchieved: Float): Int {
        var score = 100

        // Deduct for insufficient range of motion
        if (maxHipAngleAchieved < HIP_ANGLE_DOWN_THRESHOLD) {
            val romPenalty = ((HIP_ANGLE_DOWN_THRESHOLD - maxHipAngleAchieved) * 1.5).toInt().coerceAtMost(50)
            score -= romPenalty
        }

        return score.coerceIn(0, 100)
    }

    private fun areKeyLandmarksVisible(landmarks: List<MockNormalizedLandmark>): Boolean {
        val keyPoints = listOf(
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_HIP,
            PoseLandmark.RIGHT_HIP,
            PoseLandmark.LEFT_KNEE,
            PoseLandmark.RIGHT_KNEE
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
        maxHipAngle = 0f
        minShoulderWristDist = Float.MAX_VALUE
        formIssues.clear()
    }
} 