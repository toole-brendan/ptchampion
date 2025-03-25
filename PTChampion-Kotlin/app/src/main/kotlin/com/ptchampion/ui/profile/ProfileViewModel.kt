package com.ptchampion.ui.profile

import android.location.Location
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.repository.AppRepository
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
 * UI state for profile screen
 */
data class ProfileUiState(
    val isLoading: Boolean = false,
    val user: User? = null,
    val exerciseCount: Int = 0,
    val latestExercises: Map<String, UserExercise> = emptyMap(),
    val overallScore: Int = 0,
    val lastSyncTime: String? = null,
    val isSyncing: Boolean = false,
    val syncSuccess: Boolean? = null,
    val error: String? = null
)

/**
 * ViewModel for profile screen
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ProfileUiState(isLoading = true))
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()
    
    init {
        loadUserData()
        updateLastSyncTime()
    }
    
    /**
     * Load user profile data
     */
    fun loadUserData() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
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
                            loadExerciseData()
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
     * Load exercise data
     */
    private fun loadExerciseData() {
        viewModelScope.launch {
            // Load user exercises
            repository.getUserExercises()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load exercise data: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { exercises ->
                            _uiState.value = _uiState.value.copy(
                                exerciseCount = exercises.size
                            )
                            loadLatestExercises()
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load exercise data: ${e.message}"
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
                        isLoading = false,
                        error = "Failed to load latest exercises: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { latestExercises ->
                            val overallScore = calculateOverallScore(latestExercises)
                            
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                latestExercises = latestExercises,
                                overallScore = overallScore
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Failed to load latest exercises: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Update user location
     */
    fun updateLocation(location: Location) {
        viewModelScope.launch {
            repository.updateUserLocation(location.latitude, location.longitude)
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
     * Log out the current user
     */
    fun logout() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.logout()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Logout failed: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                user = null
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Logout failed: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Calculate overall fitness score from individual exercise scores
     */
    private fun calculateOverallScore(latestExercises: Map<String, UserExercise>): Int {
        if (latestExercises.isEmpty()) return 0
        
        var totalScore = 0
        var count = 0
        
        latestExercises.values.forEach { exercise ->
            totalScore += exercise.score
            count++
        }
        
        return if (count > 0) totalScore / count else 0
    }
    
    /**
     * Update last sync time
     */
    private fun updateLastSyncTime() {
        val lastSyncTime = repository.getLastSyncTime()
        _uiState.value = _uiState.value.copy(lastSyncTime = lastSyncTime)
    }
    
    /**
     * Sync data with server
     */
    fun syncData() {
        _uiState.value = _uiState.value.copy(isSyncing = true, syncSuccess = null, error = null)
        
        viewModelScope.launch {
            repository.syncData()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isSyncing = false,
                        syncSuccess = false,
                        error = "Sync failed: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { syncResponse ->
                            // Update UI with sync status
                            _uiState.value = _uiState.value.copy(
                                isSyncing = false,
                                syncSuccess = syncResponse.success,
                                lastSyncTime = syncResponse.timestamp,
                                error = if (!syncResponse.success) "Sync failed" else null
                            )
                            
                            // If sync was successful, refresh data
                            if (syncResponse.success) {
                                // Update user if profile data was returned
                                syncResponse.data?.profile?.let { user ->
                                    _uiState.value = _uiState.value.copy(user = user)
                                }
                                
                                // Reload exercise data if exercises were returned
                                if (syncResponse.data?.userExercises != null) {
                                    loadExerciseData()
                                }
                            }
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isSyncing = false,
                                syncSuccess = false,
                                error = "Sync failed: ${e.message}"
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
    
    /**
     * Clear sync status
     */
    fun clearSyncStatus() {
        _uiState.value = _uiState.value.copy(syncSuccess = null)
    }
}