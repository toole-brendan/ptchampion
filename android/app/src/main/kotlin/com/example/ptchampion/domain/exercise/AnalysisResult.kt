package com.example.ptchampion.domain.exercise

/**
 * Represents the result of exercise analysis for a single frame.
 *
 * @property repCount Current repetition count.
 * @property feedback Optional feedback message about form or positioning.
 * @property state Current state of the exercise.
 * @property confidence Confidence level of the pose detection (0.0-1.0).
 * @property formScore Quality score for exercise form (0-100).
 */
data class AnalysisResult(
    val repCount: Int,
    val feedback: String? = null,
    val state: ExerciseState,
    val confidence: Float = 0f,
    val formScore: Int = 0  // 0-100 score based on form quality
) 