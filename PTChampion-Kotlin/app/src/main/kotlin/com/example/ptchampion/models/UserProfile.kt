package org.openapitools.client.models

/**
 * User profile information used within the app
 */
data class UserProfile(
    val id: Int,
    val username: String,
    val displayName: String,
    val profilePictureUrl: String,
    val location: String,
    val latitude: String?,
    val longitude: String?,
) 