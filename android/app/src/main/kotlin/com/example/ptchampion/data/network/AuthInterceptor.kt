package com.example.ptchampion.data.network

import android.content.SharedPreferences
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

// Define paths that should NOT have the auth token added
private val NO_AUTH_PATHS = setOf("/api/v1/auth/login", "/api/v1/auth/register")

private const val AUTH_TOKEN_KEY = "auth_token"

@Singleton
class AuthInterceptor @Inject constructor(
    private val encryptedPrefs: SharedPreferences
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        // Check if the request path is one that doesn't require authentication
        val path = originalRequest.url.encodedPath
        val requiresAuth = NO_AUTH_PATHS.none { path.endsWith(it) }

        if (!requiresAuth) {
            return chain.proceed(originalRequest)
        }

        // Get token synchronously directly from EncryptedSharedPreferences
        val token = encryptedPrefs.getString(AUTH_TOKEN_KEY, null)

        val requestBuilder = originalRequest.newBuilder()
        
        // Add Authorization header only if token exists
        token?.let {
            requestBuilder.addHeader("Authorization", "Bearer $it")
        }

        val request = requestBuilder.build()
        return chain.proceed(request)
    }
} 