package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.util.Resource

interface LeaderboardRepository {
    // Define exercise types - could be an enum or sealed class later
    // For now, just use strings matching the API enum values
    suspend fun getLeaderboard(exerciseType: String, limit: Int = 20): Resource<List<LeaderboardEntry>>
} 