package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Based on openapi.yaml LogExerciseRequest schema
@Serializable
data class LogExerciseRequestDto(
    @SerialName("exercise_id") val exerciseId: Int,
    val reps: Int? = null,
    val duration: Int? = null, // Assuming this maps to time_in_seconds or similar
    val distance: Int? = null,
    val notes: String? = null,
    @SerialName("form_score") val formScore: Int? = null,
    val completed: Boolean? = null,
    @SerialName("device_id") val deviceId: String? = null
)
