package com.example.ptchampion.di

import com.example.ptchampion.data.network.AuthInterceptor
import com.example.ptchampion.data.repository.UserPreferencesRepository
import org.openapitools.client.apis.AuthApi
import org.openapitools.client.apis.UsersApi
import org.openapitools.client.apis.LeaderboardApi
import com.example.ptchampion.data.network.WorkoutApiService
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    // TODO: Replace with actual base URL from configuration or build variants
    private const val BASE_URL = "http://10.0.2.2:8080/" // Default for Android emulator talking to localhost

    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY // Log request/response body in debug builds
            // level = HttpLoggingInterceptor.Level.NONE // Use NONE for release builds
        }
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(userPreferencesRepository: UserPreferencesRepository): AuthInterceptor {
        return AuthInterceptor(userPreferencesRepository)
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        authInterceptor: AuthInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authInterceptor)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, json: Json): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
    }

    @Provides
    @Singleton
    fun provideAuthApi(retrofit: Retrofit): AuthApi {
        return retrofit.create(AuthApi::class.java)
    }

    @Provides
    @Singleton
    fun provideUsersApi(retrofit: Retrofit): UsersApi {
        return retrofit.create(UsersApi::class.java)
    }

    @Provides
    @Singleton
    fun provideLeaderboardApi(retrofit: Retrofit): LeaderboardApi {
        return retrofit.create(LeaderboardApi::class.java)
    }

    @Provides
    @Singleton
    fun provideWorkoutApiService(retrofit: Retrofit): WorkoutApiService {
        return retrofit.create(WorkoutApiService::class.java)
    }
} 