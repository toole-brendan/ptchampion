package com.example.ptchampion.ui.screens.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class HistoryUiState(
    val workouts: List<WorkoutResponse> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val currentPage: Int = 1,
    val isLastPage: Boolean = false
)

class HistoryViewModel constructor(
) : ViewModel() {

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    init {
        loadInitialHistory()
    }

    private fun loadInitialHistory() {
        loadWorkoutHistory(page = 1, initialLoad = true)
    }

    fun loadMoreHistory() {
        if (!_uiState.value.isLoading && !_uiState.value.isLastPage) {
            loadWorkoutHistory(page = _uiState.value.currentPage + 1)
        }
    }

    private fun loadWorkoutHistory(page: Int, initialLoad: Boolean = false) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = if (initialLoad) null else it.error) }
            kotlinx.coroutines.delay(1000) // Simulate loading
             // TODO: Re-enable actual fetching when DI is setup
            /*
            when (val result = workoutRepository.getWorkoutHistory(page = page)) {
                is Resource.Success -> {
                    val newWorkouts = result.data?.items ?: emptyList()
                    val isLast = result.data?.page ?: 1 >= result.data?.pages ?: 1
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            workouts = if (initialLoad) newWorkouts else it.workouts + newWorkouts,
                            currentPage = result.data?.page ?: it.currentPage,
                            isLastPage = isLast,
                            error = null // Clear error on success
                        )
                    }
                }
                is Resource.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.message ?: "Failed to load workout history"
                        )
                    }
                }
                is Resource.Loading -> { /* Handled by isLoading = true */ }
            }
            */
            // Simulate success with dummy data (only on initial load for this example)
            if (initialLoad) {
                val dummyHistory = List(5) { i ->
                    WorkoutResponse(
                        id = i + 1,
                        exerciseId = 1,
                        exerciseName = "Push-ups",
                        repetitions = 20 + i * 2,
                        durationSeconds = null,
                        formScore = 80 + i,
                        grade = 85 + i,
                        completedAt = "2024-03-${10 + i}T10:30:00Z",
                        createdAt = "2024-03-${10 + i}T10:29:00Z"
                    )
                }
                _uiState.update {
                     it.copy(isLoading = false, workouts = dummyHistory, isLastPage = true) // Assume last page for dummy data
                }
            } else {
                 _uiState.update { it.copy(isLoading = false) } // Just stop loading if not initial
            }
        }
    }
} 