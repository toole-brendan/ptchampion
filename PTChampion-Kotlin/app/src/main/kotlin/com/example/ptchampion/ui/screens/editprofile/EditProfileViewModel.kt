package com.example.ptchampion.ui.screens.editprofile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay // For simulating network calls

data class EditProfileUiState(
    val isLoading: Boolean = false,
    val name: String = "",
    val email: String = "",
    val avatarUrl: String? = null, // Placeholder for avatar
    val error: String? = null,
    val isSaveSuccess: Boolean = false
)

class EditProfileViewModel(
    // TODO: Inject UserRepository, UserPreferencesRepository when DI is set up
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditProfileUiState())
    val uiState: StateFlow<EditProfileUiState> = _uiState.asStateFlow()

    init {
        loadUserProfile()
    }

    private fun loadUserProfile() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            // Simulate loading data
            delay(500)
            // TODO: Replace with actual data fetching from repository
            _uiState.update {
                it.copy(
                    isLoading = false,
                    name = "Current User", // Replace with actual data
                    email = "current@example.com", // Replace with actual data
                    avatarUrl = null // Replace with actual avatar URL if available
                )
            }
        }
    }

    fun onNameChange(newName: String) {
        _uiState.update { it.copy(name = newName, error = null) }
    }

    fun onEmailChange(newEmail: String) {
        _uiState.update { it.copy(email = newEmail, error = null) }
    }

    fun onAvatarChange() {
        // TODO: Implement avatar selection logic (e.g., open image picker)
        // For now, maybe just cycle a placeholder or show a message
        println("Avatar change requested")
    }

    fun saveProfile() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, isSaveSuccess = false) }
            try {
                // Simulate network delay
                delay(1000)
                // TODO: Add validation logic here (e.g., check email format)
                if (_uiState.value.name.isBlank() || _uiState.value.email.isBlank()) {
                   throw IllegalArgumentException("Name and Email cannot be empty")
                }

                // TODO: Call repository to save the updated profile data
                // val success = userRepository.updateProfile(...)

                // Simulate success
                val success = true // Replace with actual API call result

                if (success) {
                    _uiState.update { it.copy(isLoading = false, isSaveSuccess = true) }
                } else {
                    throw Exception("Failed to save profile")
                }

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "An unknown error occurred",
                        isSaveSuccess = false
                    )
                }
            }
        }
    }

    // Call this after navigation to reset the success flag
    fun resetSaveSuccess() {
        _uiState.update { it.copy(isSaveSuccess = false) }
    }
}
