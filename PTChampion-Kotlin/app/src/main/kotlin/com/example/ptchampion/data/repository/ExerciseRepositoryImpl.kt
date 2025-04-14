package com.example.ptchampion.data.repository

import com.example.ptchampion.data.network.dto.LogExerciseRequestDto
import com.example.ptchampion.data.network.dto.LogExerciseResponseDto
import com.example.ptchampion.data.service.ExerciseApiService
import com.example.ptchampion.domain.model.LoggedExercise
import com.example.ptchampion.domain.repository.ExerciseRepository
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.datetime.Instant
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ExerciseRepositoryImpl @Inject constructor(
    private val exerciseApiService: ExerciseApiService
) : ExerciseRepository {

    override suspend fun logExercise(
        exerciseId: Int,
        reps: Int?,
        duration: Int?,
        distance: Int?,
        notes: String?,
        formScore: Int?,
        completed: Boolean?,
        deviceId: String?
    ): Resource<LoggedExercise> {
        return withContext(Dispatchers.IO) {
            try {
                val requestDto = LogExerciseRequestDto(
                    exerciseId = exerciseId,
                    reps = reps,
                    duration = duration,
                    distance = distance,
                    notes = notes,
                    formScore = formScore,
                    completed = completed,
                    deviceId = deviceId
                )
                val response = exerciseApiService.logExercise(requestDto)

                if (response.isSuccessful && response.body() != null) {
                    val loggedExerciseDto = response.body()!!
                    val loggedExercise = mapLoggedExerciseDtoToDomain(loggedExerciseDto)
                    Resource.Success(loggedExercise)
                } else {
                    val errorMessage = response.errorBody()?.string() ?: "Failed to log exercise: ${response.code()}"
                    Resource.Error(errorMessage)
                }
            } catch (e: HttpException) {
                Resource.Error("Log exercise failed: Network error (${e.code()})")
            } catch (e: IOException) {
                Resource.Error("Log exercise failed: Network connection error")
            } catch (e: Exception) {
                Resource.Error("Log exercise failed: An unexpected error occurred: ${e.message}")
            }
        }
    }

    // --- Helper Mapper ---
    private fun mapLoggedExerciseDtoToDomain(dto: LogExerciseResponseDto): LoggedExercise {
        return LoggedExercise(
            id = dto.id,
            userId = dto.userId,
            exerciseId = dto.exerciseId,
            exerciseName = dto.exerciseName,
            exerciseType = dto.exerciseType,
            reps = dto.reps,
            timeInSeconds = dto.timeInSeconds,
            distance = dto.distance,
            notes = dto.notes,
            grade = dto.grade,
            createdAt = try {
                Instant.parse(dto.createdAt) // Assumes ISO 8601 format
            } catch (e: Exception) {
                // Handle parse error, perhaps log it and return a default/current time
                println("Error parsing date: ${dto.createdAt} - ${e.message}")
                Instant.DISTANT_PAST // Or kotlinx.datetime.Clock.System.now()
            }
        )
    }

    // TODO: Implement other ExerciseRepository methods
}
