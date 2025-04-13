package com.example.ptchampion.data.network

import com.example.ptchampion.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

// Define paths that should NOT have the auth token added
private val NO_AUTH_PATHS = setOf("/api/users/login", "/api/users")

@Singleton
class AuthInterceptor @Inject constructor(
    private val userPreferencesRepository: UserPreferencesRepository
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        // Check if the request path is one that doesn't require authentication
        val path = originalRequest.url.encodedPath
        val requiresAuth = NO_AUTH_PATHS.none { path.endsWith(it) } // Add token if path is NOT in NO_AUTH_PATHS

        if (!requiresAuth) {
            return chain.proceed(originalRequest)
        }

        // Blockingly get the current token. This runs on OkHttp's background threads.
        val token = runBlocking {
            userPreferencesRepository.authToken.firstOrNull()
        }

        val newRequestBuilder = originalRequest.newBuilder()

        if (token != null) {
            newRequestBuilder.header("Authorization", "Bearer $token")
        }

        // TODO: Handle cases where token is null but required (e.g., redirect to login?)
        // For now, proceed without the token if it's missing, the API should reject it.

        return chain.proceed(newRequestBuilder.build())
    }
} 