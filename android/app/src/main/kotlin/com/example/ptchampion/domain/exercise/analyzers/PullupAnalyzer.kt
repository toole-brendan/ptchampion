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
import kotlin.math.min

/**
 * Concrete implementation of [ExerciseAnalyzer] for pull-ups with strict standards.
 * 
 * Pull-up standards applied:
 * - Starting from a dead hang with arms fully extended
 * - Pulling up until chin clears the bar
 * - Controlled descent back to dead hang position
 * - No kipping or swinging (strict pull-ups only)
 * - Maintaining proper body alignment
 */
class PullupAnalyzer : ExerciseAnalyzer {

    companion object {
        private const val TAG = "PullupAnalyzer"
        
        // Constants for proper form
        private const val FULL_EXTENSION_THRESHOLD = 160f // Angle considered 'straight arms'
        private const val MIN_BEND_THRESHOLD = 90f     // Angle indicating arms are significantly bent
        private const val CHIN_OVER_BAR_THRESHOLD_Y = 0.05f // Y-diff between nose/chin and wrist/bar
        private const val KIPPING_THRESHOLD = 0.10f // Allowable hip deviation (proportion of height)
        private const val ELBOW_STABILITY_THRESHOLD = 0.05f // For detecting arm instability
        private const val REQUIRED_STABILITY_FRAMES = 3 // Frames required for state change
        private const val REQUIRED_VISIBILITY = 0.6f // Minimum landmark visibility
        
        // Key landmarks required for proper pullup analysis
        private val KEY_LANDMARKS = listOf(
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.LEFT_WRIST,
            PoseLandmark.RIGHT_WRIST,
            PoseLandmark.NOSE, // Crucial for chin-over-bar detection
            PoseLandmark.LEFT_HIP,
            PoseLandmark.RIGHT_HIP
        )
    }

    private var repCount = 0
    private var currentState = ExerciseState.IDLE
    private var previousState = ExerciseState.IDLE
    private var maxElbowAngle = 0f // Track max angle during rep for extension check
    private var minElbowAngle = 180f // Track min angle during rep for chin-over-bar
    private var startingHipsY = 0f // Reference point for detecting kipping
    private var maxHipsDeviation = 0f // Max deviation from starting position (kipping check)
    private val formIssues = mutableListOf<String>()
    private var consecutiveValidFrames = 0 // For state stability
    private var repInProgress = false // Flag to track if a rep has started

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
                formScore = 0
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
                formScore = 0
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
            val nose = landmarks[PoseLandmark.NOSE]
            val leftHip = landmarks[PoseLandmark.LEFT_HIP]
            val rightHip = landmarks[PoseLandmark.RIGHT_HIP]

            // Calculate elbow angles (critical for pull-up analysis)
            val leftElbowAngle = AngleCalculator.calculateAngle(leftShoulder, leftElbow, leftWrist)
            val rightElbowAngle = AngleCalculator.calculateAngle(rightShoulder, rightElbow, rightWrist)
            val avgElbowAngle = if (leftElbowAngle > 0 && rightElbowAngle > 0) {
                (leftElbowAngle + rightElbowAngle) / 2
            } else {
                -1f
            }

            if (avgElbowAngle < 0) {
                return AnalysisResult(
                    repCount = repCount,
                    feedback = "Cannot calculate elbow angle",
                    state = ExerciseState.INVALID,
                    confidence = getAverageConfidence(landmarks),
                    formScore = 0
                )
            }

            // Calculate average hip position (for kipping detection)
            val avgHipY = (leftHip.y() + rightHip.y()) / 2
            
            // If first valid frame, set reference hip position
            if (currentState == ExerciseState.IDLE && avgElbowAngle > FULL_EXTENSION_THRESHOLD * 0.9) {
                startingHipsY = avgHipY
            }
            
            // Calculate hip deviation from starting position
            val hipDeviation = abs(avgHipY - startingHipsY)
            maxHipsDeviation = kotlin.math.max(maxHipsDeviation, hipDeviation)
            
            // Chin-over-bar detection
            // In MediaPipe coordinates, Y increases moving downward in the image
            val avgWristY = (leftWrist.y() + rightWrist.y()) / 2 // Approximates bar position
            val chinOverBar = nose.y() <= (avgWristY - CHIN_OVER_BAR_THRESHOLD_Y)

            // Track maximum elbow angle for full extension check
            if (currentState == ExerciseState.DOWN || 
                (currentState == ExerciseState.STARTING && previousState == ExerciseState.UP)) {
                maxElbowAngle = kotlin.math.max(maxElbowAngle, avgElbowAngle)
            }
            
            // Track minimum elbow angle for proper pull-up height check
            if (currentState == ExerciseState.UP || 
                (currentState == ExerciseState.STARTING && previousState == ExerciseState.DOWN)) {
                minElbowAngle = kotlin.math.min(minElbowAngle, avgElbowAngle)
            }

            // Determine state with stability check
            val detectedState = determineState(avgElbowAngle, chinOverBar)
            
            if (detectedState == currentState) {
                consecutiveValidFrames++
            } else {
                consecutiveValidFrames = 0
            }
            
            // Only change state if stable for a few frames
            if (consecutiveValidFrames >= REQUIRED_STABILITY_FRAMES) {
                previousState = currentState
                currentState = detectedState
                
                // Start tracking a rep when transitioning from DOWN to anything else
                if (previousState == ExerciseState.DOWN && currentState != ExerciseState.DOWN && !repInProgress) {
                    repInProgress = true
                    // Reset tracking values for this rep
                    maxHipsDeviation = 0f
                }
                
                // Rep counting logic - a rep is complete when returning to DOWN from UP
                if (previousState == ExerciseState.UP && currentState == ExerciseState.DOWN && repInProgress) {
                    repCount++
                    repInProgress = false
                    
                    // Form checks for the completed rep
                    
                    // Check for full extension at the bottom
                    if (maxElbowAngle < FULL_EXTENSION_THRESHOLD) {
                        formIssues.add("Arms not fully extended at bottom")
                    }
                    
                    // Check for proper chin-over-bar at top
                    if (minElbowAngle > MIN_BEND_THRESHOLD) {
                        formIssues.add("Pull up higher - chin must clear bar")
                    }
                    
                    // Check for kipping (excessive hip movement)
                    if (maxHipsDeviation > KIPPING_THRESHOLD) {
                        formIssues.add("Excessive hip movement detected")
                    }
                    
                    // Reset tracking values for next rep
                    maxElbowAngle = 0f
                    minElbowAngle = 180f
                    maxHipsDeviation = 0f
                }
            }

            // Handle transition from IDLE or INVALID to STARTING
            if ((previousState == ExerciseState.IDLE || previousState == ExerciseState.INVALID) &&
                (currentState == ExerciseState.UP || currentState == ExerciseState.DOWN)) {
                currentState = ExerciseState.STARTING
            }

            // Generate position-specific feedback
            var positionFeedback = when (currentState) {
                ExerciseState.UP -> "Chin above bar"
                ExerciseState.DOWN -> "Full extension"
                ExerciseState.STARTING -> "Starting position"
                ExerciseState.IDLE -> "Hang with arms extended"
                ExerciseState.INVALID -> "Position not recognized"
                ExerciseState.FINISHED -> "Exercise complete"
            }
            
            // Active feedback on current position
            if (currentState == ExerciseState.DOWN && maxElbowAngle < FULL_EXTENSION_THRESHOLD) {
                positionFeedback = "Extend arms fully"
            } else if (currentState == ExerciseState.UP && !chinOverBar) {
                positionFeedback = "Pull higher - chin above bar"
            }

            // Generate complete feedback string
            val feedback = if (formIssues.isNotEmpty()) {
                "$positionFeedback. ${formIssues.joinToString(". ")}"
            } else {
                positionFeedback
            }

            // Calculate form score
            val formScore = calculateFormScore(
                maxElbowAngle, 
                minElbowAngle, 
                maxHipsDeviation,
                chinOverBar
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
                feedback = "Error analyzing pose",
                state = ExerciseState.INVALID,
                confidence = 0f,
                formScore = 0
            )
        }
    }

    /**
     * Determines the current state based on elbow angle and chin position.
     */
    private fun determineState(elbowAngle: Float, chinOverBar: Boolean): ExerciseState {
        return when {
            // DOWN state - arms nearly straight in hanging position
            elbowAngle > FULL_EXTENSION_THRESHOLD * 0.9f -> ExerciseState.DOWN
            
            // UP state - arms bent significantly and chin over bar
            elbowAngle < MIN_BEND_THRESHOLD && chinOverBar -> ExerciseState.UP
            
            // If in between or transitioning, maintain current state
            currentState == ExerciseState.IDLE -> ExerciseState.STARTING
            
            else -> currentState 
        }
    }

    /**
     * Calculates form score based on strict pull-up standards.
     * Returns 0-100 where 100 is perfect form.
     */
    private fun calculateFormScore(
        maxElbowAngleAchieved: Float,
        minElbowAngleAchieved: Float,
        hipDeviation: Float,
        chinOverBar: Boolean
    ): Int {
        var score = 100
        
        // Deduct for insufficient extension at bottom
        if (maxElbowAngleAchieved < FULL_EXTENSION_THRESHOLD) {
            val extensionPenalty = ((FULL_EXTENSION_THRESHOLD - maxElbowAngleAchieved) * 0.5f).toInt()
            score -= extensionPenalty.coerceAtMost(30)
        }
        
        // Deduct for insufficient height (chin not clearing bar)
        if (minElbowAngleAchieved > MIN_BEND_THRESHOLD || !chinOverBar) {
            val heightPenalty = ((minElbowAngleAchieved - MIN_BEND_THRESHOLD) * 0.5f).toInt().coerceAtMost(20)
            score -= heightPenalty + (if (!chinOverBar) 20 else 0)
        }
        
        // Deduct for kipping/swinging
        if (hipDeviation > KIPPING_THRESHOLD) {
            val kippingPenalty = ((hipDeviation - KIPPING_THRESHOLD) * 300).toInt().coerceAtMost(40)
            score -= kippingPenalty
        }
        
        return score.coerceIn(0, 100)
    }

    /**
     * Gets the average confidence across all landmarks.
     */
    private fun getAverageConfidence(landmarks: List<NormalizedLandmark>): Float {
        if (landmarks.isEmpty()) return 0f
        // Handle Optional<Float>, provide default 0f if visibility is absent
        val visibilities = landmarks.mapNotNull { it.visibility().orElse(0f) }
        return if (visibilities.isNotEmpty()) visibilities.average().toFloat() else 0f
    }

    /**
     * Checks if all key landmarks needed for pullup analysis are visible.
     */
    private fun areKeyLandmarksVisible(landmarks: List<NormalizedLandmark>): Boolean {
        if (landmarks.size < 33) return false // Full pose has 33 landmarks
        
        return KEY_LANDMARKS.all { 
            // Get visibility value or default to 0f before comparison
            (landmarks[it].visibility().orElse(0f)) >= REQUIRED_VISIBILITY 
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
        maxElbowAngle = 0f
        minElbowAngle = 180f
        startingHipsY = 0f
        maxHipsDeviation = 0f
        formIssues.clear()
        consecutiveValidFrames = 0
        repInProgress = false
    }
} 