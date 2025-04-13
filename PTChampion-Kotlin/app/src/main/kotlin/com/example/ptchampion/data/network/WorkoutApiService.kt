package com.example.ptchampion.data.network

import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.model.WorkoutResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.GET
import retrofit2.http.Query
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse
import com.example.ptchampion.domain.model.UpdateLocationRequest
import com.example.ptchampion.domain.model.LocalLeaderboardEntry
import retrofit2.http.PUT

interface WorkoutApiService {
    @POST("api/v1/workouts") // Matches the backend route
    suspend fun saveWorkout(@Body workoutRequest: SaveWorkoutRequest): Response<WorkoutResponse>

    @GET("api/v1/exercises") // Backend endpoint for listing exercises
    suspend fun getExercises(): Response<List<ExerciseResponse>>

    @GET("api/v1/workouts") // New endpoint for workout history
    suspend fun getWorkoutHistory(
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): Response<PaginatedWorkoutResponse> // Use the Paginated response type

    @PUT("api/v1/profile/location") // Endpoint for updating location
    suspend fun updateUserLocation(@Body locationRequest: UpdateLocationRequest): Response<Unit> // Expecting 200 OK No Content

    @GET("api/v1/leaderboards/local") // Endpoint for local leaderboard
    suspend fun getLocalLeaderboard(
        @Query("exercise_id") exerciseId: Int,
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius_meters") radiusMeters: Double? // Optional
    ): Response<List<LocalLeaderboardEntry>> // Expecting a list of entries
} 