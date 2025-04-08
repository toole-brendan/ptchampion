package com.example.ptchampion.ui.screens.leaderboard

import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

// Define supported exercise types for the UI
// Could be expanded into a data class/sealed class with more info if needed
enum class ExerciseType(val apiValue: String, val displayName: String) {
    PUSHUP("pushup", "Push-ups"),
    PULLUP("pullup", "Pull-ups"),
    SITUP("situp", "Sit-ups"),
    RUN("run", "Run") // Assuming 'run' is the API value
}

data class LeaderboardState(
    val isLoading: Boolean = false,
    val leaderboard: List<LeaderboardEntry> = emptyList(),
    val selectedExerciseType: ExerciseType = ExerciseType.PUSHUP, // Default to pushups
    val error: String? = null
)

@HiltViewModel
class LeaderboardViewModel @Inject constructor(
    private val leaderboardRepository: LeaderboardRepository
) : ViewModel() {

    private val _state = mutableStateOf(LeaderboardState())
    val state: State<LeaderboardState> = _state

    init {
        loadLeaderboard(ExerciseType.PUSHUP) // Load default leaderboard on init
    }

    fun selectExerciseType(type: ExerciseType) {
        if (type != _state.value.selectedExerciseType || _state.value.error != null) {
            loadLeaderboard(type)
        }
    }

    private fun loadLeaderboard(type: ExerciseType) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null, selectedExerciseType = type)
            when (val result = leaderboardRepository.getLeaderboard(type.apiValue)) {
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
                        leaderboard = emptyList(), // Clear previous data on error
                        error = result.message ?: "An unknown error occurred"
                    )
                }
            }
        }
    }
} 