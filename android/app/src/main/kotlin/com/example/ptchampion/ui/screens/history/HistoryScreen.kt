package com.example.ptchampion.ui.screens.history

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.paging.LoadState
import androidx.paging.compose.collectAsLazyPagingItems
import androidx.paging.compose.items
import com.example.ptchampion.domain.model.WorkoutSession
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
    viewModel: HistoryViewModel = hiltViewModel()
) {
    val lazyPagingItems = viewModel.historyFlow.collectAsLazyPagingItems()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Workout History") })
        },
        containerColor = PtBackground
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Use modern Paging items approach
            items(
                count = lazyPagingItems.itemCount,
                key = lazyPagingItems.itemKey { it.id }, // Use itemKey extension
                // contentType = lazyPagingItems.itemContentType { "workoutItem" } // Optional: for performance
            ) { index ->
                val workoutSession = lazyPagingItems[index] // Get item by index
                workoutSession?.let {
                    WorkoutHistoryItem(workout = it)
                }
            }

            // Keep load state handling
            when (val refreshState = lazyPagingItems.loadState.refresh) {
                is LoadState.Loading -> {
                    item {
                        Box(modifier = Modifier.fillParentMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                }
                is LoadState.Error -> {
                    item {
                        Box(modifier = Modifier.fillParentMaxSize().padding(16.dp), contentAlignment = Alignment.Center) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    "Error loading history: ${refreshState.error.localizedMessage ?: "Unknown error"}",
                                    color = MaterialTheme.colorScheme.error
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Button(onClick = { lazyPagingItems.retry() }) {
                                    Text("Retry")
                                }
                            }
                        }
                    }
                }
                is LoadState.NotLoading -> {
                    if (lazyPagingItems.itemCount == 0) {
                        item {
                            Box(modifier = Modifier.fillParentMaxSize().padding(16.dp), contentAlignment = Alignment.Center) {
                                Text("No workout history yet.")
                            }
                        }
                    }
                }
            }

            when (val appendState = lazyPagingItems.loadState.append) {
                is LoadState.Loading -> {
                    item {
                        Box(modifier = Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                }
                is LoadState.Error -> {
                    item {
                         Box(modifier = Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                             Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                 Text(
                                     "Error loading more: ${appendState.error.localizedMessage ?: "Unknown error"}",
                                     color = MaterialTheme.colorScheme.error,
                                     modifier = Modifier.padding(8.dp)
                                 )
                                 Button(onClick = { lazyPagingItems.retry() }) {
                                     Text("Retry")
                                 }
                             }
                         }
                    }
                }
                is LoadState.NotLoading -> Unit
            }
        }
    }
}

@Composable
fun WorkoutHistoryItem(workout: WorkoutSession) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
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
            
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                horizontalArrangement = Arrangement.SpaceAround,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                StatItem("REPS", workout.repetitions?.toString() ?: "N/A")
                StatItem("TIME", if (workout.durationSeconds != null) "${workout.durationSeconds}s" else "N/A")
                StatItem("GRADE", workout.grade.toString(), highlight = true)
            }
        }
    }
}

@Composable
fun StatItem(label: String, value: String, highlight: Boolean = false) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            value,
            style = MaterialTheme.typography.bodyLarge,
            color = if (highlight) PtAccent else PtCommandBlack,
            fontWeight = if (highlight) androidx.compose.ui.text.font.FontWeight.Bold else androidx.compose.ui.text.font.FontWeight.Normal
        )
    }
}

fun formatDateTime(dateTimeString: String?): String {
    if (dateTimeString == null) return "N/A"
    return try {
        val offsetDateTime = OffsetDateTime.parse(dateTimeString)
        val formatter = DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")
        offsetDateTime.format(formatter)
    } catch (e: Exception) {
        dateTimeString
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true, name = "History Screen Empty")
@Composable
fun HistoryScreenPreviewEmpty() {
    PTChampionTheme {
        Scaffold(topBar = { TopAppBar(title = { Text("Workout History") }) }) {
            Box(modifier = Modifier.padding(it).fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No workout history yet.")
            }
        }
    }
}

@Preview(showBackground = true, name = "Workout History Item")
@Composable
fun WorkoutHistoryItemPreview() {
    PTChampionTheme {
        WorkoutHistoryItem(
            workout = WorkoutSession(
                id = 1,
                userId = 1,
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