package com.ptchampion.ui.dashboard

import android.location.Location
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.repository.AppRepository
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.LeaderboardEntry
import com.ptchampion.domain.model.User
import com.ptchampion.domain.model.UserExercise
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Dashboard UI state
 */
data class DashboardUiState(
    val isLoading: Boolean = false,
    val user: User? = null,
    val exercises: List<Exercise> = emptyList(),
    val latestExercises: Map<String, UserExercise> = emptyMap(),
    val leaderboard: List<LeaderboardEntry> = emptyList(),
    val error: String? = null
)

/**
 * ViewModel for the dashboard screen
 */
@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(DashboardUiState(isLoading = true))
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()
    
    init {
        loadData()
    }
    
    /**
     * Load initial data
     */
    fun loadData() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        // Load current user
        viewModelScope.launch {
            repository.getCurrentUser()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load user data: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(user = user)
                            loadExercises()
                            loadLatestExercises()
                            loadGlobalLeaderboard()
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load user data: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Load exercises
     */
    private fun loadExercises() {
        viewModelScope.launch {
            repository.getExercises()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load exercises: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { exercises ->
                            _uiState.value = _uiState.value.copy(
                                exercises = exercises,
                                isLoading = false
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load exercises: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Load latest exercises
     */
    private fun loadLatestExercises() {
        viewModelScope.launch {
            repository.getLatestUserExercises()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to load latest exercises: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { latestExercises ->
                            _uiState.value = _uiState.value.copy(
                                latestExercises = latestExercises
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                error = "Failed to load latest exercises: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Load global leaderboard
     */
    private fun loadGlobalLeaderboard() {
        viewModelScope.launch {
            repository.getGlobalLeaderboard()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to load leaderboard: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { leaderboard ->
                            _uiState.value = _uiState.value.copy(
                                leaderboard = leaderboard
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                error = "Failed to load leaderboard: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Load local leaderboard
     */
    fun loadLocalLeaderboard(location: Location) {
        viewModelScope.launch {
            repository.getLocalLeaderboard(location.latitude, location.longitude)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to load local leaderboard: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { leaderboard ->
                            _uiState.value = _uiState.value.copy(
                                leaderboard = leaderboard
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                error = "Failed to load local leaderboard: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Update user location
     */
    fun updateUserLocation(latitude: Double, longitude: Double) {
        viewModelScope.launch {
            repository.updateUserLocation(latitude, longitude)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to update location: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(user = user)
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                error = "Failed to update location: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Clear error
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}