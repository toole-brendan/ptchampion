package com.example.ptchampion.data.service

import com.example.ptchampion.data.network.dto.LoginRequestDto
import com.example.ptchampion.data.network.dto.LoginResponseDto
import com.example.ptchampion.data.network.dto.RegisterRequestDto
import com.example.ptchampion.data.network.dto.UserDto
import retrofit2.Response // Use Response for detailed status codes
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApiService {

    @POST("auth/login") // Path relative to base URL
    suspend fun login(@Body loginRequest: LoginRequestDto): Response<LoginResponseDto>

    @POST("auth/register")
    suspend fun register(@Body registerRequest: RegisterRequestDto): Response<UserDto>
}
