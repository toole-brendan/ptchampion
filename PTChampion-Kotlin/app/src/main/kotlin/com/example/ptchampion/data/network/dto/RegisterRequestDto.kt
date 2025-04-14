package com.example.ptchampion.data.network.dto

import kotlinx.serialization.Serializable

// Based on openapi.yaml 'InsertUser' schema
@Serializable
data class RegisterRequestDto(
    val username: String,
    val password: String,
    val displayName: String? = null, // Make optional fields nullable
    val profilePictureUrl: String? = null,
    val location: String? = null,
    val latitude: String? = null,
    val longitude: String? = null
)
