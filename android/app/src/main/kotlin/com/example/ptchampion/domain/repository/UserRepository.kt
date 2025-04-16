package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow
import com.example.ptchampion.domain.model.UpdateLocationRequest

/**
 * Repository for accessing and managing user-related data (profile, etc.).
 * Authentication logic (login, register, token handling) is handled by AuthRepository.
 */
interface UserRepository {

    /**
     * Provides a flow of the currently logged-in user's profile data.
     * Emits null if no user is logged in or data is not available.
     */
    fun getCurrentUserFlow(): Flow<User?>

    /**
     * Updates the user's profile information.
     */
    suspend fun updateProfile(
        displayName: String? = null, // Allow nullable updates
        profilePictureUrl: String? = null,
        location: String? = null,
        latitude: Double? = null,
        longitude: Double? = null
    ): Resource<User>

    /**
     * Updates the user's last known location.
     */
    suspend fun updateUserLocation(request: UpdateLocationRequest): Resource<Unit>

    /**
     * Provides a flow that emits the currently logged-in user's profile information.
     * This might observe local storage or make periodic checks.
     */
    // fun getUserProfileFlow(): Flow<Resource<User>> // TODO: Implement later

    // TODO: Add other user-related functions (e.g., getProfile, updateProfile)
} 