package com.example.ptchampion.ui.screens.exerciselist

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText
import androidx.compose.foundation.Image
import androidx.compose.ui.res.painterResource

@Composable
fun ExerciseListScreen(
    viewModel: ExerciseListViewModel = viewModel(),
    navigateToCamera: (exerciseId: Int, exerciseType: String) -> Unit
) {
    val state by viewModel.state.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Tactical Cream background
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp) // 20px global padding per style guide
            ) {
                // Title with styling guide typography
                Text(
                    text = "SELECT EXERCISE",
                    style = MaterialTheme.typography.headlineSmall,
                    color = PtCommandBlack
                )
                Spacer(modifier = Modifier.height(20.dp))

                if (!state.isLoading && state.error == null) {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(12.dp) // 12px card gap per style guide
                    ) {
                        items(state.exercises) { exercise ->
                            ExerciseCard(
                                exercise = exercise,
                                onClick = {
                                    navigateToCamera(exercise.id, exercise.type)
                                }
                            )
                        }
                    }
                }
            }

            // Centered Loading Indicator
            if (state.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center),
                    color = PtAccent // Brass Gold color
                )
            }

            // Centered Error Message
            state.error?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(16.dp)
                )
            }
        }
    }
}

@Composable
fun ExerciseCard(
    exercise: ExerciseResponse,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = PtBackground // Tactical Cream
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 1.dp // Soft subtle shadow per styling guide
        ),
        shape = MaterialTheme.shapes.medium // 12px radius as per styling guide
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp), // 16px padding per styling guide
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Use custom image based on exercise type
            val iconRes = getExerciseIconResource(exercise.type)
            Image(
                painter = painterResource(id = iconRes),
                contentDescription = exercise.name,
                modifier = Modifier.size(48.dp),
                colorFilter = androidx.compose.ui.graphics.ColorFilter.tint(PtAccent) // Apply gold tint
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // Exercise name
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = PtCommandBlack
                )
                
                // Exercise description or details (if available)
                exercise.description?.let {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = PtSecondaryText
                    )
                }
            }
            
            Icon(
                imageVector = Icons.Default.KeyboardArrowRight,
                contentDescription = "Start Exercise",
                tint = PtAccent // Brass Gold
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