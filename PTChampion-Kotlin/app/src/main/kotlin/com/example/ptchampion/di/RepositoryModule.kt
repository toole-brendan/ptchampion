package com.example.ptchampion.di

import com.example.ptchampion.data.repository.UserRepositoryImpl
import com.example.ptchampion.data.repository.ExerciseRepositoryImpl
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.repository.ExerciseRepository
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

    // TODO: Add bindings for other repositories (LeaderboardRepository, etc.) here
    // Example:
    // @Binds
    // @Singleton
    // abstract fun bindExerciseRepository(
    //     exerciseRepositoryImpl: ExerciseRepositoryImpl
    // ): ExerciseRepository
}