package com.example.ptchampion.ui.screens.leaderboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.domain.model.LocationData
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.service.LocationService
import com.example.ptchampion.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

// Enum to define the scope of leaderboard
enum class LeaderboardScope { LOCAL, GLOBAL }

// Data class for the UI state
data class LeaderboardUiState(
    val isLoading: Boolean = true,
    val isLoadingLocation: Boolean = false, // Add state for location loading
    val error: String? = null,
    val selectedExerciseType: String = "pushup", // Default exercise type key
    // TODO: Populate this dynamically from API if possible
    val availableExerciseTypes: List<String> = listOf("pushup", "pullup", "situp", "run"),
    val selectedScope: LeaderboardScope = LeaderboardScope.GLOBAL, // Default to global
    val leaderboardEntries: List<LeaderboardEntry> = emptyList(),
    val currentUserId: Int? = null // Change to store userId (Int)
    // Removed currentUsername, highlighting can be done differently if needed
)

// TODO: Fetch this mapping dynamically or store it reliably
private val exerciseIdMap = mapOf(
    "pushup" to 1,
    "pullup" to 2,
    "situp" to 3,
    "run" to 4
)

@HiltViewModel
class LeaderboardViewModel @Inject constructor(
    private val leaderboardRepository: LeaderboardRepository,
    private val locationService: LocationService,
    private val workoutRepository: WorkoutRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LeaderboardUiState())
    val uiState: StateFlow<LeaderboardUiState> = _uiState.asStateFlow()

    init {
        fetchCurrentUser() // Fetch user info first
        fetchExerciseList()
    }

    private fun fetchCurrentUser() {
        viewModelScope.launch {
            // Assuming userRepository exposes the current user's ID
            // Example: userRepository.getCurrentUserFlow().first()?.id
            // This depends heavily on UserRepository implementation
            val userId = userRepository.getCurrentUserFlow().first()?.id // Example access
            _uiState.update { it.copy(currentUserId = userId) }
        }
    }

    fun selectExerciseType(type: String) {
        if (type != _uiState.value.selectedExerciseType && exerciseIdMap.containsKey(type)) {
            _uiState.update { it.copy(selectedExerciseType = type) }
            fetchLeaderboard()
        }
    }

    fun selectScope(scope: LeaderboardScope) {
        if (scope != _uiState.value.selectedScope) {
            _uiState.update { it.copy(selectedScope = scope) }
            fetchLeaderboard()
        }
    }

    private fun fetchExerciseList() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) } // Use general loading state
            when (val result = workoutRepository.getExercises()) {
                is Resource.Success -> {
                    val exercises = result.data ?: emptyList()
                    if (exercises.isNotEmpty()) {
                        // Use `type` for the key (e.g., "pushup") and `name` for display
                        val exerciseMap = exercises.associate { it.type to it.id }
                        // The dropdown should probably show the proper name, not the type key
                        val exerciseDisplayNames = exercises.map { it.name }
                        // The internal state should track the *type key* for API calls
                        val exerciseTypeKeys = exercises.map { it.type }

                        _uiState.update {
                            it.copy(
                                // isLoading = false, // Keep loading true until leaderboard is fetched
                                availableExerciseTypes = exerciseDisplayNames, // Show proper names in dropdown
                                // Use type key for selection state
                                selectedExerciseType = if (it.selectedExerciseType in exerciseMap) it.selectedExerciseType else exerciseTypeKeys.firstOrNull() ?: "pushup"
                            )
                        }
                        fetchLeaderboard(exerciseMap)
                    } else {
                        _uiState.update { it.copy(isLoading = false, error = "No exercises found from server.") }
                    }
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = "Failed to load exercise list: ${result.message}") }
                }
                is Resource.Loading -> { /* Already loading */ }
            }
        }
    }

    // Modify fetchLeaderboard to accept the map
    private fun fetchLeaderboard(exerciseMap: Map<String, Int> = emptyMap()) {
        viewModelScope.launch {
            // Only set loading if exercises were loaded successfully
            if (_uiState.value.error == null) {
                 _uiState.update { it.copy(isLoading = true, isLoadingLocation = false, error = null) }
            }

            val currentScope = _uiState.value.selectedScope
            val currentExerciseType = _uiState.value.selectedExerciseType
            // Get exercise ID from the passed map or the global one (fallback)
            val exerciseId = exerciseMap[currentExerciseType] ?: exerciseIdMap[currentExerciseType]

            val result: Resource<List<LeaderboardEntry>> = when (currentScope) {
                LeaderboardScope.GLOBAL -> {
                    leaderboardRepository.getGlobalLeaderboard(currentExerciseType)
                }
                LeaderboardScope.LOCAL -> {
                    _uiState.update { it.copy(isLoadingLocation = true) }
                    val locationResult = locationService.getCurrentLocation().first()
                    _uiState.update { it.copy(isLoadingLocation = false) }

                    when (locationResult) {
                        is Resource.Success -> {
                            val locationData = locationResult.data!!
                            if (exerciseId != null) {
                                // ... call getLocalLeaderboard ...
                                leaderboardRepository.getLocalLeaderboard(
                                    exerciseId = exerciseId,
                                    latitude = locationData.latitude,
                                    longitude = locationData.longitude
                                )
                            } else {
                                Resource.Error("Invalid exercise type for local leaderboard.")
                            }
                        }
                        // ... Error/Loading handling for location ...
                        is Resource.Error -> { Resource.Error(locationResult.message ?: "Failed to get location.") }
                        is Resource.Loading -> { Resource.Error("Still loading location unexpectedly.") }
                    }
                }
            }

            // Update state based on leaderboard result
            when (result) {
                is Resource.Success -> {
                    _uiState.update { it.copy(isLoading = false, leaderboardEntries = result.data ?: emptyList(), error = null) }
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(isLoading = false, leaderboardEntries = emptyList(), error = result.message ?: "Unknown error") }
                }
                 is Resource.Loading -> { /* Handled */ }
            }
        }
    }
    // Removed generateMockData and old LeaderboardEntry definition
} 