package com.example.ptchampion.domain.model

/**
 * Represents user data within the application domain.
 */
data class User(
    val id: Int,
    val username: String,
    val displayName: String?,
    val email: String?, // Assuming email is part of user data needed by UI
    val profilePictureUrl: String?,
    val createdAt: String? = null,
    val updatedAt: String? = null,
    val location: UserLocation? = null
)

/**
 * Represents a user's location.
 */
data class UserLocation(
    val latitude: Double,
    val longitude: Double
)

/**
 * Model for requesting location updates.
 */
data class UpdateLocationRequest(
    val latitude: Double,
    val longitude: Double
) 