package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.util.Resource
import org.openapitools.client.apis.LeaderboardApi
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LeaderboardRepositoryImpl @Inject constructor(
    private val leaderboardApi: LeaderboardApi
) : LeaderboardRepository {

    override suspend fun getLeaderboard(exerciseType: String, limit: Int): Resource<List<LeaderboardEntry>> {
        return try {
            // Use execute() as the generated API returns Call<T>
            val response = leaderboardApi.leaderboardExerciseTypeGet(exerciseType, limit).execute()
            if (response.isSuccessful) {
                val leaderboardResponse = response.body()
                if (leaderboardResponse != null) {
                    // Map the generated API model to the domain model
                    val domainEntries = leaderboardResponse.map {
                        LeaderboardEntry(
                            username = it.username,
                            displayName = it.displayName,
                            score = it.bestGrade
                        )
                    }
                    Resource.Success(domainEntries)
                } else {
                    Resource.Error("API returned successful but empty body")
                }
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
} 