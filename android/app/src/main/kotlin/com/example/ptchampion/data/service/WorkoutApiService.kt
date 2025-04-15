package com.example.ptchampion.data.service

import retrofit2.http.GET

/**
 * API service interface for workout-related API endpoints.
 * This is a stub implementation that can be expanded with actual endpoints.
 */
interface WorkoutApiService {
    @GET("workouts")
    suspend fun getWorkouts(): List<Any>
} 