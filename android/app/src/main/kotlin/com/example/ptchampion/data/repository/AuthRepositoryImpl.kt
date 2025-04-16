package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.data.service.AuthApiService
import com.example.ptchampion.data.network.dto.LoginRequestDto
import com.example.ptchampion.data.network.dto.LoginResponseDto
import com.example.ptchampion.data.network.dto.RegisterRequestDto
import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import android.content.Context
import android.content.SharedPreferences
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import dagger.hilt.android.qualifiers.ApplicationContext
import com.example.ptchampion.data.datastore.AuthDataStore

const val AUTH_TOKEN_KEY = "auth_token"

@Singleton // Indicate Hilt should provide a single instance
class AuthRepositoryImpl @Inject constructor(
    private val authApiService: AuthApiService,
    @ApplicationContext private val context: Context,
    private val encryptedPrefs: SharedPreferences,
    private val authDataStore: AuthDataStore
) : AuthRepository {

    // Login implementation
    override suspend fun login(loginRequest: LoginRequestDto): Resource<LoginResponseDto> {
        return withContext(Dispatchers.IO) {
            try {
                val response = authApiService.login(loginRequest)
                
                if (response.isSuccessful && response.body() != null) {
                    val responseBody = response.body()!!
                    // Check for token from API
                    if (responseBody.token != null) {
                        // Save token in both storage mechanisms for consistency
                        storeAuthToken(responseBody.token)
                    }
                    Resource.Success(responseBody)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Login failed: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }

    override suspend fun register(registerRequest: RegisterRequestDto): Resource<User> {
        return withContext(Dispatchers.IO) {
            try {
                val response = authApiService.register(registerRequest)
                
                if (response.isSuccessful && response.body() != null) {
                    val userDto = response.body()!!
                    // Map DTO to domain model - you'll need to implement this mapping
                    val user = mapUserDtoToDomain(userDto)
                    Resource.Success(user)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Registration failed: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }

    override suspend fun storeAuthToken(token: String) {
        withContext(Dispatchers.IO) {
            // Store in EncryptedSharedPreferences (primary storage used by AuthInterceptor)
            encryptedPrefs.edit().putString(AUTH_TOKEN_KEY, token).apply()
            
            // Also store in DataStore for consistency
            authDataStore.saveAuthToken(token)
        }
    }

    override fun getAuthTokenSync(): String? {
        // Primary source is EncryptedSharedPreferences since AuthInterceptor uses it
        return encryptedPrefs.getString(AUTH_TOKEN_KEY, null)
    }

    override suspend fun clearAuthToken() {
        withContext(Dispatchers.IO) {
            // Clear from both storage mechanisms
            encryptedPrefs.edit().remove(AUTH_TOKEN_KEY).apply()
            authDataStore.clearAuthToken()
        }
    }

    override suspend fun logout() {
        withContext(Dispatchers.IO) {
            clearAuthToken()
        }
    }
    
    // Helper method to map UserDto to User domain model
    private fun mapUserDtoToDomain(userDto: Any): User {
        // Implementation of mapping from DTO to Domain model
        return User(
            id = 1, // Replace with actual mapping
            username = "user", // Replace with actual mapping
            displayName = null, // Replace with actual mapping when available
            email = "email@example.com", // Replace with actual mapping
            profilePictureUrl = null // Replace with actual mapping when available
        )
    }
} 