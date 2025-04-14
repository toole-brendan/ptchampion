package com.example.ptchampion.ui.screens.exerciselist

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.domain.repository.ExerciseRepository // Remove unused import
// import com.example.ptchampion.util.Resource // Remove unused import
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
// import javax.inject.Inject

// Model for the UI list - Use the backend response structure directly or map it
// Using ExerciseResponse directly for simplicity now
// data class ExerciseListItem(
//     val id: Int,
//     val apiType: String, // e.g., "pushup"
//     val name: String, // e.g., "Push-ups"
//     val description: String?
// )

// Data class to hold exercise information including Personal Best (PB)
data class ExerciseInfo(
    val id: Int, // Assuming some ID from backend/local db
    val type: String, // Type identifier (e.g., "pushups")
    val name: String,
    val icon: ImageVector,
    val personalBest: String? // String to represent PB (e.g., "35 Reps", "10:30")
)

data class ExerciseListUiState(
    val isLoading: Boolean = true,
    val exercises: List<ExerciseInfo> = emptyList(),
    val error: String? = null
)

// @HiltViewModel // Remove Hilt annotation
class ExerciseListViewModel /* @Inject */ constructor(
    // private val exerciseRepository: ExerciseRepository // Remove repo injection
) : ViewModel() {

    private val _uiState = MutableStateFlow(ExerciseListUiState())
    val uiState: StateFlow<ExerciseListUiState> = _uiState.asStateFlow()

    init {
        loadExercisesWithPBs()
    }

    private fun loadExercisesWithPBs() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // TODO: Replace with actual data fetching (API call or local DB query)
                val mockExercises = listOf(
                    ExerciseInfo(
                        id = 1,
                        type = "pushups",
                        name = "Push-ups",
                        icon = Icons.Default.FitnessCenter,
                        personalBest = "PB: 35 Reps"
                    ),
                    ExerciseInfo(
                        id = 2,
                        type = "pullups",
                        name = "Pull-ups",
                        icon = Icons.Default.FitnessCenter,
                        personalBest = "PB: 12 Reps"
                    ),
                    ExerciseInfo(
                        id = 3,
                        type = "situps",
                        name = "Sit-ups",
                        icon = Icons.Default.FitnessCenter,
                        personalBest = "PB: 50 Reps"
                    ),
                    ExerciseInfo(
                        id = 4,
                        type = "running",
                        name = "Running",
                        icon = Icons.Filled.DirectionsRun,
                        personalBest = "Best 1.5 Mile: 10:30"
                    )
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        exercises = mockExercises,
                        error = null
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "Failed to load exercises: ${e.message}"
                    )
                }
            }
        }
    }
} 