package com.example.ptchampion.domain.exercise

/**
 * Data class to hold the results of the exercise analysis for a single frame.
 */
data class AnalysisResult(
    val repCount: Int = 0,
    val feedback: String? = null,
    val formScore: Double = 100.0, // Score out of 100
    val state: ExerciseState? = null,
    val confidence: Float? = null
) 