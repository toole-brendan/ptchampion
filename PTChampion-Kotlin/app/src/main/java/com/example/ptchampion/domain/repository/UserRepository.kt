package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow

interface UserRepository {
    // Flow for observing user profile changes (e.g., from local cache)
    fun getUserProfileFlow(): Flow<Resource<UserProfile>>

    // Suspend function for fetching/refreshing profile from remote source
    suspend fun refreshUserProfile(): Resource<Unit>

    // Potentially add functions for updating user profile later
    // suspend fun updateUserProfile(profile: UserProfile): Resource<Unit>
} 