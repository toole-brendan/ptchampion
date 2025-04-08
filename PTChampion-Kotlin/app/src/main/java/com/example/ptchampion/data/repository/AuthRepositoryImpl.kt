package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.generatedapi.api.DefaultApi
import com.example.ptchampion.generatedapi.models.AuthRequest
import com.example.ptchampion.generatedapi.models.AuthResponse
import com.example.ptchampion.generatedapi.models.RegisterRequest
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton // Indicate Hilt should provide a single instance
class AuthRepositoryImpl @Inject constructor(
    private val api: DefaultApi
) : AuthRepository {

    override suspend fun login(authRequest: AuthRequest): Resource<AuthResponse> {
        return withContext(Dispatchers.IO) { // Perform network call on IO dispatcher
            try {
                val response = api.loginPost(authRequest)
                Resource.Success(response)
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }

    override suspend fun register(registerRequest: RegisterRequest): Resource<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                api.registerPost(registerRequest)
                Resource.Success(Unit) // Return Success with Unit for no body
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }
} 