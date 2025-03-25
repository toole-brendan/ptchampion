package com.ptchampion.data.repository

import com.ptchampion.data.api.ApiService
import com.ptchampion.domain.model.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository pattern implementation for handling all data operations
 */
@Singleton
class AppRepository @Inject constructor(
    private val apiService: ApiService
) {
    // Auth operations
    suspend fun login(username: String, password: String): Flow<Result<User>> = flow {
        try {
            val user = apiService.login(LoginRequest(username, password))
            emit(Result.success(user))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun register(username: String, password: String, location: String? = null,
                        latitude: Double? = null, longitude: Double? = null): Flow<Result<User>> = flow {
        try {
            val user = apiService.register(RegisterRequest(username, password, location, latitude, longitude))
            emit(Result.success(user))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun logout(): Flow<Result<Unit>> = flow {
        try {
            val result = apiService.logout()
            emit(Result.success(result))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getCurrentUser(): Flow<Result<User>> = flow {
        try {
            val user = apiService.getCurrentUser()
            emit(Result.success(user))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun updateUserLocation(latitude: Double, longitude: Double): Flow<Result<User>> = flow {
        try {
            val locationData = mapOf("latitude" to latitude, "longitude" to longitude)
            val user = apiService.updateUserLocation(locationData)
            emit(Result.success(user))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // Exercise operations
    suspend fun getExercises(): Flow<Result<List<Exercise>>> = flow {
        try {
            val exercises = apiService.getExercises()
            emit(Result.success(exercises))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getExerciseById(id: Int): Flow<Result<Exercise>> = flow {
        try {
            val exercise = apiService.getExerciseById(id)
            emit(Result.success(exercise))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // User exercise operations
    suspend fun getUserExercises(): Flow<Result<List<UserExercise>>> = flow {
        try {
            val userExercises = apiService.getUserExercises()
            emit(Result.success(userExercises))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun createUserExercise(exerciseResult: ExerciseResult): Flow<Result<UserExercise>> = flow {
        try {
            val userExercise = apiService.createUserExercise(exerciseResult)
            emit(Result.success(userExercise))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getUserExercisesByType(type: String): Flow<Result<List<UserExercise>>> = flow {
        try {
            val userExercises = apiService.getUserExercisesByType(type)
            emit(Result.success(userExercises))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getLatestUserExercises(): Flow<Result<Map<String, UserExercise>>> = flow {
        try {
            val latestExercises = apiService.getLatestUserExercises()
            emit(Result.success(latestExercises))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // Leaderboard operations
    suspend fun getGlobalLeaderboard(): Flow<Result<List<LeaderboardEntry>>> = flow {
        try {
            val leaderboard = apiService.getGlobalLeaderboard()
            emit(Result.success(leaderboard))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int = 5): 
        Flow<Result<List<LeaderboardEntry>>> = flow {
        try {
            val leaderboard = apiService.getLocalLeaderboard(latitude, longitude, radiusMiles)
            emit(Result.success(leaderboard))
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
}