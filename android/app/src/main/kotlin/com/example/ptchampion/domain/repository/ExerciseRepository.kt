package com.example.ptchampion.domain.repository

import com.example.ptchampion.domain.model.LoggedExercise
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow

/**
 * Interface defining operations for accessing and manipulating exercise data.
 */
interface ExerciseRepository {

    /**
     * Logs a completed exercise session to the backend.
     * @return A Resource wrapping the logged exercise details on success, or an error message.
     */
    suspend fun logExercise(
        exerciseId: Int,
        reps: Int?,
        duration: Int?,
        distance: Int?,
        notes: String?,
        formScore: Int?,
        completed: Boolean?,
        deviceId: String?
    ): Resource<LoggedExercise>

    // TODO: Define methods for fetching exercise list (if API endpoint becomes available)
    // suspend fun getExerciseDefinitions(): Resource<List<ExerciseDefinition>>

    // TODO: Define methods for fetching exercise history
    // fun getExerciseHistory(page: Int, pageSize: Int): Flow<PagingData<LoggedExercise>> // Example using Paging3
}
