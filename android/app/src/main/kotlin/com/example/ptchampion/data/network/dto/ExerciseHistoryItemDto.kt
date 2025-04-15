package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ExerciseHistoryItemDto(
    @SerialName("id")
    val id: Int,
    @SerialName("user_id")
    val userId: Int,
    @SerialName("exercise_id")
    val exerciseId: Int,
    @SerialName("exercise_name")
    val exerciseName: String,
    @SerialName("exercise_type")
    val exerciseType: String,
    @SerialName("reps")
    val reps: Int? = null,
    @SerialName("time_in_seconds")
    val timeInSeconds: Int? = null,
    @SerialName("distance")
    val distance: Int? = null,
    @SerialName("notes")
    val notes: String? = null,
    @SerialName("grade")
    val grade: Int,
    @SerialName("created_at")
    val createdAt: String // Consider parsing this to a date/time type later
) 