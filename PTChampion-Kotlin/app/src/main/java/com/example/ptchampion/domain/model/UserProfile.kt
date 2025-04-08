package com.example.ptchampion.domain.model

/**
 * Represents user profile information relevant to the domain layer.
 */
data class UserProfile(
    val userId: String, // Or Int depending on your backend
    val email: String,
    val name: String?, // Optional name
    // Add other relevant fields like profile picture URL, join date, etc.
    // val profilePictureUrl: String? = null,
    // val joinDate: Instant? = null
) 