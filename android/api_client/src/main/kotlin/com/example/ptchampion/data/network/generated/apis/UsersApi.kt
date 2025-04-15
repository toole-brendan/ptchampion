package com.example.ptchampion.data.network.generated.apis

import com.example.ptchampion.data.network.generated.models.UpdateUserRequest
import com.example.ptchampion.data.network.generated.models.User
import com.example.ptchampion.data.network.generated.models.UserProfile
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.Path

interface UsersApi {
    
    @GET("users/me")
    fun usersMeGet(): Call<User>
    
    @PATCH("users/me")
    fun usersMePatch(@Body updateUserRequest: UpdateUserRequest): Call<User>
    
    @GET("users/{id}")
    fun usersIdGet(@Path("id") id: Int): Call<User>
} 