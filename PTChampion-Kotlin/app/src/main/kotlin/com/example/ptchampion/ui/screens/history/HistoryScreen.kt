package com.example.ptchampion.ui.screens.history

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.WorkoutResponse
import com.example.ptchampion.ui.theme.PTChampionTheme
import androidx.compose.material3.CardDefaults
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText
import com.example.ptchampion.ui.theme.PtAccent
import java.time.format.DateTimeFormatter
import java.time.OffsetDateTime

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Workout History") })
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            if (uiState.isLoading && uiState.workouts.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (uiState.error != null && uiState.workouts.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${uiState.error}", color = MaterialTheme.colorScheme.error)
                }
            } else if (uiState.workouts.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No workout history yet.")
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.workouts) { workout ->
                        WorkoutHistoryItem(workout = workout)
                    }

                    // Optional: Add loading indicator at the bottom for pagination
                    if (uiState.isLoading && uiState.workouts.isNotEmpty()) {
                        item {
                            Box(modifier = Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                                CircularProgressIndicator()
                            }
                        }
                    }

                    // Optional: Add logic to trigger loading more items when reaching the end
                    // This usually involves checking scroll state in LazyColumn
                }
            }
        }
    }
}

@Composable
fun WorkoutHistoryItem(workout: WorkoutResponse) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(
            containerColor = PtBackground,
            contentColor = PtCommandBlack
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 1.dp
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                workout.exerciseName, 
                style = MaterialTheme.typography.titleMedium,
                color = PtCommandBlack
            )
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                "Completed: ${formatDateTime(workout.completedAt)}",
                style = MaterialTheme.typography.bodySmall,
                color = PtSecondaryText
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                horizontalArrangement = Arrangement.SpaceBetween, 
                modifier = Modifier.fillMaxWidth()
            ) {
                Column {
                    Text(
                        "REPS", 
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        workout.repetitions?.toString() ?: "N/A", 
                        style = MaterialTheme.typography.displaySmall,
                        color = PtCommandBlack
                    )
                }
                
                Column {
                    Text(
                        "TIME", 
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        if (workout.durationSeconds != null) "${workout.durationSeconds}s" else "N/A",
                        style = MaterialTheme.typography.displaySmall,
                        color = PtCommandBlack
                    )
                }
                
                Column {
                    Text(
                        "GRADE", 
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        workout.grade.toString(),
                        style = MaterialTheme.typography.displaySmall,
                        color = PtAccent
                    )
                }
            }
        }
    }
}

// Helper to format date string
fun formatDateTime(dateTimeString: String?): String {
    if (dateTimeString == null) return "N/A"
    return try {
        val offsetDateTime = OffsetDateTime.parse(dateTimeString)
        val formatter = DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")
        offsetDateTime.format(formatter)
    } catch (e: Exception) {
        dateTimeString // Return original string if parsing fails
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true)
@Composable
fun HistoryScreenPreview() {
    PTChampionTheme {
        // Preview needs a way to mock the ViewModel or pass mock state
        // For simplicity, just showing the screen structure
        Scaffold(topBar = { TopAppBar(title = { Text("Workout History") }) }) {
            Box(modifier = Modifier.padding(it).fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("History Preview (No Data)")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true)
@Composable
fun WorkoutHistoryItemPreview() {
    PTChampionTheme {
        WorkoutHistoryItem(
            workout = WorkoutResponse(
                id = 1,
                exerciseId = 1,
                exerciseName = "Push-ups",
                repetitions = 25,
                durationSeconds = null,
                formScore = 85,
                grade = 90,
                completedAt = "2023-10-27T10:30:00Z",
                createdAt = "2023-10-27T10:29:00Z"
            )
        )
    }
} 