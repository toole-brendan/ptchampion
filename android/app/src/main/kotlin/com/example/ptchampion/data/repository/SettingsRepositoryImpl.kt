package com.example.ptchampion.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.preferencesDataStore
import com.example.ptchampion.domain.repository.SettingsRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

// Define DataStore instance
private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Singleton
class SettingsRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : SettingsRepository {

    private object PreferencesKeys {
        val USE_MILES = booleanPreferencesKey("use_miles")
        val ONBOARDING_COMPLETE = booleanPreferencesKey("onboarding_complete")
    }

    override fun getUnitPreference(): Flow<Boolean> {
        return context.dataStore.data
            .catch { exception ->
                // dataStore.data throws an IOException when an error is encountered when reading data
                if (exception is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw exception
                }
            }.map {
                preferences ->
                preferences[PreferencesKeys.USE_MILES] ?: true // Default to miles
            }
    }

    override suspend fun saveUnitPreference(useMiles: Boolean) {
        context.dataStore.edit {
            preferences ->
            preferences[PreferencesKeys.USE_MILES] = useMiles
        }
    }

    override fun getOnboardingComplete(): Flow<Boolean> {
        return context.dataStore.data
            .catch { exception ->
                if (exception is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw exception
                }
            }.map {
                preferences ->
                preferences[PreferencesKeys.ONBOARDING_COMPLETE] ?: false // Default to false (needs onboarding)
            }
    }

    override suspend fun setOnboardingComplete(isComplete: Boolean) {
        context.dataStore.edit {
            preferences ->
            preferences[PreferencesKeys.ONBOARDING_COMPLETE] = isComplete
        }
    }
} 