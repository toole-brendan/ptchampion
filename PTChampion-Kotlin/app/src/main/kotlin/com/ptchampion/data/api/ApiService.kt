package com.ptchampion.data.api

import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.LeaderboardEntry
import com.ptchampion.domain.model.User
import com.ptchampion.domain.model.UserExercise
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

/**
 * Login request model
 */
data class LoginRequest(
    val username: String,
    val password: String
)

/**
 * Register request model
 */
data class RegisterRequest(
    val username: String,
    val password: String
)

/**
 * Update location request model
 */
data class UpdateLocationRequest(
    val latitude: Double,
    val longitude: Double
)

/**
 * Create user exercise request model
 */
data class CreateUserExerciseRequest(
    val exerciseId: Int,
    val type: String,
    val reps: Int? = null,
    val timeInSeconds: Int? = null,
    val distance: Double? = null,
    val score: Int
)

/**
 * API service interface
 */
interface ApiService {
    
    // Auth endpoints
    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<User>
    
    @POST("api/auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<User>
    
    @GET("api/auth/current")
    suspend fun getCurrentUser(): Response<User>
    
    @POST("api/auth/logout")
    suspend fun logout(): Response<Unit>
    
    // User endpoints
    @GET("api/user/{id}")
    suspend fun getUser(@Path("id") id: Int): Response<User>
    
    @POST("api/user/location")
    suspend fun updateUserLocation(@Body request: UpdateLocationRequest): Response<User>
    
    // Exercise endpoints
    @GET("api/exercises")
    suspend fun getExercises(): Response<List<Exercise>>
    
    @GET("api/exercises/{id}")
    suspend fun getExerciseById(@Path("id") id: Int): Response<Exercise>
    
    // User Exercise endpoints
    @GET("api/user-exercises")
    suspend fun getUserExercises(): Response<List<UserExercise>>
    
    @GET("api/user-exercises/type/{type}")
    suspend fun getUserExercisesByType(@Path("type") type: String): Response<List<UserExercise>>
    
    @GET("api/user-exercises/latest")
    suspend fun getLatestUserExercises(): Response<Map<String, UserExercise>>
    
    @POST("api/user-exercises")
    suspend fun createUserExercise(@Body request: CreateUserExerciseRequest): Response<UserExercise>
    
    // Leaderboard endpoints
    @GET("api/leaderboard")
    suspend fun getGlobalLeaderboard(): Response<List<LeaderboardEntry>>
    
    @GET("api/leaderboard/local")
    suspend fun getLocalLeaderboard(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius") radiusMiles: Int = 5
    ): Response<List<LeaderboardEntry>>
}