package com.example.ptchampion.domain.model

import java.time.Instant

/**
 * Domain model representing a recorded workout session
 */
data class WorkoutSession(
    val id: Int,
    val userId: Int,
    val exerciseId: Int,
    val exerciseName: String,
    val repetitions: Int?,
    val durationSeconds: Int?,
    val formScore: Int?,
    val grade: Int,
    val createdAt: String, // Representing ISO 8601 String
    val completedAt: String // Representing ISO 8601 String
)

/**
 * DTO model for sending workout data to the backend API
 */
data class SaveWorkoutRequest(
    val exercise_id: Int,
    val repetitions: Int?,
    val duration_seconds: Int?,
    val completed_at: String // ISO-8601 formatted timestamp
)

/**
 * DTO model representing the response from the workout API
 */
@kotlinx.serialization.Serializable // Add for JSON serialization
data class WorkoutResponse(
    val id: Int,
    // val user_id: Int, // Usually not needed in client response, user ID is implicit
    val exerciseId: Int, // Match API response field name if needed (exerciseId vs exercise_id)
    val exerciseName: String, // Add exerciseName based on Go response
    val repetitions: Int? = null, // Nullable, provide default
    val durationSeconds: Int? = null, // Nullable, provide default
    val formScore: Int? = null, // Add formScore, nullable
    val grade: Int,
    val completedAt: String, // Keep as String for ISO 8601
    val createdAt: String // Keep as String for ISO 8601
    // Removed exercise_type as it's not in the final Go response struct
)

/**
 * DTO model representing the paginated response for workout history
 */
@kotlinx.serialization.Serializable // Add for JSON serialization
data class PaginatedWorkoutResponse(
    val workouts: List<WorkoutResponse>,
    val totalCount: Long,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int
)

// REMOVED LocalLeaderboardEntry from here
// /**
//  * DTO model representing a single entry in the local leaderboard response.
//  */
// @kotlinx.serialization.Serializable
// data class LocalLeaderboardEntry(
//     val userId: Int,
//     val username: String,
//     val displayName: String? = null, // Matches nullable field in API
//     val exerciseId: Int,
//     val score: Int
// ) 