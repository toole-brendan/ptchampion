package com.example.ptchampion.domain.model

// Simple data class for leaderboard entries used in the domain/UI layers
data class LeaderboardEntry(
    val username: String,
    val displayName: String,
    val score: Int
) 