package com.example.ptchampion.di

import android.content.Context
import com.example.ptchampion.data.service.BluetoothServiceImpl
import com.example.ptchampion.domain.service.BluetoothService
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Module to provide Bluetooth service implementation.
 * LocationService is provided by LocationModule.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class ServiceModule {

    @Binds
    @Singleton
    abstract fun bindBluetoothService(bluetoothServiceImpl: BluetoothServiceImpl): BluetoothService
} 