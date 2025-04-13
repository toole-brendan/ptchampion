package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Call
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.LogExerciseRequest
import org.openapitools.client.models.LogExerciseResponse
import org.openapitools.client.models.PaginatedExerciseHistoryResponse

interface ExercisesApi {
    /**
     * GET exercises
     * Get exercise history for the current user
     * 
     * Responses:
     *  - 200: Exercise history retrieved successfully
     *  - 401: Unauthorized - missing or invalid token
     *  - 500: Internal Server Error
     *
     * @param page Page number for pagination (optional, default to 1)
     * @param pageSize Number of items per page (optional, default to 20)
     * @return [Call]<[PaginatedExerciseHistoryResponse]>
     */
    @GET("exercises")
    fun exercisesGet(@Query("page") page: kotlin.Int? = 1, @Query("pageSize") pageSize: kotlin.Int? = 20): Call<PaginatedExerciseHistoryResponse>

    /**
     * POST exercises
     * Log a completed exercise
     * 
     * Responses:
     *  - 201: Exercise logged successfully
     *  - 400: Invalid input or missing required metrics for exercise type
     *  - 401: Unauthorized - missing or invalid token
     *  - 500: Internal Server Error
     *
     * @param logExerciseRequest  (optional)
     * @return [Call]<[LogExerciseResponse]>
     */
    @POST("exercises")
    fun exercisesPost(@Body logExerciseRequest: LogExerciseRequest? = null): Call<LogExerciseResponse>

}
