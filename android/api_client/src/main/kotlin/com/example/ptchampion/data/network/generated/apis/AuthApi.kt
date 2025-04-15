package com.example.ptchampion.data.network.generated.apis

import com.example.ptchampion.data.network.generated.models.InsertUser
import com.example.ptchampion.data.network.generated.models.LoginRequest
import com.example.ptchampion.data.network.generated.models.LoginResponse
import com.example.ptchampion.data.network.generated.models.User
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApi {
    
    @POST("auth/login")
    fun authLoginPost(@Body loginRequest: LoginRequest): Call<LoginResponse>
    
    @POST("auth/register")
    fun authRegisterPost(@Body insertUser: InsertUser): Call<User>
} 