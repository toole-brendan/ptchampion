package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PaginatedExerciseHistoryResponseDto(
    @SerialName("items")
    val items: List<ExerciseHistoryItemDto>,
    @SerialName("total_count")
    val totalCount: Int,
    @SerialName("page")
    val page: Int,
    @SerialName("page_size")
    val pageSize: Int
) 