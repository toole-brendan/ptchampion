package com.example.ptchampion.data.repository

import androidx.paging.Pager
import androidx.paging.PagingConfig
import androidx.paging.PagingData
import androidx.paging.PagingSource
import androidx.paging.PagingState
import com.example.ptchampion.data.network.WorkoutApiService
import com.example.ptchampion.data.network.dto.WorkoutResponseDto
import com.example.ptchampion.data.network.mapper.toWorkoutSession
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse
import com.example.ptchampion.domain.model.SaveWorkoutRequest
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.domain.model.WorkoutSession
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.Flow
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WorkoutRepositoryImpl @Inject constructor(
    private val workoutApiService: WorkoutApiService
) : WorkoutRepository {

    override suspend fun saveWorkout(request: SaveWorkoutRequest): Resource<WorkoutResponse> {
        return try {
            val response = workoutApiService.saveWorkout(request)
            if (response.isSuccessful) {
                response.body()?.let { dto ->
                    Resource.Success(WorkoutResponse(
                        id = dto.id,
                        exerciseId = dto.exerciseId,
                        exerciseName = dto.exerciseName,
                        repetitions = dto.repetitions,
                        durationSeconds = dto.durationSeconds,
                        formScore = dto.formScore,
                        grade = dto.grade,
                        completedAt = dto.completedAt,
                        createdAt = dto.createdAt
                    ))
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

    override fun getWorkoutHistoryStream(): Flow<PagingData<WorkoutSession>> {
        return Pager(
            config = PagingConfig(
                pageSize = NETWORK_PAGE_SIZE,
                enablePlaceholders = false
            ),
            pagingSourceFactory = { WorkoutPagingSource(workoutApiService) }
        ).flow
    }

    override suspend fun getWorkoutById(workoutId: String): Resource<WorkoutResponse> {
        return try {
            val response = workoutApiService.getWorkoutById(workoutId)
            if (response.isSuccessful) {
                response.body()?.let { dto ->
                    Resource.Success(WorkoutResponse(
                        id = dto.id,
                        exerciseId = dto.exerciseId,
                        exerciseName = dto.exerciseName,
                        repetitions = dto.repetitions,
                        durationSeconds = dto.durationSeconds,
                        formScore = dto.formScore,
                        grade = dto.grade,
                        completedAt = dto.completedAt,
                        createdAt = dto.createdAt
                    ))
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

    companion object {
        const val NETWORK_PAGE_SIZE = 20
    }
}

private class WorkoutPagingSource(
    private val service: WorkoutApiService
) : PagingSource<Int, WorkoutSession>() {

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, WorkoutSession> {
        val pageIndex = params.key ?: 1
        val pageSize = params.loadSize.coerceAtMost(WorkoutRepositoryImpl.NETWORK_PAGE_SIZE)

        return try {
            val response = service.getWorkoutHistory(page = pageIndex, pageSize = pageSize)

            if (response.isSuccessful) {
                val responseDto = response.body()!!
                val workouts = responseDto.workouts.map { it.toWorkoutSession() }

                val nextKey = if (workouts.isEmpty() || pageIndex * pageSize >= responseDto.totalCount) {
                    null
                } else {
                    pageIndex + 1
                }
                val prevKey = if (pageIndex == 1) {
                    null
                } else {
                    pageIndex - 1
                }

                LoadResult.Page(
                    data = workouts,
                    prevKey = prevKey,
                    nextKey = nextKey
                )
            } else {
                LoadResult.Error(HttpException(response))
            }
        } catch (e: IOException) {
            LoadResult.Error(e)
        } catch (e: HttpException) {
            LoadResult.Error(e)
        } catch (e: Exception) {
            LoadResult.Error(e)
        }
    }

    override fun getRefreshKey(state: PagingState<Int, WorkoutSession>): Int? {
        return state.anchorPosition?.let {
            state.closestPageToPosition(it)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(it)?.nextKey?.minus(1)
        }
    }
} 