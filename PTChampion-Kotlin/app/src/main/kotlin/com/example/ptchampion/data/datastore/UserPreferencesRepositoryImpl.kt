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

// Define the DataStore instance at the top level
private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_prefs")

class UserPreferencesRepositoryImpl @Inject constructor(
    private val context: Context
) : UserPreferencesRepository {

    private object PreferencesKeys {
        val AUTH_TOKEN = stringPreferencesKey("auth_token")
    }

    override val authToken: Flow<String?> = context.dataStore.data
        .map {
            preferences ->
            preferences[PreferencesKeys.AUTH_TOKEN]
        }

    override suspend fun saveAuthToken(token: String) {
        context.dataStore.edit {
            preferences ->
            preferences[PreferencesKeys.AUTH_TOKEN] = token
        }
    }

    override suspend fun clearAuthToken() {
        context.dataStore.edit {
            preferences ->
            preferences.remove(PreferencesKeys.AUTH_TOKEN)
        }
    }
}
