package com.example.ptchampion.ui.screens.leaderboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.domain.repository.ExerciseRepository // Remove unused import
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.LocalLeaderboardEntry
// import com.example.ptchampion.domain.repository.LeaderboardRepository // Remove unused import
// import com.example.ptchampion.domain.repository.UserPreferencesRepository // Remove unused import
// import com.example.ptchampion.util.LocationService // Remove unused import
// import com.example.ptchampion.util.Resource // Remove unused import
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
// import javax.inject.Inject

data class LocalLeaderboardUiState(
    val exercises: List<ExerciseResponse> = emptyList(),
    val selectedExerciseId: Int = -1, // -1 indicates no selection
    val isExerciseDropdownExpanded: Boolean = false,
    val leaderboardEntries: List<LocalLeaderboardEntry> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val hasLocationPermission: Boolean = false
)

// @HiltViewModel // Remove Hilt annotation
class LocalLeaderboardViewModel /* @Inject */ constructor(
    // private val exerciseRepository: ExerciseRepository, // Remove repo injection
    // private val leaderboardRepository: LeaderboardRepository, // Remove repo injection
    // private val locationService: LocationService, // Remove service injection
    // private val userPreferencesRepository: UserPreferencesRepository // Remove repo injection
    private val exerciseId: Int? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(LocalLeaderboardUiState())
    val uiState: StateFlow<LocalLeaderboardUiState> = _uiState.asStateFlow()

    init {
        loadExercises()
        // If exerciseId was provided in constructor, select it
        exerciseId?.let { id ->
            _uiState.update { it.copy(selectedExerciseId = id) }
        }
        // Don't load leaderboard initially, wait for permission check/location
    }

    private fun loadExercises() {
        viewModelScope.launch {
             // Simulate loading exercises
             val dummyExercises = listOf(
                 ExerciseResponse(id = 1, name = "Push-ups", type = "PUSH_UPS", description = ""),
                 ExerciseResponse(id = 2, name = "Pull-ups", type = "PULL_UPS", description = ""),
                 ExerciseResponse(id = 3, name = "Sit-ups", type = "SIT_UPS", description = "")
             )
             _uiState.update { it.copy(exercises = dummyExercises) }
             // Select the first exercise by default if list is not empty
             if (dummyExercises.isNotEmpty()) {
                 selectExercise(dummyExercises.first().id)
             }
             // TODO: Re-enable actual fetching when DI is setup
            /*
            when (val result = exerciseRepository.getExercises()) {
                is Resource.Success -> {
                    val exercises = result.data ?: emptyList()
                    _uiState.update { it.copy(exercises = exercises) }
                    // Select the first exercise by default if list is not empty
                    if (exercises.isNotEmpty() && _uiState.value.selectedExerciseId == -1) {
                         selectExercise(exercises.first().id)
                    }
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(error = "Failed to load exercises: ${result.message}") }
                }
                is Resource.Loading -> {}
            }
            */
        }
    }

    fun selectExercise(exerciseId: Int) {
        if (exerciseId != _uiState.value.selectedExerciseId) {
             _uiState.update { it.copy(selectedExerciseId = exerciseId, isExerciseDropdownExpanded = false) }
             // Fetch leaderboard for the new exercise IF location is available and permission granted
             if (_uiState.value.hasLocationPermission) {
                 fetchLocationAndLoadLeaderboard() // Reuse the combined fetch logic
             }
        }
    }

    fun toggleExerciseDropdown(expanded: Boolean) {
        _uiState.update { it.copy(isExerciseDropdownExpanded = expanded) }
    }

    fun onPermissionResult(results: Map<String, Boolean>) {
        val granted = results.values.all { it } // Check if ALL requested permissions are granted
        _uiState.update { it.copy(hasLocationPermission = granted) }
        if (!granted) {
            _uiState.update { it.copy(error = "Location permission denied.", isLoading = false) }
        }
        // Fetching is triggered by LaunchedEffect in the screen if granted
    }

    fun fetchLocationAndLoadLeaderboard() {
        if (!_uiState.value.hasLocationPermission) {
            _uiState.update { it.copy(error = "Location permission required.") }
            return
        }
        if (_uiState.value.selectedExerciseId == -1) {
            _uiState.update { it.copy(error = "Please select an exercise.") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            kotlinx.coroutines.delay(1500) // Simulate location fetch + leaderboard fetch
            // TODO: Re-enable actual location fetching and leaderboard loading
            /*
            try {
                val location = locationService.getLastKnownLocation()
                if (location != null) {
                    val token = userPreferencesRepository.authToken.firstOrNull()
                    if (token == null) {
                        _uiState.update { it.copy(isLoading = false, error = "Not logged in") }
                        return@launch
                    }

                    // Update user's location first (fire-and-forget or handle response)
                    // TODO: Consider if we need to wait for this update to finish
                     try {
                         leaderboardRepository.updateUserLocation(
                            UpdateLocationRequest(latitude = location.latitude, longitude = location.longitude)
                         )
                         Log.d("LocalLeaderboardVM", "Location updated successfully")
                     } catch (e: Exception) {
                         Log.e("LocalLeaderboardVM", "Failed to update location", e)
                         // Decide if this is a critical error for leaderboard fetching
                     }

                    // Now fetch the leaderboard
                    when (val result = leaderboardRepository.getLocalLeaderboard(
                        exerciseId = _uiState.value.selectedExerciseId,
                        latitude = location.latitude,
                        longitude = location.longitude
                    )) {
                        is Resource.Success -> {
                            _uiState.update {
                                it.copy(
                                    isLoading = false,
                                    leaderboardEntries = result.data ?: emptyList(),
                                    error = null
                                )
                            }
                        }
                        is Resource.Error -> {
                            _uiState.update {
                                it.copy(
                                    isLoading = false,
                                    leaderboardEntries = emptyList(), // Clear old data on error
                                    error = result.message ?: "Failed to load local leaderboard"
                                )
                            }
                        }
                         is Resource.Loading -> { /* Already handled by isLoading=true */ }
                    }
                } else {
                    _uiState.update { it.copy(isLoading = false, error = "Failed to get current location.") }
                }
            } catch (e: SecurityException) {
                 _uiState.update { it.copy(isLoading = false, error = "Location permission error.") }
                 Log.e("LocalLeaderboardVM", "Location permission error", e)
            } catch (e: Exception) {
                 _uiState.update { it.copy(isLoading = false, error = "An unexpected error occurred.") }
                Log.e("LocalLeaderboardVM", "Error fetching location or leaderboard", e)
            }
            */
             // Simulate success with dummy data
              // Use a hardcoded list instead
              val dummyLeaderboard = listOf(
                  LocalLeaderboardEntry(userId = 100, username = "local_user_1", displayName = "Nearby Player 1", exerciseId = _uiState.value.selectedExerciseId, score = 95),
                  LocalLeaderboardEntry(userId = 101, username = "local_user_2", displayName = "Nearby Player 2", exerciseId = _uiState.value.selectedExerciseId, score = 85),
                  LocalLeaderboardEntry(userId = 102, username = "local_user_3", displayName = "Nearby Player 3", exerciseId = _uiState.value.selectedExerciseId, score = 75),
                  LocalLeaderboardEntry(userId = 103, username = "local_user_4", displayName = "Nearby Player 4", exerciseId = _uiState.value.selectedExerciseId, score = 65),
                  LocalLeaderboardEntry(userId = 104, username = "local_user_5", displayName = "Nearby Player 5", exerciseId = _uiState.value.selectedExerciseId, score = 55)
              )
              _uiState.update { it.copy(isLoading = false, leaderboardEntries = dummyLeaderboard) }
        }
    }
}

/**
 * Factory for creating a [LocalLeaderboardViewModel] with a specific exerciseId
 */
class LocalLeaderboardViewModelFactory(private val exerciseId: Int? = null) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(LocalLeaderboardViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return LocalLeaderboardViewModel(exerciseId) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}