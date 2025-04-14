package com.example.ptchampion.ui.screens.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.data.repository.UserPreferencesRepository // Remove unused import
// import com.example.ptchampion.domain.repository.UserRepository // Remove unused import
// import com.example.ptchampion.domain.util.Resource // Remove unused import
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

data class ProfileState(
    val isLoading: Boolean = false,
    val userName: String? = null,
    val userEmail: String? = null,
    val totalWorkouts: Int? = null,
    val error: String? = null
)

class ProfileViewModel constructor(
    // private val userPreferencesRepository: UserPreferencesRepository,
    // private val userRepository: UserRepository // Injected
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileState())
    val uiState: StateFlow<ProfileState> = _uiState.asStateFlow()

    init {
        // observeProfileData() // Temporarily disable observation
        // Simulate initial loading and success state
        _uiState.value = ProfileState(
            userName = "Temp User",
            userEmail = "temp@example.com",
            totalWorkouts = 43
        )
    }

    private fun observeProfileData() {
        // TODO: Re-enable when DI is set up
        /*
        userRepository.getUserProfileFlow()
            .onEach { resource ->
                val currentState = _uiState.value
                when (resource) {
                    is Resource.Loading -> {
                        _uiState.value = currentState.copy(
                            isLoading = true,
                            error = null
                        )
                    }
                    is Resource.Success -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            userName = resource.data?.name ?: "Unknown User",
                            userEmail = resource.data?.email ?: "No email",
                            error = null
                        )
                    }
                    is Resource.Error -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            error = resource.message ?: "An unknown error occurred",
                            // Keep previous data on error if needed
                            userName = currentState.userName,
                            userEmail = currentState.userEmail
                        )
                    }
                }
            }
            .launchIn(viewModelScope)
        */
    }

    // Optional: Add a refresh function if pull-to-refresh or similar is needed
    fun refreshProfile() {
         // TODO: Re-enable when DI is set up
        /*
        viewModelScope.launch {
            // Can potentially show loading indicator specifically for refresh
             userRepository.refreshUserProfile()
             // Flow update will handle UI changes
        }
        */
    }

    fun logout(onLoggedOut: () -> Unit) {
         // TODO: Re-enable when DI is set up
        /*
        viewModelScope.launch {
            // Consider showing loading state during logout
            _uiState.value = _uiState.value.copy(isLoading = true)
            userPreferencesRepository.clearAuthToken()
             // No need to explicitly set isLoading back to false, as navigation will occur
            onLoggedOut() // Trigger navigation callback
        }
        */
        // Simulate logout for now
        onLoggedOut()
    }
} 