package com.example.ptchampion.data.network

import com.example.ptchampion.data.network.dto.GlobalLeaderboardEntryDto
import com.example.ptchampion.data.network.dto.LocalLeaderboardEntryDto
import com.example.ptchampion.data.network.dto.PaginatedWorkoutsResponseDto
import com.example.ptchampion.data.network.dto.WorkoutResponseDto
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.GET
import retrofit2.http.Query
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.UpdateLocationRequest
import retrofit2.http.PUT
import retrofit2.http.Path

interface WorkoutApiService {
    @POST("api/v1/workouts") // Matches the backend route
    suspend fun saveWorkout(@Body workoutRequest: SaveWorkoutRequest): Response<WorkoutResponseDto>

    @GET("api/v1/exercises") // Backend endpoint for listing exercises
    suspend fun getExercises(): Response<List<ExerciseResponse>>

    @GET("api/v1/workouts") // Endpoint for workout history
    suspend fun getWorkoutHistory(
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): Response<PaginatedWorkoutsResponseDto>

    @PUT("api/v1/profile/location") // Endpoint for updating location
    suspend fun updateUserLocation(@Body locationRequest: UpdateLocationRequest): Response<Unit> // Expecting 200 OK No Content

    @GET("api/v1/leaderboards/local") // Endpoint for local leaderboard
    suspend fun getLocalLeaderboard(
        @Query("exercise_id") exerciseId: Int,
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius_meters") radiusMeters: Double? // Optional
    ): Response<List<LocalLeaderboardEntryDto>> // Use DTO

    @GET("/api/v1/workouts/{workoutId}")
    suspend fun getWorkoutById(
        @Path("workoutId") workoutId: String
    ): Response<WorkoutResponseDto>

    @GET("api/v1/leaderboard/{exerciseType}") // Path from OpenAPI
    suspend fun getGlobalLeaderboard(
        @Path("exerciseType") exerciseType: String,
        @Query("limit") limit: Int? = null // Optional limit
    ): Response<List<GlobalLeaderboardEntryDto>> // Use DTO
} 