package com.ptchampion.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.repository.AppRepository
import com.ptchampion.domain.model.Exercise
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
 * History UI state
 */
data class HistoryUiState(
    val isLoading: Boolean = false,
    val exercises: List<Exercise> = emptyList(),
    val userExercises: List<UserExercise> = emptyList(),
    val filteredUserExercises: List<UserExercise> = emptyList(),
    val selectedType: String? = null,
    val error: String? = null
)

/**
 * ViewModel for the history screen
 */
@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(HistoryUiState(isLoading = true))
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()
    
    init {
        loadData()
    }
    
    /**
     * Load all exercise history data
     */
    fun loadData() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        // Load exercise definitions
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
                                exercises = exercises
                            )
                            
                            // Now load user exercises
                            loadUserExercises()
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
     * Load user exercise history
     */
    private fun loadUserExercises() {
        viewModelScope.launch {
            repository.getUserExercises()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load exercise history: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { userExercises ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                userExercises = userExercises,
                                filteredUserExercises = if (_uiState.value.selectedType != null) {
                                    userExercises.filter { it.type == _uiState.value.selectedType }
                                } else {
                                    userExercises
                                }
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load exercise history: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Filter history by exercise type
     */
    fun filterByType(type: String?) {
        _uiState.value = _uiState.value.copy(
            selectedType = type,
            filteredUserExercises = if (type != null) {
                _uiState.value.userExercises.filter { it.type == type }
            } else {
                _uiState.value.userExercises
            }
        )
    }
    
    /**
     * Get exercise by ID
     */
    fun getExerciseById(id: Int): Exercise? {
        return _uiState.value.exercises.find { it.id == id }
    }
    
    /**
     * Clear error
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}