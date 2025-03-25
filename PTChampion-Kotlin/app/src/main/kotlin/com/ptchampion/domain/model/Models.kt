package com.ptchampion.domain.model

import java.util.Date

data class User(
    val id: Int,
    val username: String,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val createdAt: Date? = null
)

data class Exercise(
    val id: Int,
    val name: String,
    val description: String? = null,
    val type: ExerciseType
)

enum class ExerciseType {
    PUSHUP,
    PULLUP,
    SITUP,
    RUN
}

data class UserExercise(
    val id: Int,
    val userId: Int,
    val exerciseId: Int,
    val repetitions: Int? = null,
    val formScore: Int? = null,
    val timeInSeconds: Int? = null,
    val grade: Int? = null,
    val completed: Boolean = false,
    val metadata: String? = null, // JSON string for additional data
    val createdAt: Date? = null
)

data class LeaderboardEntry(
    val id: Int,
    val username: String,
    val overallScore: Int
)

// Auth models
data class LoginRequest(
    val username: String,
    val password: String
)

data class RegisterRequest(
    val username: String,
    val password: String,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null
)

// Exercise tracking models
data class PushupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 0,
    val feedback: String = "Position yourself in the frame"
)

data class PullupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 0,
    val feedback: String = "Position yourself in the frame"
)

data class SitupState(
    val isUp: Boolean = false,
    val isDown: Boolean = false,
    val count: Int = 0,
    val formScore: Int = 0,
    val feedback: String = "Position yourself in the frame"
)

data class RunState(
    val distance: Double = 0.0,
    val timeInSeconds: Int = 0,
    val heartRate: Int = 0,
    val speed: Double = 0.0,
    val completed: Boolean = false
)

// Result models
data class ExerciseResult(
    val exerciseId: Int,
    val repetitions: Int? = null,
    val formScore: Int? = null,
    val timeInSeconds: Int? = null,
    val grade: Int? = null,
    val completed: Boolean = true,
    val metadata: String? = null
)