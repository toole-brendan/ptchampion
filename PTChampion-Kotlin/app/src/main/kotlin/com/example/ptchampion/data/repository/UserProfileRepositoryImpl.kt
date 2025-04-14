package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.UserProfileRepository
import org.openapitools.client.apis.UsersApi
import org.openapitools.client.models.User
import org.openapitools.client.models.UserProfile
import org.openapitools.client.models.UpdateUserRequest
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import java.math.BigDecimal
import java.net.URI
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserProfileRepositoryImpl @Inject constructor(
    private val api: UsersApi
) : UserProfileRepository {

    private val _userProfileFlow = MutableStateFlow<UserProfile?>(null)

    override suspend fun getUserProfile(): Resource<UserProfile> {
        return withContext(Dispatchers.IO) {
            try {
                // Since there's no direct endpoint to get user profile, we'll use the response from updating with empty values
                val emptyRequest = UpdateUserRequest()
                val userResponse = api.usersMePatch(emptyRequest).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
                
                // Convert User to UserProfile
                val userProfile = convertUserToUserProfile(userResponse)
                cacheUserProfile(userProfile)
                Resource.Success(userProfile)
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
                val userResponse = api.usersMePatch(updateRequest).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
                
                // Convert User to UserProfile
                val updatedProfile = convertUserToUserProfile(userResponse)
                cacheUserProfile(updatedProfile)
                Resource.Success(updatedProfile)
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

    private fun convertUserToUserProfile(user: User): UserProfile {
        return UserProfile(
            id = user.id,
            username = user.username,
            displayName = user.displayName ?: "",
            profilePictureUrl = user.profilePictureUrl?.toString() ?: "",
            location = user.location ?: "",
            latitude = user.latitude?.toString(),
            longitude = user.longitude?.toString()
        )
    }

    private fun createUpdateRequestFromProfile(profile: UserProfile): UpdateUserRequest {
        val profileUri = try {
            if (profile.profilePictureUrl.isNotBlank()) URI.create(profile.profilePictureUrl) else null
        } catch (e: IllegalArgumentException) {
            null
        }

        return UpdateUserRequest(
            username = profile.username,
            displayName = profile.displayName,
            profilePictureUrl = profileUri,
            location = profile.location,
            latitude = profile.latitude?.toDoubleOrNull()?.toBigDecimal(),
            longitude = profile.longitude?.toDoubleOrNull()?.toBigDecimal()
        )
    }
} 