package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Call
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.UpdateUserRequest
import org.openapitools.client.models.User

interface UsersApi {
    /**
     * PATCH users/me
     * Update current user profile
     * 
     * Responses:
     *  - 200: Profile updated successfully
     *  - 400: Invalid input
     *  - 401: Unauthorized - missing or invalid token
     *  - 409: Username already taken
     *  - 500: Internal Server Error
     *
     * @param updateUserRequest  (optional)
     * @return [Call]<[User]>
     */
    @PATCH("users/me")
    fun usersMePatch(@Body updateUserRequest: UpdateUserRequest? = null): Call<User>

}
