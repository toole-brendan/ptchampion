package com.example.ptchampion.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.domain.repository.UserRepository // Remove unused import
// import com.example.ptchampion.domain.util.Resource // Remove unused import
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
// import javax.inject.Inject

data class RecentWorkout(
    val type: String,
    val date: String,
    val reps: Int,
    val score: Int,
    val durationMinutes: Int,
    val durationSeconds: Int
)

data class UserRank(
    val exerciseType: String,
    val globalRank: Int,
    val localRank: Int
)

data class HomeUiState(
    val isLoading: Boolean = false,
    val userName: String? = null,
    val error: String? = null,
    val recentWorkout: RecentWorkout? = null,
    val userRank: UserRank? = null,
    val isBluetoothConnected: Boolean = false
)

class HomeViewModel constructor(
    // private val userRepository: UserRepository // Remove repo injection
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadMockData() // For prototype, load mock data instead of real data
    }

    private fun loadMockData() {
        viewModelScope.launch {
            _uiState.update { currentState ->
                currentState.copy(
                    isLoading = false,
                    userName = "Temp User",
                    recentWorkout = RecentWorkout(
                        type = "Push-ups",
                        date = "April 13, 2025",
                        reps = 24,
                        score = 92,
                        durationMinutes = 1,
                        durationSeconds = 30
                    ),
                    userRank = UserRank(
                        exerciseType = "Push-ups",
                        globalRank = 253,
                        localRank = 12
                    ),
                    isBluetoothConnected = true,
                    error = null
                )
            }
        }
    }
    
    // When repository and DI is set up, uncomment and implement real data methods
    
    /*
    private fun observeUserProfile() {
        userRepository.getUserProfileFlow()
            .onEach { resource ->
                val currentState = _uiState.value
                when (resource) {
                    is Resource.Loading -> {
                        _uiState.value = currentState.copy(isLoading = true, error = null)
                    }
                    is Resource.Success -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            userName = resource.data?.name ?: "User", // Default name if null
                            error = null
                        )
                    }
                    is Resource.Error -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            error = resource.message ?: "Failed to load profile"
                            // Keep previous user name on error? Optional.
                        )
                    }
                }
            }
            .launchIn(viewModelScope)
    }
    
    private fun loadUserRanks() {
        viewModelScope.launch {
            // Implement call to leaderboard repository to get user ranks
        }
    }
    
    private fun loadRecentWorkout() {
        viewModelScope.launch {
            // Implement call to workout history repository to get recent workout
        }
    }
    
    private fun observeBluetoothConnections() {
        viewModelScope.launch {
            // Implement call to bluetooth service to observe connections
        }
    }
    */
} 