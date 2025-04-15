package com.example.ptchampion.data.network.dto

import kotlinx.serialization.Serializable

// Map fields from openapi.yaml 'User' schema
@Serializable
data class UserDto(
    val id: Int,
    val username: String,
    val displayName: String?, // Corresponds to displayName in schema
    val profilePictureUrl: String?, // Corresponds to profilePictureUrl
    val location: String?,
    val latitude: String?,
    val longitude: String?,
    val lastSyncedAt: String?, // Note: Timestamps might need custom serializers
    val createdAt: String?,     // if not standard ISO format
    val updatedAt: String?
    // Add other fields as required by the app's domain models
)
