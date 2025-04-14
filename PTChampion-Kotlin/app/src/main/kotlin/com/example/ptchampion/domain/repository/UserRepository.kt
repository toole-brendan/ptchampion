package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.User
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.Flow
import com.example.ptchampion.domain.model.UpdateLocationRequest
import com.example.ptchampion.domain.util.Resource as DomainResource

/**
 * Interface defining operations for accessing and manipulating user data.
 */
interface UserRepository {

    /**
     * Attempts to log in a user with the given credentials.
     * @return A Resource wrapping the logged-in User on success, or an error message on failure.
     */
    suspend fun login(username: String, password: String): DomainResource<User>

    /**
     * Attempts to register a new user.
     * @return A Resource indicating success (potentially with the new User) or an error message.
     */
    suspend fun register(
        username: String,
        password: String,
        displayName: String?,
        profilePictureUrl: String?,
        location: String?,
        latitude: String?,
        longitude: String?
    ): DomainResource<User> // API returns created User on success (201)

    /**
     * Logs out the current user by clearing their session data (e.g., auth token).
     */
    suspend fun logout()

    /**
     * Provides a flow that emits the currently logged-in user's profile information.
     * This might observe local storage or make periodic checks.
     */
    // fun getUserProfileFlow(): Flow<Resource<User>> // TODO: Implement later

    /**
     * Provides a flow that emits the currently logged-in user's profile information.
     * Returns null if no user is logged in or data is unavailable.
     */
    fun getCurrentUserFlow(): Flow<User?>

    /**
     * Updates the current user's profile information on the backend.
     * @param displayName New display name (optional)
     * @param profilePictureUrl New profile picture URL (optional)
     * @param location New location string (optional)
     * @param latitude New latitude (optional)
     * @param longitude New longitude (optional)
     * @return A Resource wrapping the updated User on success, or an error message.
     */
    suspend fun updateProfile(
        displayName: String? = null,
        profilePictureUrl: String? = null,
        location: String? = null,
        latitude: Double? = null,
        longitude: Double? = null
    ): Resource<User>

    /**
     * Updates the user's last known location on the backend.
     *
     * @param request The location data to update.
     * @return A Resource indicating success or failure.
     */
    suspend fun updateUserLocation(request: UpdateLocationRequest): Resource<Unit>

    // TODO: Add other user-related functions (e.g., getProfile, updateProfile)
} 