package com.example.ptchampion.data.network.mapper

import com.example.ptchampion.data.network.dto.GlobalLeaderboardEntryDto
import com.example.ptchampion.data.network.dto.LocalLeaderboardEntryDto
import com.example.ptchampion.domain.model.LeaderboardEntry

/**
 * Maps GlobalLeaderboardEntryDto (Network) to LeaderboardEntry (Domain)
 */
fun GlobalLeaderboardEntryDto.toLeaderboardEntry(rank: Int): LeaderboardEntry {
    return LeaderboardEntry(
        rank = rank,
        username = this.username,
        displayName = this.displayName ?: this.username, // Use username if displayName is null
        score = this.bestGrade,
        userId = null // Global leaderboard API doesn't provide userId
    )
}

/**
 * Maps LocalLeaderboardEntryDto (Network) to LeaderboardEntry (Domain)
 */
fun LocalLeaderboardEntryDto.toLeaderboardEntry(rank: Int): LeaderboardEntry {
    return LeaderboardEntry(
        rank = rank,
        username = this.username,
        displayName = this.displayName ?: this.username, // Use username if displayName is null
        score = this.score,
        userId = this.userId // Local leaderboard API provides userId
    )
} 