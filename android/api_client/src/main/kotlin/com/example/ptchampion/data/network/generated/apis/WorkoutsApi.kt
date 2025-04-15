package com.example.ptchampion.data.network.generated.apis

import retrofit2.Call
import retrofit2.http.GET

interface WorkoutsApi {
    
    @GET("workouts")
    fun workoutsGet(): Call<List<Any>> // Placeholder, replace with actual models as needed
} 