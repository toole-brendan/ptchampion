package com.example.ptchampion.di

import com.example.ptchampion.posedetection.PoseProcessor
import com.example.ptchampion.posedetection.StubPoseProcessor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PoseProcessorModule {

    @Provides
    @Singleton
    fun providePoseProcessor(): PoseProcessor {
        // For now, we're providing a stub implementation
        // In a real app, you would inject the actual implementation with its dependencies
        return StubPoseProcessor()
    }
} 