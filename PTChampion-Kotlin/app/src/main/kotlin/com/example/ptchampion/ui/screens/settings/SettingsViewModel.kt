package com.example.ptchampion.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.AuthRepository // Assuming you have this for logout
import com.example.ptchampion.domain.repository.SettingsRepository // Assuming you have this for prefs
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

// TODO: Define UI State for SettingsScreen
data class SettingsUiState(
    val isLoading: Boolean = true,
    val useMiles: Boolean = true, // Example preference
    val error: String? = null
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository, // Inject repository for preferences
    private val authRepository: AuthRepository // Inject repository for logout
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
    }

    private fun loadSettings() {
        viewModelScope.launch {
            _uiState.value = SettingsUiState(isLoading = true)
            try {
                // TODO: Implement loading settings (e.g., unit preference) in SettingsRepository
                val useMilesPref = settingsRepository.getUnitPreference().first() // Example
                _uiState.value = SettingsUiState(isLoading = false, useMiles = useMilesPref)
            } catch (e: Exception) {
                _uiState.value = SettingsUiState(isLoading = false, error = e.message ?: "Failed to load settings", useMiles = true) // Default
            }
        }
    }

    fun setUseMiles(useMiles: Boolean) {
        viewModelScope.launch {
            try {
                // TODO: Implement saving setting in SettingsRepository
                settingsRepository.saveUnitPreference(useMiles)
                _uiState.value = uiState.value.copy(useMiles = useMiles)
            } catch (e: Exception) {
                // Handle save error (e.g., update UI state with an error message)
                _uiState.value = uiState.value.copy(error = "Failed to save preference")
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            try {
                // TODO: Implement logout in AuthRepository (clear token, etc.)
                authRepository.logout()
                // Navigation is handled by the screen
            } catch (e: Exception) {
                // Handle logout error if necessary
                _uiState.value = uiState.value.copy(error = "Logout failed")
            }
        }
    }

    // TODO: Add other setting actions (change password, etc.)
} 