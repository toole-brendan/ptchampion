package com.example.ptchampion.data.features

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.ptchampion.data.api.ApiService
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import org.json.JSONObject
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.flow

/**
 * Feature flag constants - must match backend
 */
object FeatureFlags {
    const val GRADING_FORMULA_V2 = "grading_formula_v2"
    const val FINE_TUNED_PUSHUP_MODEL = "fine_tuned_pushup_model"
    const val TEAM_CHALLENGES = "team_challenges"
    const val DARK_MODE_DEFAULT = "dark_mode_default"
}

/**
 * Feature flag response from API
 */
data class FeatureFlagsResponse(
    val features: Map<String, Any>
)

/**
 * Manager for feature flags with caching and fallback values
 */
@Singleton
class FeatureFlagManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val apiService: ApiService
) {
    companion object {
        private const val TAG = "FeatureFlagManager"
        private const val PREFS_NAME = "feature_flags"
        private const val CACHE_TTL_MS = 5 * 60 * 1000 // 5 minutes
        private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(PREFS_NAME)
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private var lastFetchTimeMs: Long
        get() = prefs.getLong("last_fetch_time", 0)
        set(value) = prefs.edit().putLong("last_fetch_time", value).apply()

    /**
     * Get all feature flags, fetching from API if cache is expired
     */
    suspend fun getFeatureFlags(): Flow<Result<Map<String, Any>>> = flow {
        // Check if we should fetch new flags
        val shouldFetch = System.currentTimeMillis() - lastFetchTimeMs > CACHE_TTL_MS

        if (shouldFetch) {
            try {
                // Fetch from API
                val response = apiService.getFeatureFlags()
                
                // Update cache
                val features = response.features
                updateFeatureCache(features)
                
                // Update timestamp
                lastFetchTimeMs = System.currentTimeMillis()
                
                emit(Result.success(features))
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching feature flags", e)
                // On error, try to return cached values
                val cachedFlags = getCachedFlags()
                if (cachedFlags.isNotEmpty()) {
                    emit(Result.success(cachedFlags))
                } else {
                    emit(Result.failure(e))
                }
            }
        } else {
            // Return cached values
            emit(Result.success(getCachedFlags()))
        }
    }

    /**
     * Check if a feature flag is enabled
     */
    suspend fun isFeatureEnabled(flagName: String, defaultValue: Boolean = false): Boolean {
        return getBooleanFlag(flagName, defaultValue)
    }

    /**
     * Get a boolean feature flag
     */
    suspend fun getBooleanFlag(flagName: String, defaultValue: Boolean = false): Boolean {
        // First try to get from cache
        try {
            val key = booleanPreferencesKey(flagName)
            val preferences = context.dataStore.data.first()
            if (preferences.contains(key)) {
                return preferences[key] ?: defaultValue
            }

            // If not in cache, try to fetch
            val flagsResult = getFeatureFlags().first()
            if (flagsResult.isSuccess) {
                val flags = flagsResult.getOrNull()
                if (flags != null && flags.containsKey(flagName)) {
                    val value = flags[flagName]
                    return when (value) {
                        is Boolean -> value
                        is String -> value.equals("true", ignoreCase = true)
                        else -> defaultValue
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting boolean flag $flagName", e)
        }
        
        return defaultValue
    }

    /**
     * Get a string feature flag
     */
    suspend fun getStringFlag(flagName: String, defaultValue: String = ""): String {
        // First try to get from cache
        try {
            val key = stringPreferencesKey(flagName)
            val preferences = context.dataStore.data.first()
            if (preferences.contains(key)) {
                return preferences[key] ?: defaultValue
            }

            // If not in cache, try to fetch
            val flagsResult = getFeatureFlags().first()
            if (flagsResult.isSuccess) {
                val flags = flagsResult.getOrNull()
                if (flags != null && flags.containsKey(flagName)) {
                    return flags[flagName]?.toString() ?: defaultValue
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting string flag $flagName", e)
        }
        
        return defaultValue
    }

    /**
     * Get a numeric feature flag
     */
    suspend fun getNumberFlag(flagName: String, defaultValue: Double = 0.0): Double {
        // First try to get from cache
        try {
            val key = doublePreferencesKey(flagName)
            val preferences = context.dataStore.data.first()
            if (preferences.contains(key)) {
                return preferences[key] ?: defaultValue
            }

            // If not in cache, try to fetch
            val flagsResult = getFeatureFlags().first()
            if (flagsResult.isSuccess) {
                val flags = flagsResult.getOrNull()
                if (flags != null && flags.containsKey(flagName)) {
                    val value = flags[flagName]
                    return when (value) {
                        is Number -> value.toDouble()
                        is String -> value.toDoubleOrNull() ?: defaultValue
                        else -> defaultValue
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting number flag $flagName", e)
        }
        
        return defaultValue
    }

    /**
     * Get a JSON feature flag
     */
    suspend fun <T> getJsonFlag(flagName: String, parser: (String) -> T?, defaultValue: T? = null): T? {
        // Get as string and parse JSON
        try {
            val strValue = getStringFlag(flagName, "")
            if (strValue.isNotEmpty()) {
                return parser(strValue) ?: defaultValue
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing JSON flag $flagName", e)
        }
        
        return defaultValue
    }

    /**
     * Force refresh all feature flags
     */
    suspend fun refreshFeatureFlags(): Result<Map<String, Any>> {
        // Reset cache time to force refresh
        lastFetchTimeMs = 0
        return getFeatureFlags().first()
    }

    /**
     * Clear all cached flags
     */
    suspend fun clearCache() {
        context.dataStore.edit { it.clear() }
        lastFetchTimeMs = 0
    }
    
    /**
     * Get all cached flags
     */
    private suspend fun getCachedFlags(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        try {
            val preferences = context.dataStore.data.first()
            preferences.asMap().forEach { (key, value) ->
                if (key.name != "last_fetch_time") {
                    result[key.name] = value
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting cached flags", e)
        }
        return result
    }

    /**
     * Update the feature flag cache
     */
    private suspend fun updateFeatureCache(flags: Map<String, Any>) {
        context.dataStore.edit { preferences ->
            flags.forEach { (key, value) ->
                when (value) {
                    is Boolean -> preferences[booleanPreferencesKey(key)] = value
                    is String -> preferences[stringPreferencesKey(key)] = value
                    is Number -> preferences[doublePreferencesKey(key)] = value.toDouble()
                    else -> preferences[stringPreferencesKey(key)] = value.toString()
                }
            }
        }
    }
} 