package com.example.ptchampion.domain.repository

import com.example.ptchampion.generatedapi.models.AuthRequest
import com.example.ptchampion.generatedapi.models.AuthResponse
import com.example.ptchampion.generatedapi.models.RegisterRequest
import com.example.ptchampion.util.Resource // Create Resource class for handling loading/success/error states

interface AuthRepository {
    suspend fun login(authRequest: AuthRequest): Resource<AuthResponse>
    suspend fun register(registerRequest: RegisterRequest): Resource<Unit> // Assuming register returns no body on success
} 