package com.example.ptchampion.domain.repository

// Updated imports to use DTOs instead of generated models
import com.example.ptchampion.data.network.dto.LoginRequestDto
import com.example.ptchampion.data.network.dto.LoginResponseDto
import com.example.ptchampion.data.network.dto.RegisterRequestDto
import com.example.ptchampion.domain.model.User
// Removed incorrect imports
// import com.example.ptchampion.data.network.generated.models.LoginRequest
// import com.example.ptchampion.data.network.generated.models.LoginResponse
// import com.example.ptchampion.data.network.generated.models.InsertUser
// import com.example.ptchampion.data.network.generated.models.User
import com.example.ptchampion.domain.util.Resource
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    suspend fun login(loginRequest: LoginRequestDto): Resource<LoginResponseDto>
    suspend fun register(registerRequest: RegisterRequestDto): Resource<User> // Registration returns User model
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