package com.example.ptchampion.domain.model

import kotlinx.serialization.Serializable

@Serializable // Needed if using kotlinx-serialization converter
data class ExerciseResponse(
    val id: Int,
    val name: String,
    val description: String? = null, // Match NullString
    val type: String // Matches backend 'type' field (e.g., "pushup")
) 