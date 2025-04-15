package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class LocalLeaderboardEntryDto(
    @SerialName("userId")
    val userId: Int,
    @SerialName("username")
    val username: String,
    @SerialName("displayName")
    val displayName: String? = null,
    @SerialName("exerciseId")
    val exerciseId: Int,
    @SerialName("score")
    val score: Int
) 