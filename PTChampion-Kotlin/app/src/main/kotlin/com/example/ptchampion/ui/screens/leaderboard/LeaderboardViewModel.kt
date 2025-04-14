package com.example.ptchampion.ui.screens.leaderboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay // For simulating loading

// Enum to define the type of leaderboard
enum class LeaderboardType { LOCAL, GLOBAL }

// Data class for a single leaderboard entry
data class LeaderboardEntry(
    val rank: Int,
    val userId: String, // To identify the current user
    val competitorName: String,
    val score: Int? = null, // Score for rep-based exercises
    val timeMillis: Long? = null // Time for running exercises
)

// Data class for the UI state
data class LeaderboardUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val selectedExerciseType: String = "pushups", // Default to pushups
    val availableExerciseTypes: List<String> = listOf("pushups", "pullups", "situps", "running"),
    val selectedLeaderboardType: LeaderboardType = LeaderboardType.LOCAL, // Default to local
    val leaderboardEntries: List<LeaderboardEntry> = emptyList(),
    val currentUserId: String = "currentUser123" // Mock current user ID
)

class LeaderboardViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(LeaderboardUiState())
    val uiState: StateFlow<LeaderboardUiState> = _uiState.asStateFlow()

    init {
        // Load initial data (default: local pushups)
        fetchLeaderboardData()
    }

    fun selectExerciseType(type: String) {
        if (type != _uiState.value.selectedExerciseType) {
            _uiState.update { it.copy(selectedExerciseType = type) }
            fetchLeaderboardData()
        }
    }

    fun selectLeaderboardType(type: LeaderboardType) {
        if (type != _uiState.value.selectedLeaderboardType) {
            _uiState.update { it.copy(selectedLeaderboardType = type) }
            fetchLeaderboardData()
        }
    }

    private fun fetchLeaderboardData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, leaderboardEntries = emptyList()) }
            try {
                // Simulate network delay
                delay(1000)

                // TODO: Replace with actual API call based on
                // _uiState.value.selectedLeaderboardType and _uiState.value.selectedExerciseType
                val mockEntries = generateMockData(
                    _uiState.value.selectedLeaderboardType,
                    _uiState.value.selectedExerciseType,
                    _uiState.value.currentUserId
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        leaderboardEntries = mockEntries
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "Failed to load leaderboard: ${e.message}"
                    )
                }
            }
        }
    }

    // Mock data generation function
    private fun generateMockData(boardType: LeaderboardType, exercise: String, currentUserId: String): List<LeaderboardEntry> {
        val isRunning = exercise == "running"
        val prefix = if (boardType == LeaderboardType.LOCAL) "Nearby" else "Global"
        
        // Ensure current user is included (somewhere in the middle for testing)
        val currentUserEntry = if (isRunning) {
            LeaderboardEntry(rank = 4, userId = currentUserId, competitorName = "You", timeMillis = (10 * 60 + 45) * 1000L) // 10:45
        } else {
            LeaderboardEntry(rank = 4, userId = currentUserId, competitorName = "You", score = 70)
        }

        val entries = listOf(
            if (isRunning) LeaderboardEntry(1, "user1", "$prefix Runner 1", timeMillis = (9 * 60 + 30) * 1000L) // 9:30
            else LeaderboardEntry(1, "user1", "$prefix Player 1", score = 95),
            
            if (isRunning) LeaderboardEntry(2, "user2", "$prefix Runner 2", timeMillis = (10 * 60 + 15) * 1000L) // 10:15
            else LeaderboardEntry(2, "user2", "$prefix Player 2", score = 85),
            
            if (isRunning) LeaderboardEntry(3, "user3", "$prefix Runner 3", timeMillis = (10 * 60 + 30) * 1000L) // 10:30
            else LeaderboardEntry(3, "user3", "$prefix Player 3", score = 75),
            
            currentUserEntry, // Add current user
            
            if (isRunning) LeaderboardEntry(5, "user5", "$prefix Runner 5", timeMillis = (11 * 60 + 0) * 1000L) // 11:00
            else LeaderboardEntry(5, "user5", "$prefix Player 5", score = 65)
        )

        // Sort differently based on exercise type
        return if (isRunning) {
            // For running, sort by time ascending (shortest time first)
            entries.sortedBy { it.timeMillis ?: Long.MAX_VALUE }
                    .mapIndexed { index, entry -> entry.copy(rank = index + 1) }
        } else {
            // For strength exercises, sort by score descending (highest score first)
            entries.sortedByDescending { it.score ?: 0 }
                    .mapIndexed { index, entry -> entry.copy(rank = index + 1) }
        }
    }

} 