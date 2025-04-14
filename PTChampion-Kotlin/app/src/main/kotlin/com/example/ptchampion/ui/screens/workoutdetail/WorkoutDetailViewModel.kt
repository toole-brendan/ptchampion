package com.example.ptchampion.ui.screens.workoutdetail

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.model.WorkoutResponse // Use WorkoutResponse from API
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.util.Resource // Import your Resource class
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

// TODO: Define UI State data class for WorkoutDetailScreen
data class WorkoutDetailUiState(
    val isLoading: Boolean = true,
    val workout: WorkoutResponse? = null, // Store the response directly
    val error: String? = null
)

@HiltViewModel
class WorkoutDetailViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository,
    savedStateHandle: SavedStateHandle // Inject SavedStateHandle directly
) : ViewModel() {

    private val _uiState = MutableStateFlow(WorkoutDetailUiState())
    val uiState: StateFlow<WorkoutDetailUiState> = _uiState.asStateFlow()

    // Retrieve workoutId safely
    private val workoutId: String = savedStateHandle.get<String>("workoutId")
        ?: throw IllegalStateException("workoutId not found in SavedStateHandle")

    init {
        fetchWorkoutDetails()
    }

    private fun fetchWorkoutDetails() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) } // Start loading

            when (val result = workoutRepository.getWorkoutById(workoutId)) {
                is Resource.Success -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            workout = result.data,
                            error = null
                        )
                    }
                }
                is Resource.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            workout = null,
                            error = result.message ?: "Failed to load workout details"
                        )
                    }
                }
                is Resource.Loading -> {
                     // Optional: Handle loading state update if repository emits it
                     _uiState.update { it.copy(isLoading = true) }
                }
            }
        }
    }

    fun retryFetch() {
        fetchWorkoutDetails()
    }

    // TODO: Add any necessary event handlers or actions based on the detail screen features
} 