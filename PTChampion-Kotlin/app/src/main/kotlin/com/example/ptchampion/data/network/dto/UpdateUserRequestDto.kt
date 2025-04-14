package com.example.ptchampion.data.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Based on openapi.yaml UpdateUserRequest schema
@Serializable
data class UpdateUserRequestDto(
    // Use @SerialName if Kotlin property name differs from JSON key (e.g., display_name)
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("profile_picture_url") val profilePictureUrl: String? = null,
    val location: String? = null,
    val latitude: Double? = null, // Schema uses number type
    val longitude: Double? = null // Schema uses number type
    // Note: The 'username' field is in the schema but likely shouldn't be updatable via this request.
    // Only include fields that the user should be able to modify in their profile.
)
