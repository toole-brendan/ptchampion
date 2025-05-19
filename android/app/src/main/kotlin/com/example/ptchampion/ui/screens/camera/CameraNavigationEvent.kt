package com.example.ptchampion.ui.screens.camera

/**
 * Sealed class representing navigation events from the camera screen
 */
sealed class CameraNavigationEvent {
    /**
     * Navigate back to the previous screen
     */
    object NavigateBack : CameraNavigationEvent()
    
    /**
     * Navigate to exercise history screen
     */
    object NavigateToHistory : CameraNavigationEvent()
    
    /**
     * Navigate to the workout details screen
     * @param workoutId The ID of the workout to view
     */
    data class NavigateToWorkoutDetails(val workoutId: Int) : CameraNavigationEvent()
} 