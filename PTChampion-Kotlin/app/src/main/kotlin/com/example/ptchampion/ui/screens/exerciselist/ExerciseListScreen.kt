package com.example.ptchampion.ui.screens.exerciselist

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.ExerciseResponse

@Composable
fun ExerciseListScreen(
    viewModel: ExerciseListViewModel = viewModel(),
    navigateToCamera: (exerciseId: Int, exerciseType: String) -> Unit // Pass ID and type
) {
    val state by viewModel.state.collectAsState() // Collect state as State

    Box(modifier = Modifier.fillMaxSize()) { // Use Box for centering loading/error
        Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
            Text("Select Exercise", fontSize = 24.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(16.dp))

            if (state.isLoading) {
                // Centered Loading Indicator - Handled by Box alignment
            } else if (state.error != null) {
                // Centered Error Message - Handled by Box alignment
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(state.exercises) { exercise ->
                        ExerciseRow(exercise = exercise) {
                            // Navigate, passing the actual ID and API type string
                            navigateToCamera(exercise.id, exercise.type)
                        }
                        // HorizontalDivider() // Comment out divider until import is fixed
                    }
                }
            }
        }

        // Centered Loading Indicator
        if (state.isLoading) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        }

        // Centered Error Message
        state.error?.let {
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.align(Alignment.Center).padding(16.dp)
            )
        }
    }
}

@Composable
fun ExerciseRow(
    exercise: ExerciseResponse, // Use the new model
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.FitnessCenter, // Generic icon for now
            contentDescription = null,
            modifier = Modifier.size(40.dp)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = exercise.name,
            fontSize = 18.sp,
            modifier = Modifier.weight(1f)
        )
        Icon(
            imageVector = Icons.Default.KeyboardArrowRight,
            contentDescription = "Start Exercise"
        )
    }
} 