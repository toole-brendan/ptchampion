package com.example.ptchampion.data.service

import com.example.ptchampion.data.network.dto.UpdateUserRequestDto
import com.example.ptchampion.data.network.dto.UserDto
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH

interface UserApiService {

    // Although not explicitly in the current openapi.yaml, a GET endpoint is usually needed.
    // If it exists (or will exist), define it here.
    // @GET("users/me")
    // suspend fun getUserProfile(): Response<UserDto>

    @PATCH("users/me")
    suspend fun updateUserProfile(@Body updateUserRequest: UpdateUserRequestDto): Response<UserDto>

    // TODO: Add other user-related endpoints if needed (e.g., delete account)
}
