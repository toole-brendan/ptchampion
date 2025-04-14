package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class GlobalLeaderboardEntryDto(
    @SerialName("username")
    val username: String,
    @SerialName("display_name")
    val displayName: String? = null, // Schema seems inconsistent with LeaderboardResponse definition, using display_name for safety
    @SerialName("best_grade")
    val bestGrade: Int
    // Note: OpenAPI LeaderboardResponse schema has display_name, but the array item schema inside it doesn't explicitly. Assuming display_name is correct.
) 