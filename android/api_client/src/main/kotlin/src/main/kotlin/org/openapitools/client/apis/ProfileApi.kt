package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.HandleUpdateUserLocationRequest

interface ProfileApi {
    /**
     * PUT profile/location
     * Update current user&#39;s last known location
     * 
     * Responses:
     *  - 200: Location updated successfully
     *  - 400: Invalid input (latitude/longitude format incorrect)
     *  - 401: Unauthorized - missing or invalid token
     *  - 500: Internal Server Error updating location
     *
     * @param handleUpdateUserLocationRequest 
     * @return [Unit]
     */
    @PUT("profile/location")
    suspend fun handleUpdateUserLocation(@Body handleUpdateUserLocationRequest: HandleUpdateUserLocationRequest): Response<Unit>

}
