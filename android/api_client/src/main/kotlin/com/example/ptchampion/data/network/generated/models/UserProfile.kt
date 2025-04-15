package com.example.ptchampion.data.network.generated.models

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class UserProfile(
    val id: Int,
    val username: String,
    val displayName: String? = null,
    val profilePictureUrl: String? = null,
    val location: String? = null,
    val latitude: String? = null,
    val longitude: String? = null
) 