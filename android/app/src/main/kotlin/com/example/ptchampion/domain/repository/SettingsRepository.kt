package com.example.ptchampion.domain.repository

import kotlinx.coroutines.flow.Flow

interface SettingsRepository {

    /**
     * Get the user's preference for distance units.
     * @return Flow emitting true if miles should be used, false for kilometers.
     */
    fun getUnitPreference(): Flow<Boolean>

    /**
     * Save the user's preference for distance units.
     * @param useMiles true to use miles, false for kilometers.
     */
    suspend fun saveUnitPreference(useMiles: Boolean)

    /**
     * Check if the user has completed the onboarding process.
     * @return Flow emitting true if onboarding is complete, false otherwise.
     */
    fun getOnboardingComplete(): Flow<Boolean>

    /**
     * Mark the onboarding process as complete or incomplete.
     * @param isComplete true if onboarding is complete.
     */
    suspend fun setOnboardingComplete(isComplete: Boolean)
} 