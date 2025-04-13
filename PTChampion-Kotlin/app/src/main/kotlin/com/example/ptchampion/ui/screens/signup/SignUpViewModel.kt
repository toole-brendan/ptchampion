package com.example.ptchampion.ui.screens.signup

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.AuthRepository
// import com.example.ptchampion.generatedapi.models.RegisterRequest - Removed
import org.openapitools.client.models.InsertUser // Correct import
import com.example.ptchampion.util.Resource
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
// import javax.inject.Inject

data class SignUpState(
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

sealed class SignUpEvent {
    data class EmailChanged(val value: String) : SignUpEvent()
    data class PasswordChanged(val value: String) : SignUpEvent()
    data class ConfirmPasswordChanged(val value: String) : SignUpEvent()
    object Submit : SignUpEvent()
}

sealed class SignUpEffect {
    object NavigateToLogin : SignUpEffect()
}

// @HiltViewModel
class SignUpViewModel /* @Inject */ constructor(
    // private val authRepository: AuthRepository
) : ViewModel() {

    var state by mutableStateOf(SignUpState())
        private set

    private val _effect = MutableSharedFlow<SignUpEffect>()
    val effect = _effect.asSharedFlow()

    fun onEvent(event: SignUpEvent) {
        when (event) {
            is SignUpEvent.EmailChanged -> state = state.copy(email = event.value, error = null)
            is SignUpEvent.PasswordChanged -> state = state.copy(password = event.value, error = null)
            is SignUpEvent.ConfirmPasswordChanged -> state = state.copy(confirmPassword = event.value, error = null)
            SignUpEvent.Submit -> registerUser()
        }
    }

    private fun registerUser() {
        if (state.password != state.confirmPassword) {
            state = state.copy(error = "Passwords do not match")
            return
        }
        
        if (state.password.length < 6) { // Example basic validation
             state = state.copy(error = "Password must be at least 6 characters")
            return
        }

        viewModelScope.launch {
            // Temporarily bypass registration logic
            state = state.copy(isLoading = true)
            kotlinx.coroutines.delay(1000)
            // TODO: Re-enable actual registration logic when DI is set up
            /*
            state = state.copy(isLoading = true, error = null)
            val result = authRepository.register(
                InsertUser(username = state.email, password = state.password)
            )
            when (result) {
                is Resource.Success -> {
                    state = state.copy(isLoading = false)
                    _effect.emit(SignUpEffect.NavigateToLogin) // Navigate back to Login on success
                }
                is Resource.Error -> {
                    state = state.copy(isLoading = false, error = result.message)
                }
                 is Resource.Loading -> { }
            }
            */
             state = state.copy(isLoading = false)
            _effect.emit(SignUpEffect.NavigateToLogin)
        }
    }
    
    fun navigateToLogin() {
         viewModelScope.launch {
            _effect.emit(SignUpEffect.NavigateToLogin)
        }
    }
} 