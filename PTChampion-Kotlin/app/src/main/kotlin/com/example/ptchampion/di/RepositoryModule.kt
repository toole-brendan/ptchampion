package com.example.ptchampion.di

import com.example.ptchampion.data.repository.AuthRepositoryImpl
import com.example.ptchampion.data.repository.LeaderboardRepositoryImpl
import com.example.ptchampion.data.repository.UserRepositoryImpl
import com.example.ptchampion.data.repository.WorkoutRepositoryImpl
import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.repository.WorkoutRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds
    @Singleton
    abstract fun bindLeaderboardRepository(impl: LeaderboardRepositoryImpl): LeaderboardRepository

    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository

    @Binds
    @Singleton
    abstract fun bindWorkoutRepository(impl: WorkoutRepositoryImpl): WorkoutRepository

    // Bind other repositories here as they are created
} 