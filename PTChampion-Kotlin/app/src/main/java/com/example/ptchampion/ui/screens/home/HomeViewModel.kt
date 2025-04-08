package com.example.ptchampion.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeState(
    val isLoading: Boolean = false,
    val userName: String? = null,
    val error: String? = null
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeState())
    val uiState: StateFlow<HomeState> = _uiState.asStateFlow()

    init {
        observeUserProfile()
    }

    private fun observeUserProfile() {
        userRepository.getUserProfileFlow()
            .onEach { resource ->
                when (resource) {
                    is Resource.Loading -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = true,
                            error = null
                        )
                    }
                    is Resource.Success -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            userName = resource.data?.name ?: "User", // Use fetched name or default
                            error = null
                        )
                    }
                    is Resource.Error -> {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = resource.message ?: "An unknown error occurred"
                            // Keep previous user name if available on error
                        )
                    }
                }
            }
            .launchIn(viewModelScope)
    }

    // Optional: Function to trigger a refresh if needed
    fun refreshData() {
        viewModelScope.launch {
            userRepository.refreshUserProfile() // Result ignored for now, flow will update state
        }
    }

    // TODO: Add functions for user interactions
} 