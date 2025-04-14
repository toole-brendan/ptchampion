package com.example.ptchampion.ui.screens.editprofile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EditProfileUiState(
    val isLoading: Boolean = true, // Start loading
    val name: String = "", // Corresponds to displayName
    val email: String = "", // Keep for display, but might not be editable
    val profilePictureUrl: String? = null,
    val location: String? = null,
    val error: String? = null,
    val isSaveSuccess: Boolean = false
)

@HiltViewModel
class EditProfileViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditProfileUiState())
    val uiState: StateFlow<EditProfileUiState> = _uiState.asStateFlow()

    init {
        loadUserProfile()
    }

    private fun loadUserProfile() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            // Get the current user data once
            val currentUser = userRepository.getCurrentUserFlow().first()
            
            if (currentUser != null) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        name = currentUser.displayName ?: currentUser.username, // Fallback to username
                        email = currentUser.email ?: "", // Use email if available
                        profilePictureUrl = currentUser.profilePictureUrl,
                        // TODO: Load location/lat/lon if needed for editing
                        location = null // Placeholder
                    )
                }
            } else {
                _uiState.update { it.copy(isLoading = false, error = "Failed to load user profile.") }
            }
        }
    }

    fun onNameChange(newName: String) {
        _uiState.update { it.copy(name = newName, error = null) }
    }

    // Email likely isn't editable, remove if not needed
    fun onEmailChange(newEmail: String) {
        _uiState.update { it.copy(email = newEmail, error = null) }
    }

    fun onProfilePictureUrlChange(newUrl: String?) {
        _uiState.update { it.copy(profilePictureUrl = newUrl, error = null) }
    }

    fun onLocationChange(newLocation: String?) {
         _uiState.update { it.copy(location = newLocation, error = null) }
    }

    // TODO: Implement avatar selection/upload logic
    fun onAvatarChange() {
        // This should trigger image picker, upload, get URL, then call onProfilePictureUrlChange
        println("Avatar change requested - requires implementation")
        _uiState.update { it.copy(error = "Avatar change not implemented yet.") }
    }

    fun saveProfile() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, isSaveSuccess = false) }
            
            // Get current state for saving
            val state = _uiState.value

            // Basic validation
            if (state.name.isBlank()) {
                _uiState.update { it.copy(isLoading = false, error = "Name cannot be empty") }
                return@launch
            }

            try {
                val result = userRepository.updateProfile(
                    displayName = state.name,
                    profilePictureUrl = state.profilePictureUrl, // Assume URL is already updated
                    location = state.location
                    // TODO: Add lat/lon if location is structured
                )

                when (result) {
                    is Resource.Success -> {
                        _uiState.update { it.copy(isLoading = false, isSaveSuccess = true) }
                    }
                    is Resource.Error -> {
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = result.message ?: "Failed to save profile",
                                isSaveSuccess = false
                            )
                        }
                    }
                    else -> { // Handle Loading case if necessary, though should be brief
                        _uiState.update { it.copy(isLoading = true) }
                    }
                }

            } catch (e: Exception) { // Catch any unexpected errors during the process
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "An unknown error occurred during save",
                        isSaveSuccess = false
                    )
                }
            }
        }
    }

    fun resetSaveSuccess() {
        _uiState.update { it.copy(isSaveSuccess = false) }
    }
}
