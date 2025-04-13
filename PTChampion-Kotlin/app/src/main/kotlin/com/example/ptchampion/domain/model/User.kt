package com.example.ptchampion.domain.model

/**
 * Represents a user in the application.
 * This is a domain model that is distinct from the API model.
 */
data class User(
    val id: Int,
    val username: String,
    val displayName: String? = null,
    val email: String? = null,
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