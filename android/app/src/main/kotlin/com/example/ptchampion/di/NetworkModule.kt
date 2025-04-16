package com.example.ptchampion.di

import com.example.ptchampion.data.datastore.UserPreferencesRepository
import com.example.ptchampion.data.network.AuthInterceptor
import com.example.ptchampion.data.service.AuthApiService
import com.example.ptchampion.data.service.UserApiService
import com.example.ptchampion.data.service.ExerciseApiService
import com.example.ptchampion.data.network.WorkoutApiService
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import javax.inject.Singleton
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    // TODO: Replace with your actual backend base URL
    // It's recommended to use BuildConfig fields for different build types (debug/release)
    private const val BASE_URL = "http://10.0.2.2:8080/api/v1/" // Example: Emulator accessing localhost:8080
    
    // Use a constant for debug mode instead of BuildConfig.DEBUG
    private const val DEBUG_MODE = true

    @Provides
    @Singleton
    fun provideAuthInterceptor(userPreferencesRepository: UserPreferencesRepository): AuthInterceptor {
        return AuthInterceptor(userPreferencesRepository)
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(authInterceptor: AuthInterceptor): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (DEBUG_MODE) HttpLoggingInterceptor.Level.BODY else HttpLoggingInterceptor.Level.NONE
        }
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor) // Add auth interceptor first
            .addInterceptor(loggingInterceptor) // Then logging interceptor
            .build()
    }

    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .add(KotlinJsonAdapterFactory()) // Add Kotlin support
            .build()
    }
    
    @Provides
    @Singleton
    fun provideJson(): Json {
        return Json {
            ignoreUnknownKeys = true
            coerceInputValues = true
            encodeDefaults = true
        }
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, moshi: Moshi, json: Json): Retrofit {
        val contentType = "application/json".toMediaType()
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .addConverterFactory(json.asConverterFactory(contentType))
            .build()
    }

    // --- API Service Providers ---

    @Provides
    @Singleton
    fun provideAuthApiService(retrofit: Retrofit): AuthApiService {
        return retrofit.create(AuthApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideUserApiService(retrofit: Retrofit): UserApiService {
        return retrofit.create(UserApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideExerciseApiService(retrofit: Retrofit): ExerciseApiService {
        return retrofit.create(ExerciseApiService::class.java)
    }
    
    @Provides
    @Singleton
    fun provideWorkoutApiService(retrofit: Retrofit): com.example.ptchampion.data.network.WorkoutApiService {
        return retrofit.create(com.example.ptchampion.data.network.WorkoutApiService::class.java)
    }

    // Remove providers for other APIs we don't need right now
}