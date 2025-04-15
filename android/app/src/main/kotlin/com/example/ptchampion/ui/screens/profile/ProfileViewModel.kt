package com.example.ptchampion.ui.screens.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileState(
    val isLoading: Boolean = true, // Start as loading
    val user: User? = null,
    val error: String? = null
    // Removed totalWorkouts as it's not directly in the User model yet
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileState())
    val uiState: StateFlow<ProfileState> = _uiState.asStateFlow()

    init {
        observeProfileData()
    }

    private fun observeProfileData() {
        userRepository.getCurrentUserFlow()
            .onEach { user ->
                // Update state when user data changes (login, update, logout)
                _uiState.update {
                    it.copy(
                        isLoading = false, // Data received (or null)
                        user = user,
                        error = if (user == null && it.isLoading) "Failed to load profile" else null
                    )
                }
            }
            .catch { e ->
                // Handle potential errors in the flow itself
                _uiState.update { it.copy(isLoading = false, error = "Error observing profile: ${e.message}") }
            }
            .launchIn(viewModelScope)
    }

    fun logout(onLoggedOut: () -> Unit) {
        viewModelScope.launch {
            // Consider showing loading state during logout
            // _uiState.update { it.copy(isLoading = true) }
            userRepository.logout()
            // Flow update will set user to null
            onLoggedOut() // Trigger navigation callback
        }
    }

    // Optional: Add refresh function if needed later
    // fun refreshProfile() {
    //     viewModelScope.launch {
    //         _uiState.update { it.copy(isLoading = true) }
    //         val result = userRepository.refreshUserProfile()
    //         if (result is Resource.Error) {
    //             _uiState.update { it.copy(isLoading = false, error = result.message) }
    //         } // Success is handled by the flow observation
    //     }
    // }
} 