package com.example.ptchampion.ui.screens.camera

/**
 * Represents the current state of a camera tracking session
 */
enum class SessionState {
    IDLE,        // Initial state, not actively tracking
    STARTING,    // Starting up tracking
    RUNNING,     // Actively tracking/analyzing
    PAUSED,      // Temporarily paused
    FINISHED     // Completed workout session
} 