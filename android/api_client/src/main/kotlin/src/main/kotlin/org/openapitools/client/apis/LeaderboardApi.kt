package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.HandleGetLocalLeaderboard200ResponseInner
import org.openapitools.client.models.LeaderboardResponseInner

interface LeaderboardApi {
    /**
     * GET leaderboards/local
     * Get leaderboard filtered by proximity to user location
     * 
     * Responses:
     *  - 200: Local leaderboard retrieved successfully
     *  - 400: Missing or invalid required query parameters
     *  - 500: Internal Server Error retrieving local leaderboard
     *
     * @param exerciseId ID of the exercise to filter leaderboard by
     * @param latitude User&#39;s current latitude
     * @param longitude User&#39;s current longitude
     * @param radiusMeters Search radius in meters (optional, default to 8047.0)
     * @return [kotlin.collections.List<HandleGetLocalLeaderboard200ResponseInner>]
     */
    @GET("leaderboards/local")
    suspend fun handleGetLocalLeaderboard(@Query("exercise_id") exerciseId: kotlin.Int, @Query("latitude") latitude: kotlin.Double, @Query("longitude") longitude: kotlin.Double, @Query("radius_meters") radiusMeters: kotlin.Double? = 8047.0): Response<kotlin.collections.List<HandleGetLocalLeaderboard200ResponseInner>>


    /**
    * enum for parameter exerciseType
    */
    enum class ExerciseTypeLeaderboardExerciseTypeGet(val value: kotlin.String) {
        @Json(name = "pushup") pushup("pushup"),
        @Json(name = "pullup") pullup("pullup"),
        @Json(name = "situp") situp("situp"),
        @Json(name = "run") run("run")
    }

    /**
     * GET leaderboard/{exerciseType}
     * Get leaderboard for a specific exercise type
     * 
     * Responses:
     *  - 200: Leaderboard retrieved successfully
     *  - 400: Invalid exercise type
     *  - 500: Internal Server Error
     *
     * @param exerciseType Type of exercise for the leaderboard
     * @param limit Maximum number of leaderboard entries to return (optional, default to 20)
     * @return [kotlin.collections.List<LeaderboardResponseInner>]
     */
    @GET("leaderboard/{exerciseType}")
    suspend fun leaderboardExerciseTypeGet(@Path("exerciseType") exerciseType: kotlin.String, @Query("limit") limit: kotlin.Int? = 20): Response<kotlin.collections.List<LeaderboardResponseInner>>

}
