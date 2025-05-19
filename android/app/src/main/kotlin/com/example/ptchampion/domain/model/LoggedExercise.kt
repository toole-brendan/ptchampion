package com.example.ptchampion.domain.model

import kotlinx.datetime.Instant // Using kotlinx-datetime for timestamps

/**
 * Represents a logged exercise session within the application domain.
 */
data class LoggedExercise(
    val id: Int,
    val userId: Int,
    val exerciseId: Int,
    val exerciseName: String,
    val exerciseType: String,
    val reps: Int?,
    val timeInSeconds: Int?,
    val distance: Int?,
    val notes: String?,
    val grade: Int,
    val createdAt: Instant // Use Instant for better type safety
)
