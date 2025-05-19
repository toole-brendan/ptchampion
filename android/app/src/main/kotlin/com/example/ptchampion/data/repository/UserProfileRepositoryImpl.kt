package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.UserProfileRepository
import com.example.ptchampion.data.service.UserApiService
import com.example.ptchampion.data.network.dto.UserDto
import com.example.ptchampion.data.network.dto.UpdateUserRequestDto
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserProfileRepositoryImpl @Inject constructor(
    private val userApiService: UserApiService
) : UserProfileRepository {

    private val _userProfileFlow = MutableStateFlow<UserProfile?>(null)

    override suspend fun getUserProfile(): Resource<UserProfile> {
        return withContext(Dispatchers.IO) {
            try {
                // Get user profile from API
                val response = userApiService.getCurrentUser()
                
                if (response.isSuccessful && response.body() != null) {
                    val userDto = response.body()!!
                    // Convert UserDto to UserProfile
                    val userProfile = convertUserToUserProfile(userDto)
                    cacheUserProfile(userProfile)
                    Resource.Success(userProfile)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Failed to fetch profile: ${response.code()}"
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

    override suspend fun updateUserProfile(userProfile: UserProfile): Resource<UserProfile> {
        return withContext(Dispatchers.IO) {
            try {
                val updateRequest = createUpdateRequestFromProfile(userProfile)
                val response = userApiService.updateUserProfile(updateRequest)
                
                if (response.isSuccessful && response.body() != null) {
                    val userDto = response.body()!!
                    // Convert UserDto to UserProfile
                    val updatedProfile = convertUserToUserProfile(userDto)
                    cacheUserProfile(updatedProfile)
                    Resource.Success(updatedProfile)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Failed to update profile: ${response.code()}"
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

    override fun getUserProfileStream(): Flow<UserProfile?> {
        return _userProfileFlow.asStateFlow()
    }

    override suspend fun cacheUserProfile(userProfile: UserProfile) {
        _userProfileFlow.emit(userProfile)
    }

    override suspend fun clearUserProfileCache() {
        _userProfileFlow.emit(null)
    }

    private fun convertUserToUserProfile(userDto: UserDto): UserProfile {
        return UserProfile(
            id = userDto.id,
            username = userDto.username,
            displayName = userDto.displayName,
            email = null // Email not available in the DTO
        )
    }

    private fun createUpdateRequestFromProfile(profile: UserProfile): UpdateUserRequestDto {
        return UpdateUserRequestDto(
            displayName = profile.displayName
            // Note: Other fields are not present in UserProfile model
        )
    }
} 