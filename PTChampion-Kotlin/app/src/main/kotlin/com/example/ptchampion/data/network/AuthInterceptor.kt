package com.example.ptchampion.data.network

import com.example.ptchampion.data.datastore.UserPreferencesRepository
import kotlinx.coroutines.flow.first
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

        // Fetch token synchronously (required for interceptor)
        // Note: This blocks the network thread. Consider alternative approaches if performance is critical.
        val token = runBlocking {
            userPreferencesRepository.authToken.first()
        }

        val requestBuilder = originalRequest.newBuilder()
        
        // Add Authorization header only if token exists
        token?.let {
            requestBuilder.addHeader("Authorization", "Bearer $it")
        }

        val request = requestBuilder.build()
        return chain.proceed(request)
    }
} 