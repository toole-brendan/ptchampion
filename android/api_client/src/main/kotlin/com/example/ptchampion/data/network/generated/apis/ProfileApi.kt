package com.example.ptchampion.data.network.generated.apis

import com.example.ptchampion.data.network.generated.models.UserProfile
import retrofit2.Call
import retrofit2.http.GET

interface ProfileApi {
    
    @GET("profile")
    fun profileGet(): Call<UserProfile>
} 