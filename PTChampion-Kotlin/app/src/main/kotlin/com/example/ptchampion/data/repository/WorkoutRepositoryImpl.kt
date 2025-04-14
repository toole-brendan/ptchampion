package com.example.ptchampion.data.repository

import com.example.ptchampion.data.network.WorkoutApiService
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.util.Resource
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse
import com.example.ptchampion.domain.model.WorkoutSession

@Singleton
class WorkoutRepositoryImpl @Inject constructor(
    private val workoutApiService: WorkoutApiService
) : WorkoutRepository {

    override suspend fun saveWorkout(request: SaveWorkoutRequest): Resource<WorkoutResponse> {
        return try {
            val response = workoutApiService.saveWorkout(request)
            if (response.isSuccessful) {
                response.body()?.let {
                    Resource.Success(it)
                } ?: Resource.Error("API returned successful but empty body")
            } else {
                Resource.Error("API Error: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred: ${e.message}")
        }
    }

    override suspend fun getExercises(): Resource<List<ExerciseResponse>> {
        return try {
            val response = workoutApiService.getExercises()
            if (response.isSuccessful) {
                response.body()?.let {
                    Resource.Success(it)
                } ?: Resource.Error("API returned successful but empty body for exercises")
            } else {
                Resource.Error("API Error fetching exercises: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error fetching exercises: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error fetching exercises: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred fetching exercises: ${e.message}")
        }
    }

    override suspend fun getWorkoutHistory(page: Int, pageSize: Int): Resource<PaginatedWorkoutResponse> {
        return try {
            val response = workoutApiService.getWorkoutHistory(page, pageSize)
            if (response.isSuccessful) {
                response.body()?.let {
                    Resource.Success(it)
                } ?: Resource.Error("API returned successful but empty body for workout history")
            } else {
                Resource.Error("API Error fetching history: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error fetching history: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error fetching history: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred fetching history: ${e.message}")
        }
    }

    override suspend fun getWorkoutById(workoutId: String): Resource<WorkoutResponse> {
        return try {
            val response = workoutApiService.getWorkoutById(workoutId)
            if (response.isSuccessful) {
                response.body()?.let {
                    Resource.Success(it)
                } ?: Resource.Error("API returned successful but empty body for workout ID: $workoutId")
            } else {
                Resource.Error("API Error fetching workout $workoutId: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error fetching workout $workoutId: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error fetching workout $workoutId: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred fetching workout $workoutId: ${e.message}")
        }
    }
} 