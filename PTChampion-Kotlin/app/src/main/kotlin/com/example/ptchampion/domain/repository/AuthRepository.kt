package com.example.ptchampion.domain.repository

// Correct imports for generated models
import org.openapitools.client.models.LoginRequest
import org.openapitools.client.models.LoginResponse
import org.openapitools.client.models.InsertUser
import org.openapitools.client.models.User
// import com.example.ptchampion.generatedapi.models.AuthRequest - Removed
// import com.example.ptchampion.generatedapi.models.AuthResponse - Removed
// import com.example.ptchampion.generatedapi.models.RegisterRequest - Removed
import com.example.ptchampion.util.Resource // Create Resource class for handling loading/success/error states
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    suspend fun login(loginRequest: LoginRequest): Resource<LoginResponse>
    suspend fun register(insertUser: InsertUser): Resource<User> // Registration returns User model
    suspend fun logout()

    /**
     * Stores the authentication token securely.
     * @param token The authentication token to store.
     */
    suspend fun storeAuthToken(token: String)

    /**
     * Retrieves the stored authentication token as a Flow.
     * Emits null if no token is stored.
     * @return A Flow emitting the auth token or null.
     */
    fun getAuthToken(): Flow<String?>

    /**
     * Clears the stored authentication token.
     */
    suspend fun clearAuthToken()
} 