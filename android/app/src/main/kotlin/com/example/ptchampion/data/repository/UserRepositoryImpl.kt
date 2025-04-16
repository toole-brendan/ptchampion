package com.example.ptchampion.data.repository

import com.example.ptchampion.data.network.dto.UserDto
import com.example.ptchampion.data.network.dto.UpdateUserRequestDto
import com.example.ptchampion.data.service.UserApiService
import com.example.ptchampion.domain.model.UpdateLocationRequest
import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.repository.AuthRepository
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
    private val authRepository: AuthRepository,
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