package com.ptchampion.domain.model

/**
 * User model
 */
data class User(
    val id: Int,
    val username: String,
    val password: String,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val createdAt: String? = null
)

/**
 * Exercise model
 */
data class Exercise(
    val id: Int,
    val name: String, 
    val description: String,
    val type: String,
    val imageUrl: String,
    val videoUrl: String? = null,
    val instructions: String? = null
)

/**
 * User Exercise model
 */
data class UserExercise(
    val id: Int,
    val userId: Int,
    val exerciseId: Int,
    val type: String,
    val reps: Int? = null,
    val timeInSeconds: Int? = null,
    val distance: Double? = null,
    val score: Int,
    val date: String
)

/**
 * LeaderboardEntry
 */
data class LeaderboardEntry(
    val userId: Int,
    val username: String,
    val totalScore: Int,
    val distance: Double? = null
)

/**
 * State for pushup tracking
 */
data class PushupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 100,
    val feedback: String = "Get in position to start"
)

/**
 * State for pullup tracking
 */
data class PullupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 100,
    val feedback: String = "Get in position to start"
)

/**
 * State for situp tracking
 */
data class SitupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 100,
    val feedback: String = "Get in position to start"
)

/**
 * Result wrapper
 */
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    
    fun fold(
        onSuccess: (T) -> Any,
        onFailure: (Throwable) -> Any
    ): Any {
        return when (this) {
            is Success -> onSuccess(data)
            is Error -> onFailure(exception)
        }
    }
}