package com.example.ptchampion.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.example.ptchampion.domain.repository.UserRepository // Remove unused import
// import com.example.ptchampion.domain.util.Resource // Remove unused import
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
// import javax.inject.Inject

data class HomeUiState(
    val isLoading: Boolean = false,
    val userName: String? = null,
    val error: String? = null
    // Add other relevant home screen data (e.g., recent workout summary)
)

class HomeViewModel constructor(
    // private val userRepository: UserRepository // Remove repo injection
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        observeUserProfile()
    }

    private fun observeUserProfile() {
        _uiState.value = HomeUiState(userName = "Temp User") // Simulate success
        // TODO: Re-enable actual fetching when DI is setup
        /*
        userRepository.getUserProfileFlow()
            .onEach { resource ->
                val currentState = _uiState.value
                when (resource) {
                    is Resource.Loading -> {
                        _uiState.value = currentState.copy(isLoading = true, error = null)
                    }
                    is Resource.Success -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            userName = resource.data?.name ?: "User", // Default name if null
                            error = null
                        )
                    }
                    is Resource.Error -> {
                        _uiState.value = currentState.copy(
                            isLoading = false,
                            error = resource.message ?: "Failed to load profile"
                            // Keep previous user name on error? Optional.
                        )
                    }
                }
            }
            .launchIn(viewModelScope)
        */
    }

    // Add functions for any actions triggered from the home screen
} 