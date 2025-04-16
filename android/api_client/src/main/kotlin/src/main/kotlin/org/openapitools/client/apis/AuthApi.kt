package org.openapitools.client.apis

import org.openapitools.client.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import com.squareup.moshi.Json

import org.openapitools.client.models.InsertUser
import org.openapitools.client.models.LoginRequest
import org.openapitools.client.models.LoginResponse
import org.openapitools.client.models.User

interface AuthApi {
    /**
     * POST auth/login
     * Authenticate a user and get JWT token
     * 
     * Responses:
     *  - 200: Login successful
     *  - 400: Invalid input
     *  - 401: Invalid username or password
     *  - 500: Internal Server Error
     *
     * @param loginRequest  (optional)
     * @return [LoginResponse]
     */
    @POST("auth/login")
    suspend fun authLoginPost(@Body loginRequest: LoginRequest? = null): Response<LoginResponse>

    /**
     * POST auth/register
     * Register a new user
     * 
     * Responses:
     *  - 201: User created successfully
     *  - 400: Invalid input (e.g., validation error)
     *  - 409: Username already exists
     *  - 500: Internal Server Error
     *
     * @param insertUser  (optional)
     * @return [User]
     */
    @POST("auth/register")
    suspend fun authRegisterPost(@Body insertUser: InsertUser? = null): Response<User>

}
