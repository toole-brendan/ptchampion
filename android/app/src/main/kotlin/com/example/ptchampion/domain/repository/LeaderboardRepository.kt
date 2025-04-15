package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.domain.util.Resource

interface LeaderboardRepository {
    // Define exercise types - could be an enum or sealed class later
    // For now, just use strings matching the API enum values
    suspend fun getGlobalLeaderboard(exerciseType: String, limit: Int = 20): Resource<List<LeaderboardEntry>>

    suspend fun getLocalLeaderboard(
        exerciseId: Int,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double? = null, // Use default from API spec later if needed
        limit: Int = 20 // Added limit, though API doesn't explicitly mention it here
    ): Resource<List<LeaderboardEntry>>
} 