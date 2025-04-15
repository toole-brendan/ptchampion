package com.example.ptchampion.data.service

import com.example.ptchampion.data.network.dto.UpdateUserRequestDto
import com.example.ptchampion.data.network.dto.UserDto
import com.example.ptchampion.data.network.dto.UserProfileDto
import com.example.ptchampion.domain.model.UpdateLocationRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path

interface UserApiService {

    // Although not explicitly in the current openapi.yaml, a GET endpoint is usually needed.
    // If it exists (or will exist), define it here.
    // @GET("users/me")
    // suspend fun getUserProfile(): Response<UserDto>

    @GET("users/me")
    suspend fun getCurrentUser(): Response<UserDto>

    @PATCH("users/me")
    suspend fun updateUserProfile(@Body updateRequest: UpdateUserRequestDto): Response<UserDto>

    @POST("users/location")
    suspend fun updateUserLocation(@Body request: UpdateLocationRequest): Response<Unit>

    @GET("users/{userId}")
    suspend fun getUserById(@Path("userId") userId: Int): Response<UserDto>

    // TODO: Add other user-related endpoints if needed (e.g., delete account)
}
