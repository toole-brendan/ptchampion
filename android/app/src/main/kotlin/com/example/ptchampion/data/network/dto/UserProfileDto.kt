package com.example.ptchampion.data.network.dto

import kotlinx.serialization.Serializable

@Serializable
data class UserProfileDto(
    val id: Int,
    val username: String,
    val displayName: String? = null,
    val profilePictureUrl: String? = null,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null
) 