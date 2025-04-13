package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.Flow
import com.example.ptchampion.domain.model.UpdateLocationRequest

/**
 * Repository interface for user-related data operations.
 */
interface UserRepository {
    // Flow for observing user profile changes (e.g., from local cache)
    fun getUserProfileFlow(): Flow<Resource<UserProfile>>

    // Suspend function for fetching/refreshing profile from remote source
    suspend fun refreshUserProfile(): Resource<Unit>

    /**
     * Updates the user's last known location on the backend.
     *
     * @param request The location data to update.
     * @return A Resource indicating success or failure.
     */
    suspend fun updateUserLocation(request: UpdateLocationRequest): Resource<Unit>

    // TODO: Add other user-related functions (e.g., getProfile, updateProfile)
} 