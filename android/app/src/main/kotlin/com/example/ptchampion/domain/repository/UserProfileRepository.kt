package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow

interface UserProfileRepository {
    suspend fun getUserProfile(): Resource<UserProfile>
    suspend fun updateUserProfile(userProfile: UserProfile): Resource<UserProfile>
    fun getUserProfileStream(): Flow<UserProfile?>
    suspend fun cacheUserProfile(userProfile: UserProfile)
    suspend fun clearUserProfileCache()
} 