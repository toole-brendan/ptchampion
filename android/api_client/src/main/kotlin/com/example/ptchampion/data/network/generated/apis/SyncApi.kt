package com.example.ptchampion.data.network.generated.apis

import retrofit2.Call
import retrofit2.http.GET
import retrofit2.http.POST

interface SyncApi {
    
    @GET("sync")
    fun syncGet(): Call<Any> // Placeholder, replace with actual models as needed
    
    @POST("sync")
    fun syncPost(): Call<Any> // Placeholder, replace with actual models as needed
} 