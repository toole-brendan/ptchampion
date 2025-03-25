package com.ptchampion.ui.exercises

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel

/**
 * Screen that coordinates between different exercise types
 */
@Composable
fun ExercisesScreen(
    exerciseId: Int,
    onNavigateBack: () -> Unit,
    viewModel: ExerciseViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Load exercise data
    LaunchedEffect(exerciseId) {
        viewModel.loadExercise(exerciseId)
    }
    
    // Show error messages
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }
    
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        if (uiState.isLoading) {
            CircularProgressIndicator()
        } else {
            uiState.exercise?.let { exercise ->
                when (exercise.type.lowercase()) {
                    "pushup" -> {
                        PushupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updatePushupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(
                                    exerciseType = exercise.type,
                                    reps = reps
                                )
                            }
                        )
                    }
                    "pullup" -> {
                        PullupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updatePullupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(
                                    exerciseType = exercise.type,
                                    reps = reps
                                )
                            }
                        )
                    }
                    "situp" -> {
                        SitupExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateState = { viewModel.updateSitupState(it) },
                            onCompleteExercise = { reps ->
                                viewModel.completeExercise(
                                    exerciseType = exercise.type,
                                    reps = reps
                                )
                            }
                        )
                    }
                    "run" -> {
                        RunExerciseScreen(
                            exercise = exercise,
                            uiState = uiState,
                            onNavigateBack = onNavigateBack,
                            onStartExercise = { viewModel.startExercise() },
                            onUpdateRunData = { viewModel.updateRunData(it) },
                            onCompleteExercise = { timeInSeconds, distance ->
                                viewModel.completeExercise(
                                    exerciseType = exercise.type,
                                    timeInSeconds = timeInSeconds,
                                    distance = distance
                                )
                            }
                        )
                    }
                    else -> {
                        Text(
                            text = "Unknown exercise type: ${exercise.type}",
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } ?: run {
                Text(
                    text = "Exercise not found",
                    style = MaterialTheme.typography.bodyLarge,
                    textAlign = TextAlign.Center
                )
            }
        }
        
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}