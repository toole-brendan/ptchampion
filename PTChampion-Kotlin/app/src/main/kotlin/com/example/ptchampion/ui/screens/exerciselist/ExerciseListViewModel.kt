package com.example.ptchampion.ui.screens.exerciselist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.domain.repository.ExerciseRepository // Remove unused import
import com.example.ptchampion.domain.model.ExerciseResponse
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

data class ExerciseListState(
    val exercises: List<ExerciseResponse> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

// @HiltViewModel // Remove Hilt annotation
class ExerciseListViewModel /* @Inject */ constructor(
    // private val exerciseRepository: ExerciseRepository // Remove repo injection
) : ViewModel() {

    private val _state = MutableStateFlow(ExerciseListState())
    val state: StateFlow<ExerciseListState> = _state.asStateFlow()

    init {
        fetchExercises()
    }

    private fun fetchExercises() {
        viewModelScope.launch {
             _state.update { it.copy(isLoading = true, error = null) }
             kotlinx.coroutines.delay(1000) // Simulate loading
             // TODO: Re-enable actual fetching when DI is setup
             /*
            when (val result = exerciseRepository.getExercises()) {
                is Resource.Success -> {
                    _state.update { it.copy(isLoading = false, exercises = result.data ?: emptyList()) }
                }
                is Resource.Error -> {
                    _state.update { it.copy(isLoading = false, error = result.message ?: "Failed to load exercises") }
                }
                is Resource.Loading -> { /* Already handled */ }
            }
            */
            // Simulate success with dummy data
             val dummyExercises = listOf(
                 ExerciseResponse(id = 1, name = "Push-ups", type = "PUSH_UPS", description = "Standard push-ups"),
                 ExerciseResponse(id = 2, name = "Pull-ups", type = "PULL_UPS", description = "Standard pull-ups"),
                 ExerciseResponse(id = 3, name = "Sit-ups", type = "SIT_UPS", description = "Standard sit-ups")
             )
             _state.update { it.copy(isLoading = false, exercises = dummyExercises) }
        }
    }
} 