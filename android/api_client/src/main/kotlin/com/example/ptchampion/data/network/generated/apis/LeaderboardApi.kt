package com.example.ptchampion.data.network.generated.apis

import retrofit2.Call
import retrofit2.http.GET

interface LeaderboardApi {
    
    @GET("leaderboard")
    fun leaderboardGet(): Call<List<Any>> // Placeholder, replace with actual models as needed
} 