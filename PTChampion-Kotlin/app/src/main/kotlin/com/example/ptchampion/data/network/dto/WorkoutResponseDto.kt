package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WorkoutResponseDto(
    @SerialName("id")
    val id: Int,
    @SerialName("userId")
    val userId: Int,
    @SerialName("exerciseId")
    val exerciseId: Int,
    @SerialName("exerciseName")
    val exerciseName: String,
    @SerialName("repetitions")
    val repetitions: Int? = null,
    @SerialName("durationSeconds")
    val durationSeconds: Int? = null,
    @SerialName("formScore")
    val formScore: Int? = null,
    @SerialName("grade")
    val grade: Int,
    @SerialName("createdAt")
    val createdAt: String, // Consider parsing later
    @SerialName("completedAt")
    val completedAt: String // Consider parsing later
) 