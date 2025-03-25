package com.ptchampion.data.repository

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.ptchampion.data.api.ApiService
import com.ptchampion.data.api.AuthResponse
import com.ptchampion.data.api.CreateUserExerciseRequest
import com.ptchampion.data.api.LoginRequest
import com.ptchampion.data.api.RegisterRequest
import com.ptchampion.data.api.UpdateLocationRequest
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.LeaderboardEntry
import com.ptchampion.domain.model.Result
import com.ptchampion.domain.model.User
import com.ptchampion.domain.model.UserExercise
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import retrofit2.Response
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for app data operations
 */
@Singleton
class AppRepository @Inject constructor(
    @ApplicationContext context: Context,
    private val apiService: ApiService
) {
    companion object {
        private const val TAG = "AppRepository"
        private const val PREFS_NAME = "pt_champion_prefs"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USERNAME = "username"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_TOKEN_EXPIRY = "auth_token_expiry"
    }
    
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    // Cache of current user
    private var currentUser: User? = null
    
    /**
     * Get the stored auth token
     */
    private fun getAuthToken(): String? {
        return prefs.getString(KEY_AUTH_TOKEN, null)
    }
    
    /**
     * Get the authorization header with Bearer token
     */
    private fun getAuthHeader(): String {
        val token = getAuthToken() ?: ""
        return "Bearer $token"
    }
    
    /**
     * Check API health
     */
    fun checkApiHealth(): Flow<Result<Boolean>> = flow {
        try {
            val response = apiService.checkHealth()
            if (response.isSuccessful) {
                emit(Result.Success(true))
            } else {
                emit(Result.Error(IOException("API health check failed: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "API health check error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Login user with JWT
     */
    fun login(username: String, password: String): Flow<Result<User>> = flow {
        try {
            val response = apiService.login(LoginRequest(username, password))
            if (response.isSuccessful) {
                val authResponse = response.body()!!
                saveUserSession(authResponse.user, authResponse.token, authResponse.expiresIn)
                currentUser = authResponse.user
                emit(Result.Success(authResponse.user))
            } else {
                emit(Result.Error(IOException("Login failed: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Login error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Register new user
     */
    fun register(username: String, password: String): Flow<Result<User>> = flow {
        try {
            val response = apiService.register(RegisterRequest(username, password))
            if (response.isSuccessful) {
                val authResponse = response.body()!!
                saveUserSession(authResponse.user, authResponse.token, authResponse.expiresIn)
                currentUser = authResponse.user
                emit(Result.Success(authResponse.user))
            } else {
                emit(Result.Error(IOException("Registration failed: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Registration error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Validate JWT token
     */
    fun validateToken(): Flow<Result<Boolean>> = flow {
        val token = getAuthToken()
        if (token == null) {
            emit(Result.Success(false))
            return@flow
        }
        
        try {
            val response = apiService.validateToken(getAuthHeader())
            if (response.isSuccessful) {
                // Update cached user
                currentUser = response.body()
                emit(Result.Success(true))
            } else {
                // If 401, clear token as it's invalid
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Success(false))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Token validation error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Logout user
     */
    fun logout(): Flow<Result<Unit>> = flow {
        // Token invalidation mostly happens client-side by clearing token
        clearUserSession()
        currentUser = null
        
        // Notify server (but don't fail if this fails)
        try {
            apiService.logout()
        } catch (e: Exception) {
            Log.e(TAG, "Logout API call error (non-critical)", e)
        }
        
        emit(Result.Success(Unit))
    }
    
    /**
     * Get current user
     */
    fun getCurrentUser(): Flow<Result<User>> = flow {
        // Return cached user if available
        currentUser?.let {
            emit(Result.Success(it))
            return@flow
        }
        
        // Check if we have a token
        if (getAuthToken() == null) {
            emit(Result.Error(IOException("Not authenticated")))
            return@flow
        }
        
        // Otherwise fetch from API
        try {
            val response = apiService.getCurrentUser(getAuthHeader())
            if (response.isSuccessful) {
                val user = response.body()!!
                currentUser = user
                emit(Result.Success(user))
            } else {
                // If 401, clear session as token may be expired
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to get current user: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get current user error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Update user location
     */
    fun updateUserLocation(latitude: Double, longitude: Double): Flow<Result<User>> = flow {
        try {
            val response = apiService.updateUserLocation(
                getAuthHeader(),
                UpdateLocationRequest(latitude, longitude)
            )
            if (response.isSuccessful) {
                val user = response.body()!!
                currentUser = user
                emit(Result.Success(user))
            } else {
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to update location: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Update location error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get all exercises (public endpoint)
     */
    fun getExercises(): Flow<Result<List<Exercise>>> = flow {
        try {
            val response = apiService.getExercises()
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                emit(Result.Error(IOException("Failed to get exercises: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get exercises error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get exercise by ID (public endpoint)
     */
    fun getExerciseById(id: Int): Flow<Result<Exercise>> = flow {
        try {
            val response = apiService.getExerciseById(id)
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                emit(Result.Error(IOException("Failed to get exercise: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get exercise by ID error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get user exercises (protected endpoint)
     */
    fun getUserExercises(): Flow<Result<List<UserExercise>>> = flow {
        try {
            val response = apiService.getUserExercises(getAuthHeader())
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to get user exercises: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get user exercises error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get user exercises by type (protected endpoint)
     */
    fun getUserExercisesByType(type: String): Flow<Result<List<UserExercise>>> = flow {
        try {
            val response = apiService.getUserExercisesByType(getAuthHeader(), type)
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to get user exercises by type: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get user exercises by type error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get latest user exercises (protected endpoint)
     */
    fun getLatestUserExercises(): Flow<Result<Map<String, UserExercise>>> = flow {
        try {
            val response = apiService.getLatestUserExercises(getAuthHeader())
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to get latest user exercises: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get latest user exercises error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Create user exercise (protected endpoint)
     */
    fun createUserExercise(
        exerciseId: Int,
        type: String,
        reps: Int? = null,
        timeInSeconds: Int? = null,
        distance: Double? = null,
        score: Int
    ): Flow<Result<UserExercise>> = flow {
        try {
            val request = CreateUserExerciseRequest(
                exerciseId = exerciseId,
                type = type,
                reps = reps,
                timeInSeconds = timeInSeconds,
                distance = distance,
                score = score
            )
            val response = apiService.createUserExercise(getAuthHeader(), request)
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                if (response.code() == 401) {
                    clearUserSession()
                }
                emit(Result.Error(IOException("Failed to create user exercise: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Create user exercise error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get global leaderboard (public endpoint)
     */
    fun getGlobalLeaderboard(): Flow<Result<List<LeaderboardEntry>>> = flow {
        try {
            val response = apiService.getGlobalLeaderboard()
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                emit(Result.Error(IOException("Failed to get global leaderboard: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get global leaderboard error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Get local leaderboard (public endpoint)
     */
    fun getLocalLeaderboard(
        latitude: Double,
        longitude: Double,
        radiusMiles: Int = 5
    ): Flow<Result<List<LeaderboardEntry>>> = flow {
        try {
            val response = apiService.getLocalLeaderboard(latitude, longitude, radiusMiles)
            if (response.isSuccessful) {
                emit(Result.Success(response.body()!!))
            } else {
                emit(Result.Error(IOException("Failed to get local leaderboard: ${response.code()}")))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Get local leaderboard error", e)
            emit(Result.Error(e))
        }
    }
    
    /**
     * Save user session to preferences with JWT token
     */
    private fun saveUserSession(user: User, token: String, expiresIn: String) {
        prefs.edit().apply {
            putInt(KEY_USER_ID, user.id)
            putString(KEY_USERNAME, user.username)
            putString(KEY_AUTH_TOKEN, token)
            // Could convert expiresIn (e.g. "7d") to milliseconds and store expiry time
            // For simplicity we'll just store the raw value
            putString(KEY_TOKEN_EXPIRY, expiresIn)
            apply()
        }
    }
    
    /**
     * Clear user session from preferences
     */
    private fun clearUserSession() {
        prefs.edit().clear().apply()
    }
    
    /**
     * Check if a user is logged in
     */
    fun isLoggedIn(): Boolean {
        return getAuthToken() != null && prefs.contains(KEY_USER_ID)
    }
}