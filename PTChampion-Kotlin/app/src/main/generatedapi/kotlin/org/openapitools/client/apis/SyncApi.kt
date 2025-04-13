package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Call
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.SyncRequest
import org.openapitools.client.models.SyncResponse

interface SyncApi {
    /**
     * POST sync
     * Synchronize client data with the server
     * 
     * Responses:
     *  - 200: Sync successful
     *  - 400: Invalid sync request
     *  - 401: Unauthorized - missing or invalid token
     *  - 500: Internal Server Error during sync
     *
     * @param syncRequest  (optional)
     * @return [Call]<[SyncResponse]>
     */
    @POST("sync")
    fun syncPost(@Body syncRequest: SyncRequest? = null): Call<SyncResponse>

}
