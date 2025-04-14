package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.repository.AuthRepository
import org.openapitools.client.apis.AuthApi
import org.openapitools.client.models.LoginRequest
import org.openapitools.client.models.LoginResponse
import org.openapitools.client.models.InsertUser
import org.openapitools.client.models.User
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.emptyPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.preferencesDataStoreFile
import dagger.hilt.android.qualifiers.ApplicationContext

@Singleton // Indicate Hilt should provide a single instance
class AuthRepositoryImpl @Inject constructor(
    private val api: AuthApi,
    @ApplicationContext private val context: Context
) : AuthRepository {

    private val dataStore: DataStore<Preferences> = PreferenceDataStoreFactory.create(
        produceFile = { context.preferencesDataStoreFile("auth") }
    )
    private object PreferencesKeys {
        val AUTH_TOKEN = stringPreferencesKey("auth_token")
    }

    override suspend fun login(loginRequest: LoginRequest): Resource<LoginResponse> {
        return withContext(Dispatchers.IO) { // Perform network call on IO dispatcher
            try {
                val response = api.authLoginPost(loginRequest).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
                if (response.token != null) {
                    storeAuthToken(response.token)
                }
                Resource.Success(response)
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }

    override suspend fun register(insertUser: InsertUser): Resource<User> {
        return withContext(Dispatchers.IO) {
            try {
                val response = api.authRegisterPost(insertUser).execute().body()
                    ?: return@withContext Resource.Error("Empty response body")
                Resource.Success(response)
            } catch (e: HttpException) {
                Resource.Error(e.message ?: "HTTP Error: ${e.code()}")
            } catch (e: IOException) {
                Resource.Error(e.message ?: "Network Error")
            } catch (e: Exception) {
                Resource.Error(e.message ?: "An unexpected error occurred")
            }
        }
    }

    override suspend fun storeAuthToken(token: String) {
        dataStore.edit {
            preferences ->
            preferences[PreferencesKeys.AUTH_TOKEN] = token
        }
    }

    override fun getAuthToken(): Flow<String?> {
        return dataStore.data
            .catch { exception ->
                if (exception is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw exception
                }
            }.map {
                preferences ->
                preferences[PreferencesKeys.AUTH_TOKEN]
            }
    }

    override suspend fun clearAuthToken() {
        dataStore.edit {
            preferences ->
            preferences.remove(PreferencesKeys.AUTH_TOKEN)
        }
    }

    override suspend fun logout() {
        clearAuthToken()
    }
} 