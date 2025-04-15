package com.example.ptchampion.ui.screens.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.data.datastore.UserPreferencesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject

sealed class SplashDestination {
    object Login : SplashDestination()
    object Home : SplashDestination()
    object Undetermined: SplashDestination() // Initial state
}

@HiltViewModel
class SplashViewModel @Inject constructor(
    private val userPreferencesRepository: UserPreferencesRepository
) : ViewModel() {

    private val _destination = MutableStateFlow<SplashDestination>(SplashDestination.Undetermined)
    val destination = _destination.asStateFlow()

    init {
        checkAuthStatus()
    }

    private fun checkAuthStatus() {
        viewModelScope.launch {
            val token = userPreferencesRepository.authToken.firstOrNull()
            if (token != null) {
                try {
                    // For now, just check if token exists and assume it's valid
                    // In a production app, you would validate the token with a server call
                    _destination.value = SplashDestination.Home
                } catch (e: HttpException) {
                    userPreferencesRepository.clearAuthToken()
                    _destination.value = SplashDestination.Login
                } catch (e: IOException) {
                    _destination.value = SplashDestination.Login
                } catch (e: Exception) {
                    userPreferencesRepository.clearAuthToken()
                    _destination.value = SplashDestination.Login
                }
            } else {
                // No token found
                _destination.value = SplashDestination.Login
            }
        }
    }
} 