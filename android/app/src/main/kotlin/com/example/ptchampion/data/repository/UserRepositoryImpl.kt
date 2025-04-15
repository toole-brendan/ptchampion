package com.example.ptchampion.data.repository

import com.example.ptchampion.data.datastore.AuthDataStore
import com.example.ptchampion.data.datastore.UserPreferencesRepository
import com.example.ptchampion.data.network.dto.LoginRequestDto
import com.example.ptchampion.data.network.dto.RegisterRequestDto
import com.example.ptchampion.data.network.dto.UserDto
import com.example.ptchampion.data.network.dto.UpdateUserRequestDto
import com.example.ptchampion.data.service.AuthApiService
import com.example.ptchampion.data.service.UserApiService
import com.example.ptchampion.domain.model.UpdateLocationRequest
import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepositoryImpl @Inject constructor(
    private val authDataStore: AuthDataStore,
    private val userPreferencesRepository: UserPreferencesRepository,
    private val authApiService: AuthApiService,
    private val userApiService: UserApiService
) : UserRepository {

    // Flow to hold the current user state in memory
    private val _currentUserFlow = MutableStateFlow<User?>(null)

    override fun getCurrentUserFlow(): Flow<User?> = _currentUserFlow.asStateFlow()

    override suspend fun updateUserLocation(request: UpdateLocationRequest): Resource<Unit> {
         // No need to check auth token here, as it should be added by an Authenticator/Interceptor
         return try {
            // Use userApiService instead of usersApi
            val response = userApiService.updateUserLocation(request)
            // Assuming the response indicates success/failure without needing specific body
            if (response.isSuccessful) {
                Resource.Success(Unit)
            } else {
                Resource.Error("API Error updating location: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error updating location: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error updating location: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred updating location: ${e.message}")
        }
    }

    override suspend fun login(username: String, password: String): Resource<User> {
        return withContext(Dispatchers.IO) {
            try {
                val requestDto = LoginRequestDto(username = username, password = password)
                val response = authApiService.login(requestDto)

                if (response.isSuccessful && response.body() != null) {
                    val loginResponse = response.body()!!
                    userPreferencesRepository.saveAuthToken(loginResponse.token)
                    val user = mapUserDtoToDomain(loginResponse.user)
                    // Update the in-memory flow with the logged-in user
                    _currentUserFlow.update { user }
                    Resource.Success(user)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Login failed: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error("Login failed: Network error (${e.code()})")
            } catch (e: IOException) {
                Resource.Error("Login failed: Network connection error")
            } catch (e: Exception) {
                Resource.Error("Login failed: An unexpected error occurred: ${e.message}")
            }
        }
    }

    override suspend fun register(
        username: String,
        password: String,
        displayName: String?,
        profilePictureUrl: String?,
        location: String?,
        latitude: String?,
        longitude: String?
    ): Resource<User> {
        return withContext(Dispatchers.IO) {
            try {
                val requestDto = RegisterRequestDto(
                    username = username,
                    password = password,
                    displayName = displayName,
                    profilePictureUrl = profilePictureUrl,
                    location = location,
                    latitude = latitude,
                    longitude = longitude
                )
                val response = authApiService.register(requestDto)

                if (response.isSuccessful && response.body() != null) {
                    // API returns the created User DTO
                    val userDto = response.body()!!
                    val user = mapUserDtoToDomain(userDto)
                    Resource.Success(user) // Indicate success, optionally with the created user
                } else {
                    // Handle specific errors (e.g., 409 Conflict - username exists)
                    val errorMessage = response.errorBody()?.string() ?: "Registration failed: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error("Registration failed: Network error (${e.code()})")
            } catch (e: IOException) {
                Resource.Error("Registration failed: Network connection error")
            } catch (e: Exception) {
                Resource.Error("Registration failed: An unexpected error occurred: ${e.message}")
            }
        }
    }

    override suspend fun logout() {
        withContext(Dispatchers.IO) {
            userPreferencesRepository.clearAuthToken()
            // Clear the in-memory user state
            _currentUserFlow.update { null }
            // Optionally: Call a backend logout endpoint if one exists
        }
    }

    override suspend fun updateProfile(
        displayName: String?,
        profilePictureUrl: String?,
        location: String?,
        latitude: Double?,
        longitude: Double?
    ): Resource<User> {
        // Check if there are any changes to send
        if (displayName == null && profilePictureUrl == null && location == null && latitude == null && longitude == null) {
            // Return current user data if no changes are requested
            val currentUser = _currentUserFlow.value
            return if (currentUser != null) Resource.Success(currentUser) else Resource.Error("No user logged in or no changes requested")
        }

        return withContext(Dispatchers.IO) {
            try {
                val requestDto = UpdateUserRequestDto(
                    displayName = displayName,
                    profilePictureUrl = profilePictureUrl,
                    location = location,
                    latitude = latitude,
                    longitude = longitude
                )
                val response = userApiService.updateUserProfile(requestDto)

                if (response.isSuccessful && response.body() != null) {
                    val updatedUserDto = response.body()!!
                    val updatedUser = mapUserDtoToDomain(updatedUserDto)
                    // Update the in-memory flow
                    _currentUserFlow.update { updatedUser }
                    Resource.Success(updatedUser)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Profile update failed: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error("Profile update failed: Network error (${e.code()})")
            } catch (e: IOException) {
                Resource.Error("Profile update failed: Network connection error")
            } catch (e: Exception) {
                Resource.Error("Profile update failed: An unexpected error occurred: ${e.message}")
            }
        }
    }

    // --- Helper Mapper --- 
    private fun mapUserDtoToDomain(dto: UserDto): User {
        return User(
            id = dto.id,
            username = dto.username,
            displayName = dto.displayName,
            email = null, // TODO: Get email if available from API or another source
            profilePictureUrl = dto.profilePictureUrl
            // Map other fields if necessary
        )
    }
} 