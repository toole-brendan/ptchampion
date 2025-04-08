package com.example.ptchampion.ui.screens.exerciselist

import androidx.lifecycle.ViewModel
import com.example.ptchampion.ui.screens.leaderboard.ExerciseType // Reuse ExerciseType enum
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

// Simple model for the UI list
data class ExerciseListItem( // Renamed to avoid conflict
    val type: ExerciseType,
    val name: String,
    // Add description or image later if needed
)

data class ExerciseListState(
    val exercises: List<ExerciseListItem> = emptyList()
)

@HiltViewModel
class ExerciseListViewModel @Inject constructor() : ViewModel() {

    val state = ExerciseListState(
        // Hardcode the list of available exercises for now
        exercises = ExerciseType.values().map {
            ExerciseListItem(type = it, name = it.displayName)
        }
    )

    // No data fetching logic needed yet
} 