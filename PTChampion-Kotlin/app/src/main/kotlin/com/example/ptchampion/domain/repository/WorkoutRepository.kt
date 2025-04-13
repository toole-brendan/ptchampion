package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.util.Resource
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse

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
    suspend fun getWorkoutHistory(page: Int, pageSize: Int): Resource<PaginatedWorkoutResponse>
} 