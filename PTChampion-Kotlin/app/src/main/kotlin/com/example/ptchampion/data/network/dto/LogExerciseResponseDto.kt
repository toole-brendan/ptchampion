package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Based on openapi.yaml LogExerciseResponse schema
@Serializable
data class LogExerciseResponseDto(
    val id: Int,
    @SerialName("user_id") val userId: Int,
    @SerialName("exercise_id") val exerciseId: Int,
    @SerialName("exercise_name") val exerciseName: String,
    @SerialName("exercise_type") val exerciseType: String,
    val reps: Int? = null,
    @SerialName("time_in_seconds") val timeInSeconds: Int? = null,
    val distance: Int? = null,
    val notes: String? = null,
    val grade: Int,
    @SerialName("created_at") val createdAt: String // Consider using Instant or a custom serializer
)
