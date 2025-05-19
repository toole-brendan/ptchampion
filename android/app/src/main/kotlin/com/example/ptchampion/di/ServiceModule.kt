package com.example.ptchampion.di

import android.content.Context
import com.example.ptchampion.data.service.BluetoothServiceImpl
import com.example.ptchampion.data.service.WatchBluetoothService
import com.example.ptchampion.domain.service.BluetoothService
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Qualifier
import javax.inject.Singleton

/**
 * Custom qualifiers for Bluetooth service implementations
 */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class GeneralBluetoothService

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class GPSWatchBluetoothService

/**
 * Module to provide Bluetooth service implementation.
 * LocationService is provided by LocationModule.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class ServiceModule {

    @Binds
    @Singleton
    @GeneralBluetoothService
    abstract fun bindBluetoothService(bluetoothServiceImpl: BluetoothServiceImpl): BluetoothService
    
    @Binds
    @Singleton
    @GPSWatchBluetoothService
    abstract fun bindWatchBluetoothService(watchBluetoothService: WatchBluetoothService): BluetoothService
} 