package com.example.ptchampion.domain.exercise.analyzers

import android.util.Log
import com.example.ptchampion.domain.exercise.AnalysisResult
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer
import com.example.ptchampion.domain.exercise.ExerciseState
import com.example.ptchampion.domain.exercise.utils.AngleCalculator
import com.example.ptchampion.domain.exercise.utils.PoseLandmark
import com.example.ptchampion.domain.exercise.utils.PoseResultExtensions.getLandmark
import com.example.ptchampion.domain.exercise.utils.PoseResultExtensions.isLandmarkVisible
import com.example.ptchampion.domain.exercise.utils.PoseResultExtensions.areAllLandmarksVisible
import com.example.ptchampion.domain.exercise.utils.PoseResultExtensions.getAverageConfidence
import com.example.ptchampion.posedetection.PoseLandmarkerHelper
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.max
import java.util.Optional
import kotlin.math.sqrt
import kotlin.math.acos
import kotlin.math.pow

/**
 * Analyzer for push-ups according to US Army APFT standards.
 * 
 * Army standards require:
 * - Body forms a generally straight line from head to heels
 * - Starting position has fully extended arms
 * - Lowering until upper arms are at least parallel to the ground
 * - No arching of the back or raising the buttocks
 * - Movement as a single unit
 */
class PushupAnalyzer : ExerciseAnalyzer {

    companion object {
        private const val TAG = "PushupAnalyzer"
        
        // Constants for APFT standard form checking
        private const val MIN_ELBOW_ANGLE_THRESHOLD = 90f  // Upper arms must be parallel to ground
        private const val FULL_EXTENSION_THRESHOLD = 160f  // Arms nearly straight at top
        private const val SHOULDER_ALIGNMENT_THRESHOLD = 0.10f // X-axis alignment tolerance
        private const val HIP_SAG_THRESHOLD = 0.10f // Hip sagging threshold
        private const val HIP_PIKE_THRESHOLD = 0.12f // Hip raising/piking threshold
        private const val BODY_ALIGNMENT_THRESHOLD = 0.15f // Shoulders-hips-ankles alignment
        private const val REQUIRED_VISIBILITY = 0.5f       // Minimum visibility for landmarks
        
        // Key landmarks required for proper pushup analysis
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
            PoseLandmark.LEFT_ANKLE,
            PoseLandmark.RIGHT_ANKLE
        )
    }

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var minElbowAngle = 180f  // Track minimum angle during rep for depth check
    private var maxHipDeviation = 0f  // Track maximum hip deviation from straight line
    private val formIssues = mutableListOf<String>()
    
    // Store previous valid positions for movement analysis
    private var lastValidShoulderY = 0f
    private var lastValidHipY = 0f
    private var lastValidElbowAngle = 180f

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
                feedback = "Position your full body in frame",
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
            val leftAnkle = landmarks[PoseLandmark.LEFT_ANKLE]
            val rightAnkle = landmarks[PoseLandmark.RIGHT_ANKLE]

            // Calculate joint angles
            val leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist)
            val rightElbowAngle = calculateAngle(rightShoulder, rightElbow, rightWrist)
            val avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2

            // Store current position data
            val avgShoulderY = (leftShoulder.y() + rightShoulder.y()) / 2
            val avgHipY = (leftHip.y() + rightHip.y()) / 2
            val avgAnkleY = (leftAnkle.y() + rightAnkle.y()) / 2
            
            // Update position tracking
            if (avgElbowAngle > 0 && avgShoulderY > 0 && avgHipY > 0) {
                lastValidShoulderY = avgShoulderY
                lastValidHipY = avgHipY
                lastValidElbowAngle = avgElbowAngle
            }

            // Update minimum elbow angle during a rep
            if (currentState == ExerciseState.DOWN || 
                (currentState == ExerciseState.STARTING && previousState == ExerciseState.UP)) {
                minElbowAngle = min(minElbowAngle, avgElbowAngle)
            }

            // APFT Form checks
            
            // 1. Body straight line check (shoulders-hips-ankles)
            checkBodyAlignment(leftShoulder, rightShoulder, leftHip, rightHip, leftAnkle, rightAnkle)
            
            // 2. Hip sagging check
            checkHipSag(leftShoulder, rightShoulder, leftHip, rightHip, leftAnkle, rightAnkle)
            
            // 3. Hip piking check (butt raising too high)
            checkHipPike(leftShoulder, rightShoulder, leftHip, rightHip, leftAnkle, rightAnkle)
            
            // 4. Shoulder alignment check (level shoulders)
            checkShoulderAlignment(leftShoulder, rightShoulder)
            
            // 5. Proper arm movement check
            checkArmMovement(avgElbowAngle)

            // State machine logic to track rep phases
            previousState = currentState
            currentState = determineState(avgElbowAngle)

            // Rep counting logic - only count when proper form is maintained
            if (previousState == ExerciseState.DOWN && currentState == ExerciseState.UP) {
                // Check depth at bottom of pushup (did they go low enough?)
                if (minElbowAngle > MIN_ELBOW_ANGLE_THRESHOLD) {
                    formIssues.add("Not low enough (arms weren't parallel to ground)")
                } else {
                    // Only count the rep if it meets depth requirement
                    repCount++
                }
                
                // Reset tracking variables for next rep
                minElbowAngle = 180f
                maxHipDeviation = 0f
            }

            // Handle transition from IDLE or INVALID to STARTING
            if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
                (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN)) {
                currentState = ExerciseState.STARTING
            }

            // Generate feedback message
            val feedback = when {
                formIssues.isNotEmpty() -> formIssues.joinToString(". ")
                currentState == ExerciseState.UP -> "Good form, upper position"
                currentState == ExerciseState.DOWN -> "Good form, lower position"
                currentState == ExerciseState.STARTING -> "Starting position OK"
                else -> null
            }

            // Calculate overall form score
            val formScore = calculateFormScore(
                minElbowAngleAchieved = minElbowAngle,
                bodyDeviations = maxHipDeviation,
                shoulders = Pair(leftShoulder, rightShoulder),
                hips = Pair(leftHip, rightHip)
            )

            // Calculate confidence from landmark visibility
            val confidence = getAverageConfidence(landmarks)

            return AnalysisResult(
                repCount = repCount,
                feedback = feedback,
                state = currentState,
                confidence = confidence,
                formScore = formScore
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error analyzing pose: ${e.message}", e)
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
     * Determines the current push-up state based on the elbow angle.
     */
    private fun determineState(elbowAngle: Float): ExerciseState {
        return when {
            elbowAngle < MIN_ELBOW_ANGLE_THRESHOLD * 1.1 -> ExerciseState.DOWN // Low position
            elbowAngle > FULL_EXTENSION_THRESHOLD * 0.95 -> ExerciseState.UP // High position
            currentState == ExerciseState.IDLE -> ExerciseState.STARTING
            else -> currentState // Maintain current state during transition
        }
    }

    /**
     * Checks if the body forms a straight line from shoulders to ankles.
     * APFT requires the body to move as a unit without sagging or piking.
     */
    private fun checkBodyAlignment(
        leftShoulder: NormalizedLandmark,
        rightShoulder: NormalizedLandmark,
        leftHip: NormalizedLandmark,
        rightHip: NormalizedLandmark,
        leftAnkle: NormalizedLandmark,
        rightAnkle: NormalizedLandmark
    ) {
        // Calculate average y-coordinates (vertical position)
        val avgShoulderY = (leftShoulder.y() + rightShoulder.y()) / 2
        val avgHipY = (leftHip.y() + rightHip.y()) / 2
        val avgAnkleY = (leftAnkle.y() + rightAnkle.y()) / 2
        
        // In a perfect plank position, shoulders, hips and ankles should form a straight line
        // We'll use a linear approximation and check deviation of hips from that line
        
        // Calculate expected hip position if on straight line between shoulders and ankles
        val shoulderToAnkleRatio = 0.5 // Hips should be approximately halfway
        val expectedHipY = avgShoulderY + (avgAnkleY - avgShoulderY) * shoulderToAnkleRatio
        
        // Calculate actual deviation
        val hipDeviation = abs(avgHipY - expectedHipY)
        
        // Track maximum hip deviation during the rep
        maxHipDeviation = kotlin.math.max(maxHipDeviation as Float, hipDeviation as Float)
        
        // Check if deviation exceeds threshold
        if (hipDeviation > BODY_ALIGNMENT_THRESHOLD) {
            if (avgHipY > expectedHipY) {
                formIssues.add("Keep your body straight, hips are sagging")
            } else {
                formIssues.add("Keep your body straight, hips are too high")
            }
        }
    }

    /**
     * Specifically checks for hip sagging (common issue).
     * In APFT, the torso must be kept rigid and move as a unit.
     */
    private fun checkHipSag(
        leftShoulder: NormalizedLandmark,
        rightShoulder: NormalizedLandmark,
        leftHip: NormalizedLandmark,
        rightHip: NormalizedLandmark,
        leftAnkle: NormalizedLandmark,
        rightAnkle: NormalizedLandmark
    ) {
        val avgShoulderX = (leftShoulder.x() + rightShoulder.x()) / 2
        val avgShoulderY = (leftShoulder.y() + rightShoulder.y()) / 2
        val avgShoulderZ = (leftShoulder.z() + rightShoulder.z()) / 2

        val avgHipX = (leftHip.x() + rightHip.x()) / 2
        val avgHipY = (leftHip.y() + rightHip.y()) / 2
        val avgHipZ = (leftHip.z() + rightHip.z()) / 2
        
        val avgAnkleX = (leftAnkle.x() + rightAnkle.x()) / 2
        val avgAnkleY = (leftAnkle.y() + rightAnkle.y()) / 2
        val avgAnkleZ = (leftAnkle.z() + rightAnkle.z()) / 2
        
        // Manual angle calculation using averaged coordinates
        val v1x = avgShoulderX - avgHipX
        val v1y = avgShoulderY - avgHipY
        val v1z = avgShoulderZ - avgHipZ
        val v2x = avgAnkleX - avgHipX
        val v2y = avgAnkleY - avgHipY
        val v2z = avgAnkleZ - avgHipZ
        val dotProduct = v1x * v2x + v1y * v2y + v1z * v2z
        val v1Mag = sqrt(v1x.pow(2) + v1y.pow(2) + v1z.pow(2))
        val v2Mag = sqrt(v2x.pow(2) + v2y.pow(2) + v2z.pow(2))
        
        val hipAngle = if (v1Mag > 0.0001f && v2Mag > 0.0001f) {
            val cosTheta = (dotProduct / (v1Mag * v2Mag)).coerceIn(-1.0f, 1.0f)
            Math.toDegrees(acos(cosTheta).toDouble()).toFloat()
        } else {
            0f // Default angle if magnitude is near zero
        }
        
        // If angle is significantly less than 180, hips are sagging
        if (hipAngle < 160 && avgHipY > (avgShoulderY + avgAnkleY) / 2) {
            formIssues.add("Keep your core tight, hips are sagging")
        }
    }

    /**
     * Checks for hip piking (raising the butt too high).
     * APFT requires the body to maintain a straight line.
     */
    private fun checkHipPike(
        leftShoulder: NormalizedLandmark,
        rightShoulder: NormalizedLandmark,
        leftHip: NormalizedLandmark,
        rightHip: NormalizedLandmark,
        leftAnkle: NormalizedLandmark,
        rightAnkle: NormalizedLandmark
    ) {
        val avgShoulderX = (leftShoulder.x() + rightShoulder.x()) / 2
        val avgShoulderY = (leftShoulder.y() + rightShoulder.y()) / 2
        val avgShoulderZ = (leftShoulder.z() + rightShoulder.z()) / 2

        val avgHipX = (leftHip.x() + rightHip.x()) / 2
        val avgHipY = (leftHip.y() + rightHip.y()) / 2
        val avgHipZ = (leftHip.z() + rightHip.z()) / 2

        val avgAnkleX = (leftAnkle.x() + rightAnkle.x()) / 2
        val avgAnkleY = (leftAnkle.y() + rightAnkle.y()) / 2
        val avgAnkleZ = (leftAnkle.z() + rightAnkle.z()) / 2
        
        // Manual angle calculation using averaged coordinates
        val v1x = avgShoulderX - avgHipX
        val v1y = avgShoulderY - avgHipY
        val v1z = avgShoulderZ - avgHipZ
        val v2x = avgAnkleX - avgHipX
        val v2y = avgAnkleY - avgHipY
        val v2z = avgAnkleZ - avgHipZ
        val dotProduct = v1x * v2x + v1y * v2y + v1z * v2z
        val v1Mag = sqrt(v1x.pow(2) + v1y.pow(2) + v1z.pow(2))
        val v2Mag = sqrt(v2x.pow(2) + v2y.pow(2) + v2z.pow(2))

        val hipAngle = if (v1Mag > 0.0001f && v2Mag > 0.0001f) {
            val cosTheta = (dotProduct / (v1Mag * v2Mag)).coerceIn(-1.0f, 1.0f)
            Math.toDegrees(acos(cosTheta).toDouble()).toFloat()
        } else {
            0f // Default angle if magnitude is near zero
        }
        
        // If angle is significantly more than 180, hips are piked (butt too high)
        if (hipAngle > 200 && avgHipY < (avgShoulderY + avgAnkleY) / 2) {
            formIssues.add("Lower your hips, buttocks are too high")
        }
    }

    /**
     * Checks if shoulders are level (not tilted).
     * APFT requires balanced, controlled movement.
     */
    private fun checkShoulderAlignment(
        leftShoulder: NormalizedLandmark,
        rightShoulder: NormalizedLandmark
    ) {
        val shoulderTilt = abs(leftShoulder.y() - rightShoulder.y())
        if (shoulderTilt > SHOULDER_ALIGNMENT_THRESHOLD) {
            formIssues.add("Keep shoulders level")
        }
    }

    /**
     * Monitors arm movement to ensure proper lowering and raising.
     * APFT requires controlled movement.
     */
    private fun checkArmMovement(currentElbowAngle: Float) {
        // Check for sudden changes in elbow angle which might indicate jerky movements
        val angleDelta = abs(currentElbowAngle - lastValidElbowAngle)
        
        // Only check when in motion (not at extremes)
        if (currentState != ExerciseState.IDLE && 
            currentElbowAngle > MIN_ELBOW_ANGLE_THRESHOLD && 
            currentElbowAngle < FULL_EXTENSION_THRESHOLD) {
            
            // Large sudden changes might indicate jerky motion, not controlled
            if (angleDelta > 30) {
                formIssues.add("Keep movements slow and controlled")
            }
        }
    }

    /**
     * Calculates form score based on APFT standards.
     * Returns 0-100 where 100 is perfect form.
     */
    private fun calculateFormScore(
        minElbowAngleAchieved: Float,
        bodyDeviations: Float,
        shoulders: Pair<NormalizedLandmark, NormalizedLandmark>,
        hips: Pair<NormalizedLandmark, NormalizedLandmark>
    ): Double {
        var score = 100.0
        
        // Penalty for insufficient depth (most critical for APFT)
        if (minElbowAngleAchieved > MIN_ELBOW_ANGLE_THRESHOLD) {
            val depthPenalty = ((minElbowAngleAchieved - MIN_ELBOW_ANGLE_THRESHOLD) * 1.5).toInt()
                .coerceAtMost(50) // Major penalty - up to 50 points
            score -= depthPenalty.toDouble()
        }
        
        // Penalty for body alignment issues
        val alignmentPenalty = (bodyDeviations * 300).toInt().coerceAtMost(40)
        score -= alignmentPenalty.toDouble()
        
        // Penalty for shoulder alignment issues
        val shoulderTilt = abs(shoulders.first.y() - shoulders.second.y())
        if (shoulderTilt > SHOULDER_ALIGNMENT_THRESHOLD) {
            val tiltPenalty = (shoulderTilt * 100).toInt().coerceAtMost(20)
            score -= tiltPenalty.toDouble()
        }
        
        return score.coerceIn(0.0, 100.0)
    }

    /**
     * Calculates the angle between three landmarks.
     */
    private fun calculateAngle(
        first: NormalizedLandmark,
        middle: NormalizedLandmark,
        last: NormalizedLandmark
    ): Float {
        // Calculate vectors from middle point
        val v1x = first.x() - middle.x()
        val v1y = first.y() - middle.y()
        val v1z = first.z() - middle.z()

        val v2x = last.x() - middle.x()
        val v2y = last.y() - middle.y()
        val v2z = last.z() - middle.z()

        // Calculate dot product
        val dotProduct = v1x * v2x + v1y * v2y + v1z * v2z

        // Calculate magnitudes
        val v1Mag = kotlin.math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z)
        val v2Mag = kotlin.math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z)

        // Handle potential division by zero
        if (v1Mag < 0.0001f || v2Mag < 0.0001f) {
            return 0f
        }

        // Calculate angle in radians, clamp to [-1, 1] to avoid NaN from acos
        val cosTheta = (dotProduct / (v1Mag * v2Mag)).coerceIn(-1.0f, 1.0f)
        val angleRad = kotlin.math.acos(cosTheta)

        // Convert to degrees
        return Math.toDegrees(angleRad.toDouble()).toFloat()
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
     * Checks if all key landmarks needed for pushup analysis are visible.
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
        minElbowAngle = 180f
        maxHipDeviation = 0f
        lastValidShoulderY = 0f
        lastValidHipY = 0f
        lastValidElbowAngle = 180f
        formIssues.clear()
    }
} 