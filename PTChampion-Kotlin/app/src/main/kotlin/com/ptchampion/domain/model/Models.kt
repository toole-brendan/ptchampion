package com.ptchampion.domain.model

/**
 * User model
 */
data class User(
    val id: Int,
    val username: String,
    val password: String,
    val displayName: String? = null,
    val profilePictureUrl: String? = null,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val deviceId: String? = null,
    val lastSyncedAt: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null
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
    val formScore: Int? = null, // Renamed from score for consistency
    val timeInSeconds: Int? = null,
    val distance: Double? = null,
    val grade: Int, // This will store the calculated score
    val completed: Boolean = true,
    val metadata: Map<String, String>? = null,
    val deviceId: String? = null,
    val syncStatus: String? = null,
    val createdAt: String, // Renamed from date for consistency
    val updatedAt: String? = null
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
 * Sync request model for sending data to the server
 */
data class SyncRequest(
    val userId: Int,
    val deviceId: String,
    val lastSyncTimestamp: String,
    val data: SyncRequestData? = null
)

/**
 * Data container for sync request
 */
data class SyncRequestData(
    val userExercises: List<UserExercise>? = null,
    val profile: User? = null
)

/**
 * Sync response model received from the server
 */
data class SyncResponse(
    val success: Boolean,
    val timestamp: String,
    val data: SyncResponseData? = null,
    val conflicts: List<UserExercise>? = null
)

/**
 * Data container for sync response
 */
data class SyncResponseData(
    val userExercises: List<UserExercise>? = null,
    val profile: User? = null
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