package com.example.ptchampion.ui.screens.leaderboard

import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.util.Resource
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
// import javax.inject.Inject

// Represents the exercise types for filtering the leaderboard
enum class ExerciseType(val apiName: String, val displayName: String) {
    PUSH_UPS("push-ups", "Push-ups"),
    PULL_UPS("pull-ups", "Pull-ups"),
    SIT_UPS("sit-ups", "Sit-ups")
    // Add other exercise types as needed
}

data class LeaderboardState(
    val leaderboard: List<LeaderboardEntry> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedExerciseType: ExerciseType = ExerciseType.PUSH_UPS // Default type
)

// @HiltViewModel // Remove Hilt annotation
class LeaderboardViewModel /* @Inject */ constructor(
    // private val leaderboardRepository: LeaderboardRepository // Remove repo injection
) : ViewModel() {

    private val _state = mutableStateOf(LeaderboardState())
    val state: State<LeaderboardState> = _state

    init {
        fetchLeaderboard()
    }

    fun selectExerciseType(type: ExerciseType) {
        if (type != _state.value.selectedExerciseType) {
            _state.value = _state.value.copy(selectedExerciseType = type)
            fetchLeaderboard() // Fetch data for the newly selected type
        }
    }

    private fun fetchLeaderboard() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            kotlinx.coroutines.delay(1000) // Simulate loading
             // TODO: Re-enable actual fetching when DI is setup
            /*
            when (val result = leaderboardRepository.getLeaderboard(_state.value.selectedExerciseType.apiName)) {
                is Resource.Success -> {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        leaderboard = result.data ?: emptyList(),
                        error = null
                    )
                }
                is Resource.Error -> {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = result.message ?: "Failed to load leaderboard"
                    )
                }
                is Resource.Loading -> { /* Already handled */ }
            }
            */
             // Simulate success with dummy data
             val dummyData = List(10) { i ->
                 LeaderboardEntry(
                     username = "user${i + 1}", 
                     displayName = "Player ${i + 1}", 
                     score = 100 - i * 5
                 )
             }
             _state.value = _state.value.copy(isLoading = false, leaderboard = dummyData)
        }
    }
} 