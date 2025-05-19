package com.example.ptchampion.ui.screens.exerciselist

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.ui.theme.*

@Composable
fun ExerciseListScreen(
    viewModel: ExerciseListViewModel = viewModel(),
    navigateToCamera: (exerciseId: Int, exerciseType: String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Use the main cream background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp)
        ) {
            Text(
                text = "SELECT EXERCISE",
                style = MaterialTheme.typography.headlineMedium,
                color = PtCommandBlack,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            when {
                uiState.isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = PtAccent)
                    }
                }
                uiState.error != null -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("Error: ${uiState.error}", color = MaterialTheme.colorScheme.error)
                    }
                }
                else -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(12.dp) // Spacing between cards
                    ) {
                        itemsIndexed(uiState.exercises, key = { _, exercise -> exercise.id }) { index, exercise ->
                            // Determine background color based on index
                            val backgroundColor = if (index % 2 == 0) {
                                PtBackground // Standard cream for even items
                            } else {
                                PtBackground.copy(alpha = 0.95f) // Slightly darker cream for odd items
                            }
                            ExerciseListItem(
                                exercise = exercise,
                                backgroundColor = backgroundColor,
                                onClick = { navigateToCamera(exercise.id, exercise.type) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ExerciseListItem(
    exercise: ExerciseInfo,
    backgroundColor: Color,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = backgroundColor // Apply alternating background
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp) // Subtle shadow
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = exercise.icon,
                    contentDescription = exercise.name,
                    tint = PtAccent, // Brass Gold for icon
                    modifier = Modifier.size(32.dp)
                )
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text(
                        text = exercise.name,
                        style = MaterialTheme.typography.titleLarge,
                        color = PtCommandBlack
                    )
                    // Display Personal Best instead of description
                    exercise.personalBest?.let { pbText ->
                        Text(
                            text = pbText,
                            style = MaterialTheme.typography.bodyMedium,
                            color = PtSecondaryText
                        )
                    }
                }
            }
            Icon(
                imageVector = Icons.Filled.KeyboardArrowRight,
                contentDescription = "Select Exercise",
                tint = PtAccent // Brass Gold for arrow
            )
        }
    }
}

// Helper function to get the resource ID for exercise icons
@Composable
fun getExerciseIconResource(type: String): Int {
    return when (type.lowercase()) {
        "push_ups" -> com.example.ptchampion.R.drawable.pushup
        "pushup" -> com.example.ptchampion.R.drawable.pushup
        "pull_ups" -> com.example.ptchampion.R.drawable.pullup  
        "pullup" -> com.example.ptchampion.R.drawable.pullup
        "sit_ups" -> com.example.ptchampion.R.drawable.situp
        "situp" -> com.example.ptchampion.R.drawable.situp
        "run" -> com.example.ptchampion.R.drawable.running
        else -> com.example.ptchampion.R.drawable.pushup // Default icon
    }
}

// Keep the original function but mark as unused
// @Composable
// private fun getExerciseIcon(type: String): ImageVector {
//     return when (type.lowercase()) {
//         "pushup" -> Icons.Default.FitnessCenter
//         "situp" -> Icons.Default.SelfImprovement
//         "pullup" -> Icons.Default.FitnessCenter
//         "run" -> Icons.Default.DirectionsRun
//         else -> Icons.Default.FitnessCenter
//     }
// } 