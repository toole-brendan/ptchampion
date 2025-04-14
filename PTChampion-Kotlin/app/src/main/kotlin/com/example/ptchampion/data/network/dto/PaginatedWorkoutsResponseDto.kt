package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PaginatedWorkoutsResponseDto(
    @SerialName("workouts")
    val workouts: List<WorkoutResponseDto>,
    @SerialName("totalCount")
    val totalCount: Long, // Use Long as per schema format: int64
    @SerialName("page")
    val page: Int,
    @SerialName("pageSize")
    val pageSize: Int,
    @SerialName("totalPages")
    val totalPages: Int
) 