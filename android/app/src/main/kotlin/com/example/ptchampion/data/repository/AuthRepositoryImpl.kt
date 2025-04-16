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
import dagger.hilt.android.qualifiers.ApplicationContext

@Singleton // Indicate Hilt should provide a single instance
class AuthRepositoryImpl @Inject constructor(
    private val authApiService: AuthApiService,
    @ApplicationContext private val context: Context,
    private val encryptedPrefs: SharedPreferences
) : AuthRepository {

    private companion object {
        const val AUTH_TOKEN_KEY = "auth_token"
    }

    override suspend fun login(loginRequest: LoginRequestDto): Resource<LoginResponseDto> {
        return withContext(Dispatchers.IO) { // Perform network call on IO dispatcher
            try {
                val response = authApiService.login(loginRequest)
                
                if (response.isSuccessful && response.body() != null) {
                    val responseBody = response.body()!!
                    if (responseBody.token != null) {
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
            encryptedPrefs.edit().putString(AUTH_TOKEN_KEY, token).apply()
        }
    }

    override fun getAuthTokenSync(): String? {
        return encryptedPrefs.getString(AUTH_TOKEN_KEY, null)
    }

    override suspend fun clearAuthToken() {
        withContext(Dispatchers.IO) {
            encryptedPrefs.edit().remove(AUTH_TOKEN_KEY).apply()
        }
    }

    override suspend fun logout() {
        withContext(Dispatchers.IO) {
            clearAuthToken()
        }
    }
    
    // Helper method to map UserDto to User domain model
    private fun mapUserDtoToDomain(dto: com.example.ptchampion.data.network.dto.UserDto): User {
        return User(
            id = dto.id,
            username = dto.username,
            displayName = dto.displayName,
            email = null, // If email is not in the DTO
            profilePictureUrl = dto.profilePictureUrl
            // Map other fields as needed
        )
    }
} 