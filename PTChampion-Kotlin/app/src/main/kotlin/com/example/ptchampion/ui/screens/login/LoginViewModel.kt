package com.example.ptchampion.ui.screens.login

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.AuthRepository
// import com.example.ptchampion.generatedapi.models.AuthRequest - Removed
import org.openapitools.client.models.LoginRequest // Correct import
import com.example.ptchampion.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import com.example.ptchampion.data.repository.UserPreferencesRepository
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.util.Resource as DomainResource
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class LoginState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val isLoginSuccess: Boolean = false
)

sealed class LoginEvent {
    data class EmailChanged(val value: String) : LoginEvent()
    data class PasswordChanged(val value: String) : LoginEvent()
    object Submit : LoginEvent()
}

sealed class LoginEffect {
    object NavigateToHome : LoginEffect()
    object NavigateToSignUp : LoginEffect() // Example for navigation effect
}

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginState())
    val uiState: StateFlow<LoginState> = _uiState.asStateFlow()

    private val _effect = MutableSharedFlow<LoginEffect>()
    val effect = _effect.asSharedFlow()

    fun onEvent(event: LoginEvent) {
        when (event) {
            is LoginEvent.EmailChanged -> _uiState.update { it.copy(email = event.value, error = null) }
            is LoginEvent.PasswordChanged -> _uiState.update { it.copy(password = event.value, error = null) }
            LoginEvent.Submit -> login()
        }
    }

    fun login() {
        // Prevent multiple login attempts while one is in progress
        if (_uiState.value.isLoading) return

        val email = _uiState.value.email
        val password = _uiState.value.password

        // Basic client-side validation (optional, but good practice)
        if (email.isBlank() || password.isBlank()) {
            _uiState.update { it.copy(error = "Email and password cannot be empty") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, isLoginSuccess = false) }
            
            val result = userRepository.login(email, password)

            when (result) {
                is DomainResource.Success -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            isLoginSuccess = true,
                            error = null
                        )
                    }
                    _effect.emit(LoginEffect.NavigateToHome)
                }
                is DomainResource.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.message ?: "An unknown login error occurred",
                            isLoginSuccess = false
                        )
                    }
                }
                is DomainResource.Loading -> {
                    // Optional: Handle loading state if needed, though already set
                    _uiState.update { it.copy(isLoading = true) }
                }
            }
        }
    }
    
    fun navigateToSignUp() {
        viewModelScope.launch {
            _effect.emit(LoginEffect.NavigateToSignUp)
        }
    }

    // Optional: Function to reset the success flag after navigation
    fun resetLoginSuccess() {
        _uiState.update { it.copy(isLoginSuccess = false) }
    }
} 