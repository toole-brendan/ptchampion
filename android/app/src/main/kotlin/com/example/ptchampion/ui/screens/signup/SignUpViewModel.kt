package com.example.ptchampion.ui.screens.signup

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.data.network.dto.RegisterRequestDto
import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.domain.util.Resource as DomainResource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SignUpState(
    val username: String = "",
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSignUpSuccess: Boolean = false
)

sealed class SignUpEvent {
    data class UsernameChanged(val value: String) : SignUpEvent()
    data class EmailChanged(val value: String) : SignUpEvent()
    data class PasswordChanged(val value: String) : SignUpEvent()
    data class ConfirmPasswordChanged(val value: String) : SignUpEvent()
    object Submit : SignUpEvent()
}

sealed class SignUpEffect {
    object NavigateToLogin : SignUpEffect()
}

@HiltViewModel
class SignUpViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SignUpState())
    val uiState: StateFlow<SignUpState> = _uiState.asStateFlow()

    private val _effect = MutableStateFlow<SignUpEffect?>(null)
    val effect: StateFlow<SignUpEffect?> = _effect.asStateFlow()

    fun onEvent(event: SignUpEvent) {
        when (event) {
            is SignUpEvent.UsernameChanged -> _uiState.update { it.copy(username = event.value, error = null) }
            is SignUpEvent.EmailChanged -> _uiState.update { it.copy(email = event.value, error = null) }
            is SignUpEvent.PasswordChanged -> _uiState.update { it.copy(password = event.value, error = null) }
            is SignUpEvent.ConfirmPasswordChanged -> _uiState.update { it.copy(confirmPassword = event.value, error = null) }
            SignUpEvent.Submit -> signUp()
        }
    }

    private fun signUp() {
        if (_uiState.value.isLoading) return

        val state = _uiState.value
        if (state.username.isBlank() || state.password.isBlank() || state.email.isBlank()) {
            _uiState.update { it.copy(error = "Username, Email, and Password cannot be empty") }
            return
        }
        if (state.password != state.confirmPassword) {
            _uiState.update { it.copy(error = "Passwords do not match") }
            return
        }
        // TODO: Add more robust validation (email format, password complexity)

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, isSignUpSuccess = false) }

            val registerRequest = RegisterRequestDto(
                username = state.username,
                password = state.password
            )

            val result = authRepository.register(registerRequest)

            when (result) {
                is DomainResource.Success -> {
                    _uiState.update { it.copy(isLoading = false, isSignUpSuccess = true, error = null) }
                    _effect.update { SignUpEffect.NavigateToLogin }
                }
                is DomainResource.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.message ?: "An unknown sign-up error occurred",
                            isSignUpSuccess = false
                        )
                    }
                }
                is DomainResource.Loading -> {
                    _uiState.update { it.copy(isLoading = true) }
                }
            }
        }
    }

    fun navigateToLogin() {
        _effect.update { SignUpEffect.NavigateToLogin }
    }

    fun resetSignUpSuccess() {
        _uiState.update { it.copy(isSignUpSuccess = false) }
    }

    fun consumeEffect() {
        _effect.value = null
    }
} 