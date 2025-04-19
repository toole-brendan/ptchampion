package com.example.ptchampion.di

import com.example.ptchampion.util.AppUpdateManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Module to provide app update-related dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
object UpdateModule {

    @Provides
    @Singleton
    fun provideAppUpdateManager(): AppUpdateManager {
        return AppUpdateManager()
    }
} 