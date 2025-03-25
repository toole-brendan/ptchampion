package com.ptchampion.data.api

import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.LeaderboardEntry
import com.ptchampion.domain.model.User
import com.ptchampion.domain.model.UserExercise
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Headers
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
 * Auth response model
 */
data class AuthResponse(
    val user: User,
    val token: String,
    val expiresIn: String
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
    @Headers("X-Client-Platform: mobile")
    @POST("api/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>
    
    @Headers("X-Client-Platform: mobile")
    @POST("api/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>
    
    @GET("api/validate-token")
    suspend fun validateToken(@Header("Authorization") authHeader: String): Response<User>
    
    @GET("api/user")
    suspend fun getCurrentUser(@Header("Authorization") authHeader: String): Response<User>
    
    @POST("api/logout")
    suspend fun logout(): Response<Unit>
    
    // User endpoints
    @POST("api/user/location")
    suspend fun updateUserLocation(
        @Header("Authorization") authHeader: String,
        @Body request: UpdateLocationRequest
    ): Response<User>
    
    // Exercise endpoints (public, no auth needed)
    @GET("api/exercises")
    suspend fun getExercises(): Response<List<Exercise>>
    
    @GET("api/exercises/{id}")
    suspend fun getExerciseById(@Path("id") id: Int): Response<Exercise>
    
    // User Exercise endpoints (protected)
    @GET("api/user-exercises")
    suspend fun getUserExercises(@Header("Authorization") authHeader: String): Response<List<UserExercise>>
    
    @GET("api/user-exercises/{type}")
    suspend fun getUserExercisesByType(
        @Header("Authorization") authHeader: String,
        @Path("type") type: String
    ): Response<List<UserExercise>>
    
    @GET("api/user-exercises/latest/all")
    suspend fun getLatestUserExercises(@Header("Authorization") authHeader: String): Response<Map<String, UserExercise>>
    
    @POST("api/user-exercises")
    suspend fun createUserExercise(
        @Header("Authorization") authHeader: String,
        @Body request: CreateUserExerciseRequest
    ): Response<UserExercise>
    
    // Leaderboard endpoints (public)
    @GET("api/leaderboard/global")
    suspend fun getGlobalLeaderboard(): Response<List<LeaderboardEntry>>
    
    @GET("api/leaderboard/local")
    suspend fun getLocalLeaderboard(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("radius") radiusMiles: Int = 5
    ): Response<List<LeaderboardEntry>>
    
    // Health check endpoint
    @GET("api/health")
    suspend fun checkHealth(): Response<Map<String, Any>>
}