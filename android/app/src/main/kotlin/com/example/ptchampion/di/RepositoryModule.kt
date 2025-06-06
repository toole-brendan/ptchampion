package com.example.ptchampion.di

import com.example.ptchampion.data.repository.UserRepositoryImpl
import com.example.ptchampion.data.repository.ExerciseRepositoryImpl
import com.example.ptchampion.data.repository.WorkoutRepositoryImpl
import com.example.ptchampion.data.repository.LeaderboardRepositoryImpl
import com.example.ptchampion.data.repository.AuthRepositoryImpl
import com.example.ptchampion.data.repository.SettingsRepositoryImpl
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.repository.ExerciseRepository
import com.example.ptchampion.domain.repository.WorkoutRepository
import com.example.ptchampion.domain.repository.LeaderboardRepository
import com.example.ptchampion.domain.repository.AuthRepository
import com.example.ptchampion.domain.repository.SettingsRepository
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
    abstract fun bindUserRepository(
        userRepositoryImpl: UserRepositoryImpl
    ): UserRepository

    @Binds
    @Singleton
    abstract fun bindExerciseRepository(
        exerciseRepositoryImpl: ExerciseRepositoryImpl
    ): ExerciseRepository
    
    @Binds
    @Singleton
    abstract fun bindWorkoutRepository(
        workoutRepositoryImpl: WorkoutRepositoryImpl
    ): WorkoutRepository
    
    @Binds
    @Singleton
    abstract fun bindLeaderboardRepository(
        leaderboardRepositoryImpl: LeaderboardRepositoryImpl
    ): LeaderboardRepository

    // Add binding for AuthRepository
    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        authRepositoryImpl: AuthRepositoryImpl
    ): AuthRepository

    // Add binding for SettingsRepository
    @Binds
    @Singleton
    abstract fun bindSettingsRepository(
        settingsRepositoryImpl: SettingsRepositoryImpl
    ): SettingsRepository

    // TODO: Add bindings for other repositories (LeaderboardRepository, etc.) here
    // Example:
    // @Binds
    // @Singleton
    // abstract fun bindExerciseRepository(
    //     exerciseRepositoryImpl: ExerciseRepositoryImpl
    // ): ExerciseRepository
}