package com.example.ptchampion.domain.repository

import org.openapitools.client.models.User
import org.openapitools.client.models.UserProfile
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.Flow

interface UserProfileRepository {
    suspend fun getUserProfile(): Resource<UserProfile>
    suspend fun updateUserProfile(userProfile: UserProfile): Resource<UserProfile>
    fun getUserProfileStream(): Flow<UserProfile?>
    suspend fun cacheUserProfile(userProfile: UserProfile)
    suspend fun clearUserProfileCache()
} 