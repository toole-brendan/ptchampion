package com.example.ptchampion.data.datastore

import kotlinx.coroutines.flow.Flow

interface UserPreferencesRepository {
    val authToken: Flow<String?>
    suspend fun saveAuthToken(token: String)
    suspend fun clearAuthToken()
}
