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
 * Authentication states
 */
sealed class AuthState {
    object Initial : AuthState()
    object Loading : AuthState()
    data class Success(val user: User) : AuthState()
    data class Error(val message: String) : AuthState()
}

/**
 * View model for authentication
 */
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {
    
    private val _authState = MutableStateFlow<AuthState>(AuthState.Initial)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    // Login
    fun login(username: String, password: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            
            repository.login(username, password)
                .catch { e ->
                    _authState.value = AuthState.Error(e.message ?: "Login failed")
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _authState.value = AuthState.Success(user)
                        },
                        onFailure = { e ->
                            _authState.value = AuthState.Error(e.message ?: "Login failed")
                        }
                    )
                }
        }
    }
    
    // Register
    fun register(username: String, password: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            
            repository.register(username, password)
                .catch { e ->
                    _authState.value = AuthState.Error(e.message ?: "Registration failed")
                }
                .collectLatest { result ->
                    result.fold(
                        onSuccess = { user ->
                            _authState.value = AuthState.Success(user)
                        },
                        onFailure = { e ->
                            _authState.value = AuthState.Error(e.message ?: "Registration failed")
                        }
                    )
                }
        }
    }
    
    // Reset state
    fun resetState() {
        _authState.value = AuthState.Initial
    }
}