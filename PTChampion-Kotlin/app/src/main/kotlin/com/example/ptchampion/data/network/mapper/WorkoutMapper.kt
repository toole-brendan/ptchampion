package com.example.ptchampion.data.network.mapper

import com.example.ptchampion.data.network.dto.WorkoutResponseDto
import com.example.ptchampion.domain.model.WorkoutSession

/**
 * Maps WorkoutResponseDto (network layer) to WorkoutSession (domain layer)
 */
fun WorkoutResponseDto.toWorkoutSession(): WorkoutSession {
    return WorkoutSession(
        id = this.id,
        userId = this.userId,
        exerciseId = this.exerciseId,
        exerciseName = this.exerciseName,
        repetitions = this.repetitions,
        durationSeconds = this.durationSeconds,
        formScore = this.formScore,
        grade = this.grade,
        createdAt = this.createdAt,
        completedAt = this.completedAt
    )
} 