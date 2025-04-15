package com.example.ptchampion.domain.repository

import androidx.paging.PagingData
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.domain.util.Resource
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse
import com.example.ptchampion.domain.model.WorkoutSession
import kotlinx.coroutines.flow.Flow

interface WorkoutRepository {
    /**
     * Saves a completed workout session to the backend.
     *
     * @param request The workout data to save.
     * @return A Resource indicating success (with the created WorkoutResponse) or failure.
     */
    suspend fun saveWorkout(request: SaveWorkoutRequest): Resource<WorkoutResponse>

    /**
     * Fetches the list of available exercises from the backend.
     *
     * @return A Resource containing the list of exercises or an error.
     */
    suspend fun getExercises(): Resource<List<ExerciseResponse>>

    /**
     * Fetches the workout history for the current user, paginated.
     *
     * @param page The page number to fetch.
     * @param pageSize The number of items per page.
     * @return A Resource containing the paginated workout history or an error.
     */
    // suspend fun getWorkoutHistory(page: Int, pageSize: Int): Resource<PaginatedWorkoutResponse> // Removed old signature
    fun getWorkoutHistoryStream(): Flow<PagingData<WorkoutSession>> // New Paging 3 signature

    /**
     * Fetches a specific workout by its ID.
     *
     * @param workoutId The ID of the workout to fetch.
     * @return A Resource containing the workout details or an error.
     */
    suspend fun getWorkoutById(workoutId: String): Resource<WorkoutResponse>
} 