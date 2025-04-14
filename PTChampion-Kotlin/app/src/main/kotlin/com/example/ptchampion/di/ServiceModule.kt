package com.example.ptchampion.di

import android.content.Context
import com.example.ptchampion.data.service.BluetoothServiceImpl
import com.example.ptchampion.data.service.LocationServiceImpl
import com.example.ptchampion.domain.service.BluetoothService
import com.example.ptchampion.domain.service.LocationService
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class ServiceModule {

    @Binds
    @Singleton
    abstract fun bindLocationService(locationServiceImpl: LocationServiceImpl): LocationService

    @Binds
    @Singleton
    abstract fun bindBluetoothService(bluetoothServiceImpl: BluetoothServiceImpl): BluetoothService

}

// Separate module for other dependencies. Moved FusedLocationProviderClient to LocationModule
@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    // Remove provideFusedLocationProviderClient as it's already provided in LocationModule

    // Add other application-wide providers here if needed
} 