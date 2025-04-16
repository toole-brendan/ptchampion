package com.example.ptchampion.domain.exercise

/**
 * Represents the different states an exercise can be in during analysis.
 */
enum class ExerciseState {
    IDLE,       // Initial state, no movement detected
    STARTING,   // Movement detected, but not yet in a countable position
    DOWN,       // In the "down" position of the exercise (e.g., bottom of pushup)
    UP,         // In the "up" position of the exercise (e.g., top of pushup)
    FINISHED,   // Exercise session completed
    INVALID     // Invalid form detected or user not properly in frame
} 