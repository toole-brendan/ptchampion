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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.screens.leaderboard.ExerciseType

@Composable
fun ExerciseListScreen(
    viewModel: ExerciseListViewModel = hiltViewModel(),
    navigateToCamera: (exerciseType: String) -> Unit // Callback to navigate
) {
    val state = viewModel.state

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Select Exercise", fontSize = 24.sp, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(16.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(state.exercises) { exercise ->
                ExerciseRow(exercise = exercise) {
                    // Navigate to CameraScreen, passing the API value of the type
                    navigateToCamera(exercise.type.apiValue)
                }
                HorizontalDivider()
            }
        }
    }
}

@Composable
fun ExerciseRow(
    exercise: ExerciseListItem,
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