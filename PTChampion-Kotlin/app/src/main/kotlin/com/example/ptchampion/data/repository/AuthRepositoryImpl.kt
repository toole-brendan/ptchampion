package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.AuthRepository
import org.openapitools.client.apis.AuthApi
import org.openapitools.client.models.LoginRequest
import org.openapitools.client.models.LoginResponse
import org.openapitools.client.models.InsertUser
import org.openapitools.client.models.User
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton // Indicate Hilt should provide a single instance
class AuthRepositoryImpl @Inject constructor(
    private val api: AuthApi
) : AuthRepository {

    override suspend fun login(loginRequest: LoginRequest): Resource<LoginResponse> {
        return withContext(Dispatchers.IO) { // Perform network call on IO dispatcher
            try {
                val response = api.authLoginPost(loginRequest).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
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

    override suspend fun register(insertUser: InsertUser): Resource<User> {
        return withContext(Dispatchers.IO) {
            try {
                val response = api.authRegisterPost(insertUser).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
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
} 