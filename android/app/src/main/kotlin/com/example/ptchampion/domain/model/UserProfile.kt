package com.example.ptchampion.domain.model

import kotlinx.datetime.Instant
import kotlinx.datetime.toInstant

/**
 * Represents a user's profile in the application.
 * This contains user data that is displayed in the profile section.
 */
data class UserProfile(
    val id: Int,
    val username: String,
    val displayName: String? = null,
    val email: String? = null,
    val createdAt: String? = null,
    val stats: UserStats? = null
)

/**
 * Represents a user's exercise statistics.
 */
data class UserStats(
    val totalWorkouts: Int = 0,
    val totalExercises: Int = 0,
    val favoriteExercise: String? = null,
    val totalPoints: Int = 0
)

// Extension function to parse RFC3339 string to Instant
fun String.toInstantSafe(): Instant? {
    return try {
        this.toInstant()
    } catch (e: Exception) {
        null
    }
}

// UpdateLocationRequest is now in User.kt 