package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Call
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.PaginatedWorkoutsResponse

interface WorkoutsApi {
    /**
     * GET workouts
     * Get workout history for the current user (tracked sessions)
     * 
     * Responses:
     *  - 200: Workout history retrieved successfully
     *  - 401: Unauthorized - missing or invalid token
     *  - 500: Internal Server Error
     *
     * @param page Page number for pagination (optional, default to 1)
     * @param pageSize Number of items per page (optional, default to 20)
     * @return [Call]<[PaginatedWorkoutsResponse]>
     */
    @GET("workouts")
    fun handleGetWorkouts(@Query("page") page: kotlin.Int? = 1, @Query("pageSize") pageSize: kotlin.Int? = 20): Call<PaginatedWorkoutsResponse>

}
