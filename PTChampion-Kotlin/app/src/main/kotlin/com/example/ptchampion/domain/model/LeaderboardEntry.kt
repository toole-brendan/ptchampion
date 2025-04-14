package com.example.ptchampion.domain.model

/**
 * Represents a single entry displayed in the leaderboard UI.
 */
data class LeaderboardEntry(
    val rank: Int, // Added rank for display
    val username: String,
    val displayName: String?, // Make nullable to match DTOs
    val score: Int,
    val userId: Int? = null // Add optional userId for comparison
) 