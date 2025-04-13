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
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
// import javax.inject.Inject
import com.example.ptchampion.data.repository.UserPreferencesRepository

data class LoginState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
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

// @HiltViewModel
class LoginViewModel /* @Inject */ constructor(
    // private val authRepository: AuthRepository,
    // private val userPreferencesRepository: UserPreferencesRepository
) : ViewModel() {

    var state by mutableStateOf(LoginState())
        private set

    private val _effect = MutableSharedFlow<LoginEffect>()
    val effect = _effect.asSharedFlow()

    fun onEvent(event: LoginEvent) {
        when (event) {
            is LoginEvent.EmailChanged -> state = state.copy(email = event.value, error = null)
            is LoginEvent.PasswordChanged -> state = state.copy(password = event.value, error = null)
            LoginEvent.Submit -> loginUser()
        }
    }

    private fun loginUser() {
        viewModelScope.launch {
            // Temporarily bypass login logic as dependencies are commented out
            state = state.copy(isLoading = true) // Show loading briefly
            kotlinx.coroutines.delay(1000) // Simulate network call
            // TODO: Re-enable actual login logic when DI is set up
            /*
            state = state.copy(isLoading = true, error = null)
            val result = authRepository.login(
                LoginRequest(username = state.email, password = state.password)
            )
            when (result) {
                is Resource.Success -> {
                    result.data?.token?.let { token ->
                        userPreferencesRepository.saveAuthToken(token)
                    } ?: run {
                        state = state.copy(isLoading = false, error = "Login successful but token missing.")
                        return@launch
                    }
                   
                    state = state.copy(isLoading = false)
                    _effect.emit(LoginEffect.NavigateToHome)
                }
                is Resource.Error -> {
                    state = state.copy(isLoading = false, error = result.message)
                }
                is Resource.Loading -> {
                    // Can be ignored here as we set isLoading explicitly
                }
            }
            */
            state = state.copy(isLoading = false)
             _effect.emit(LoginEffect.NavigateToHome)
        }
    }
    
    fun navigateToSignUp() {
        viewModelScope.launch {
            _effect.emit(LoginEffect.NavigateToSignUp)
        }
    }
} 