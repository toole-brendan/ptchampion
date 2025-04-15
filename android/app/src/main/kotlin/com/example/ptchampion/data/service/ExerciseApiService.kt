package com.example.ptchampion.data.service

import com.example.ptchampion.data.network.dto.LogExerciseRequestDto
import com.example.ptchampion.data.network.dto.LogExerciseResponseDto
// Import other DTOs if needed (e.g., for GET /exercises)
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.GET
import retrofit2.http.Query

interface ExerciseApiService {

    @POST("exercises")
    suspend fun logExercise(@Body logRequest: LogExerciseRequestDto): Response<LogExerciseResponseDto>

    // TODO: Define GET /exercises for history later
    // @GET("exercises")
    // suspend fun getExerciseHistory(
    //     @Query("page") page: Int? = null,
    //     @Query("pageSize") pageSize: Int? = null
    // ): Response<PaginatedExerciseHistoryResponseDto> // Need to define this DTO

    // TODO: Define GET /workouts if needed for session history

}
