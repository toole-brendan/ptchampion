package com.example.ptchampion.data.repository

import com.example.ptchampion.data.network.WorkoutApiService
import com.example.ptchampion.data.network.mapper.toLeaderboardEntry
import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.util.Resource
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LeaderboardRepositoryImpl @Inject constructor(
    private val workoutApiService: WorkoutApiService
) : LeaderboardRepository {

    override suspend fun getGlobalLeaderboard(exerciseType: String, limit: Int): Resource<List<LeaderboardEntry>> {
        return try {
            val response = workoutApiService.getGlobalLeaderboard(exerciseType, limit)
            if (response.isSuccessful) {
                val dtoList = response.body()
                if (dtoList != null) {
                    val domainEntries = dtoList.mapIndexed { index, dto ->
                        dto.toLeaderboardEntry(rank = index + 1)
                    }
                    Resource.Success(domainEntries)
                } else {
                    Resource.Error("API returned successful but empty body for global leaderboard")
                }
            } else {
                Resource.Error("API Error fetching global leaderboard: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error fetching global leaderboard: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error fetching global leaderboard: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred fetching global leaderboard: ${e.message}")
        }
    }

    override suspend fun getLocalLeaderboard(
        exerciseId: Int,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double?,
        limit: Int
    ): Resource<List<LeaderboardEntry>> {
        return try {
            val response = workoutApiService.getLocalLeaderboard(exerciseId, latitude, longitude, radiusMeters)
            if (response.isSuccessful) {
                val dtoList = response.body()
                if (dtoList != null) {
                    val domainEntries = dtoList.mapIndexed { index, dto ->
                        dto.toLeaderboardEntry(rank = index + 1)
                    }
                    Resource.Success(domainEntries.take(limit))
                } else {
                    Resource.Error("API returned successful but empty body for local leaderboard")
                }
            } else {
                Resource.Error("API Error fetching local leaderboard: ${response.code()} ${response.message()}")
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error fetching local leaderboard: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error fetching local leaderboard: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred fetching local leaderboard: ${e.message}")
        }
    }
} 