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

interface AuthRepository {
    suspend fun login(loginRequest: LoginRequest): Resource<LoginResponse>
    suspend fun register(insertUser: InsertUser): Resource<User> // Registration returns User model
} 