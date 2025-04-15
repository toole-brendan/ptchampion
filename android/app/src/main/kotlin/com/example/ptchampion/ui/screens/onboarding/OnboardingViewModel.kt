package com.example.ptchampion.ui.screens.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.domain.repository.SettingsRepository // Assuming you use this to store onboarding status
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository // Inject repository to save flag
) : ViewModel() {

    fun completeOnboarding() {
        viewModelScope.launch {
            // TODO: Implement saving the onboarding completion flag in SettingsRepository
            settingsRepository.setOnboardingComplete(true)
        }
    }

    // You might add logic here to check if onboarding is needed initially,
    // although that might be better handled in your main navigation logic.
} 