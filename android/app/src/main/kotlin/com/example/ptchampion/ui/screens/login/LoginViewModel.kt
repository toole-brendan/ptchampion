package com.example.ptchampion.ui.screens.login

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.domain.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

sealed class LoginEffect {
    object NavigateToHome : LoginEffect()
    data class ShowError(val message: String) : LoginEffect()
}

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginState())
    val uiState = _uiState.asStateFlow()

    private val _effect = MutableStateFlow<LoginEffect?>(null)
    val effect = _effect.asStateFlow()

    fun onEvent(event: LoginEvent) {
        when (event) {
            is LoginEvent.EmailChanged -> _uiState.update { it.copy(email = event.value, error = null) }
            is LoginEvent.PasswordChanged -> _uiState.update { it.copy(password = event.value, error = null) }
            LoginEvent.Submit -> loginUser()
            LoginEvent.EffectConsumed -> _effect.value = null
        }
    }

    private fun loginUser() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            val email = _uiState.value.email
            val password = _uiState.value.password

            val loginRequest = com.example.ptchampion.data.network.dto.LoginRequestDto(username = email, password = password)
            
            val result = authRepository.login(loginRequest)

            when (result) {
                is Resource.Success -> {
                    _uiState.update { it.copy(isLoading = false) }
                    _effect.value = LoginEffect.NavigateToHome
                }
                is Resource.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = result.message) }
                    _effect.value = LoginEffect.ShowError(result.message ?: "Unknown login error")
                }
                 is Resource.Loading -> {
                    // Handled by initial isLoading update
                }
            }
        }
    }
}

sealed class LoginEvent {
    data class EmailChanged(val value: String) : LoginEvent()
    data class PasswordChanged(val value: String) : LoginEvent()
    object Submit : LoginEvent()
    object EffectConsumed: LoginEvent()
}