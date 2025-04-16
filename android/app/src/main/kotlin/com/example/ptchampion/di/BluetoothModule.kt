package com.example.ptchampion.di

import com.example.ptchampion.domain.exercise.bluetooth.WatchDataRepository
import com.example.ptchampion.domain.exercise.bluetooth.WatchDataRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class BluetoothModule {
    
    @Binds
    @Singleton
    abstract fun bindWatchDataRepository(
        watchDataRepositoryImpl: WatchDataRepositoryImpl
    ): WatchDataRepository
} 