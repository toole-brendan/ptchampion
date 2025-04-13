package com.example.ptchampion.ui.screens.splash

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.data.repository.UserPreferencesRepository
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
// import org.openapitools.client.apis.UsersApi - No longer needs direct import as it's commented out
import retrofit2.HttpException
import java.io.IOException
// import javax.inject.Inject

sealed class SplashDestination {
    object Login : SplashDestination()
    object Home : SplashDestination()
    object Undetermined: SplashDestination() // Initial state
}

// @HiltViewModel
class SplashViewModel /* @Inject */ constructor(
    // private val userPreferencesRepository: UserPreferencesRepository,
    // private val usersApi: UsersApi
) : ViewModel() {

    private val _destination = MutableStateFlow<SplashDestination>(SplashDestination.Undetermined)
    val destination = _destination.asStateFlow()

    init {
        // checkAuthStatus() // Temporarily disable auth check
        // Always navigate to Login for now
        _destination.value = SplashDestination.Login 
    }

    private fun checkAuthStatus() {
         // TODO: Re-enable when DI is set up
        /*
        viewModelScope.launch {
            val token = userPreferencesRepository.authToken.firstOrNull()
            if (token != null) {
                try {
                    // Attempt to validate token by calling PATCH /users/me
                    // We don't need the response body, just check for success/failure.
                    // Note: Retrofit Call adapters are needed to use suspend functions directly.
                    // Assuming the generated code uses Call<T>, we execute it.
                    // If it uses suspend fun, adjust accordingly.
                    val response = usersApi.usersMePatch().execute() // Use execute() for blocking call within launch

                    if (response.isSuccessful) {
                        // Token is likely valid
                        _destination.value = SplashDestination.Home
                    } else {
                        // API returned an error (e.g., 401 if token invalid/expired)
                        userPreferencesRepository.clearAuthToken() // Clear invalid token
                        _destination.value = SplashDestination.Login
                    }
                } catch (e: HttpException) {
                    // Specific HTTP error (like 401 Unauthorized)
                    userPreferencesRepository.clearAuthToken() // Clear invalid token
                    _destination.value = SplashDestination.Login
                } catch (e: IOException) {
                    // Network error (e.g., no connection)
                    // Decide how to handle - maybe retry later or go to Login?
                    // For now, assume offline token might still be usable for cached data (if implemented)
                    // or just go to login if online validation is strictly required.
                    // Let's go to login for simplicity for now.
                    _destination.value = SplashDestination.Login
                } catch (e: Exception) {
                    // Other unexpected errors
                    userPreferencesRepository.clearAuthToken()
                    _destination.value = SplashDestination.Login
                }
            } else {
                // No token found
                _destination.value = SplashDestination.Login
            }
        }
        */
    }
} 