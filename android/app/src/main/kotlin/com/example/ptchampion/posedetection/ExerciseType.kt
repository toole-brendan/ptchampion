package com.example.ptchampion.posedetection

/**
 * Enumeration of exercise types supported by the application.
 * Each type includes an ID that corresponds to backend exercise identifiers.
 */
enum class ExerciseType(val id: Int) {
    PUSH_UPS(1),
    PULL_UPS(2),
    SIT_UPS(3),
    RUN(4);

    companion object {
        /**
         * Convert a string representation to enum value
         */
        fun fromString(value: String): ExerciseType {
            return when(value.lowercase()) {
                "pushup", "pushups" -> PUSH_UPS
                "pullup", "pullups" -> PULL_UPS
                "situp", "situps" -> SIT_UPS
                "run", "running" -> RUN
                else -> throw IllegalArgumentException("Unknown exercise type: $value")
            }
        }
    }
} 