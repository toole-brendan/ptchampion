package com.ptchampion.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ptchampion.data.repository.AppRepository
import com.ptchampion.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI state for authentication screens
 */
data class AuthUiState(
    val isLoading: Boolean = false,
    val isLoggedIn: Boolean = false,
    val user: User? = null,
    val error: String? = null
)

/**
 * ViewModel for authentication screens
 */
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()
    
    init {
        // Check if user is already logged in
        if (repository.isLoggedIn()) {
            loadCurrentUser()
        }
    }
    
    /**
     * Login with username and password
     */
    fun login(username: String, password: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.login(username, password)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Login failed: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = true,
                                user = user
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Login failed: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Register a new account
     */
    fun register(username: String, password: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.register(username, password)
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Registration failed: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = true,
                                user = user
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = "Registration failed: ${e.message}"
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Load the current user if any
     */
    fun loadCurrentUser() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.getCurrentUser()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        isLoggedIn = false,
                        error = "Failed to load user: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = true,
                                user = user
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = false,
                                error = null // Don't show error for this case
                            )
                        }
                    )
                }
        }
    }
    
    /**
     * Logout the current user
     */
    fun logout() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        
        viewModelScope.launch {
            repository.logout()
                .catch { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        isLoggedIn = false,
                        user = null,
                        error = "Logout failed: ${e.message}"
                    )
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = false,
                                user = null
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                isLoggedIn = false,
                                user = null,
                                error = "Logout failed: ${e.message}"
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