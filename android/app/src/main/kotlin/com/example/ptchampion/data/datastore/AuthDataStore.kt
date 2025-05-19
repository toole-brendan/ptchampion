package com.example.ptchampion.data.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

// Define DataStore instance at the top level - REMOVE THIS, PROVIDED BY MODULE
// private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "auth_prefs")

@Singleton
class AuthDataStore @Inject constructor(private val dataStore: DataStore<Preferences>) {

    private object PreferencesKeys {
        val AUTH_TOKEN = stringPreferencesKey("auth_token")
    }

    val authToken: Flow<String?> = dataStore.data
        .map {
            it[PreferencesKeys.AUTH_TOKEN]
        }

    suspend fun saveAuthToken(token: String) {
        dataStore.edit {
            it[PreferencesKeys.AUTH_TOKEN] = token
        }
    }

    suspend fun clearAuthToken() {
        dataStore.edit {
            it.remove(PreferencesKeys.AUTH_TOKEN)
        }
    }
} 