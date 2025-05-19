package com.example.ptchampion.data.network

import android.content.SharedPreferences
import com.example.ptchampion.data.repository.AUTH_TOKEN_KEY
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

// Define paths that should NOT have the auth token added
private val NO_AUTH_PATHS = setOf("/api/v1/auth/login", "/api/v1/auth/register")

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

        // Get token synchronously from EncryptedSharedPreferences (primary secure storage)
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