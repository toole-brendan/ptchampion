package com.ptchampion.data.api

import com.ptchampion.domain.model.*
import retrofit2.http.*

interface ApiService {
    // Authentication endpoints
    @POST("api/auth/login")
    suspend fun login(@Body loginRequest: LoginRequest): User

    @POST("api/auth/register")
    suspend fun register(@Body registerRequest: RegisterRequest): User

    @POST("api/auth/logout")
    suspend fun logout(): Unit

    @GET("api/user")
    suspend fun getCurrentUser(): User

    @PATCH("api/user/location")
    suspend fun updateUserLocation(@Body locationData: Map<String, Double>): User

    // Exercise endpoints
    @GET("api/exercises")
    suspend fun getExercises(): List<Exercise>

    @GET("api/exercises/{id}")
    suspend fun getExerciseById(@Path("id") id: Int): Exercise

    // User exercise endpoints
    @GET("api/user-exercises")
    suspend fun getUserExercises(): List<UserExercise>

    @POST("api/user-exercises")
    suspend fun createUserExercise(@Body exerciseResult: ExerciseResult): UserExercise

    @GET("api/user-exercises/type/{type}")
    suspend fun getUserExercisesByType(@Path("type") type: String): List<UserExercise>

    @GET("api/user-exercises/latest/all")
    suspend fun getLatestUserExercises(): Map<String, UserExercise>

    // Leaderboard endpoints
    @GET("api/leaderboard/global")
    suspend fun getGlobalLeaderboard(): List<LeaderboardEntry>

    @GET("api/leaderboard/local")
    suspend fun getLocalLeaderboard(@Query("latitude") latitude: Double, 
                                   @Query("longitude") longitude: Double,
                                   @Query("radiusMiles") radiusMiles: Int = 5): List<LeaderboardEntry>
}