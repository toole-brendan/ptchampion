package com.example.ptchampion.ui.screens.workoutdetail

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.components.StyledButton
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.domain.model.WorkoutResponse
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import com.example.ptchampion.ui.theme.RobotoMono
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutDetailScreen(
    workoutId: String, // Passed via navigation
    viewModel: WorkoutDetailViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background, // Tactical Cream
        topBar = {
            TopAppBar(
                title = { Text("Workout Details", style = MaterialTheme.typography.headlineSmall) }, // Bebas Neue
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background, // Tactical Cream
                    titleContentColor = MaterialTheme.colorScheme.onBackground, // Command Black
                    navigationIconContentColor = MaterialTheme.colorScheme.onBackground // Command Black
                )
            )
        }
    ) {
        paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            contentAlignment = Alignment.TopCenter // Align content to top
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center), color = PtAccent)
                }
                uiState.error != null -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Error: ${uiState.error}",
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        StyledButton(onClick = { viewModel.retryFetch() }, text = "Retry")
                    }
                }
                uiState.workout != null -> {
                    WorkoutDetailsContent(workout = uiState.workout!!)
                }
                else -> {
                     Text(
                         text = "No workout data available.",
                         modifier = Modifier.align(Alignment.Center),
                         style = MaterialTheme.typography.bodyLarge
                     )
                }
            }
        }
    }
}

@Composable
fun WorkoutDetailsContent(workout: WorkoutResponse, modifier: Modifier = Modifier) {
    // TODO: Fetch Exercise Name based on workout.exerciseId if needed from a repository/map
    // For now, using placeholder logic
    val exerciseName = when (workout.exerciseId) {
        1 -> "Push-ups"
        2 -> "Sit-ups"
        3 -> "Pull-ups"
        4 -> "Running"
        else -> "Exercise ID: ${workout.exerciseId}"
    }.uppercase() // Match heading style

    Column(
        modifier = modifier
            .fillMaxWidth(), // Use fillMaxWidth instead of fillMaxSize here
        horizontalAlignment = Alignment.Start
    ) {
        Text(exerciseName, style = MaterialTheme.typography.headlineMedium) // Bebas Neue Bold 28sp
        Spacer(modifier = Modifier.height(24.dp))

        // Use Roboto Mono for numeric values
        DetailRow("Reps:", "${workout.repetitions ?: 0}", valueStyle = MaterialTheme.typography.displaySmall)
        DetailRow("Duration:", formatDurationSeconds(workout.durationSeconds ?: 0), valueStyle = MaterialTheme.typography.displaySmall)
        DetailRow("Form Score:", String.format("%.1f / 100", workout.formScore ?: 0.0), valueStyle = MaterialTheme.typography.displaySmall)

        Spacer(modifier = Modifier.height(16.dp))
        Divider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 1.dp)
        Spacer(modifier = Modifier.height(16.dp))

        // Use Montserrat for date/time and feedback labels/text
        DetailRow(label = "Started:", value = formatDateTime(workout.createdAt), labelStyle = MaterialTheme.typography.bodySmall, valueStyle = MaterialTheme.typography.bodyMedium)
        DetailRow(label = "Ended:", value = formatDateTime(workout.completedAt), labelStyle = MaterialTheme.typography.bodySmall, valueStyle = MaterialTheme.typography.bodyMedium)

        Spacer(modifier = Modifier.height(24.dp))
        Text("Feedback:", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)) // Subheading style, bold
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "No feedback available", // Static text since feedback field is not available
            style = MaterialTheme.typography.bodyMedium, // Montserrat Regular 14sp
            maxLines = 5,
            overflow = TextOverflow.Ellipsis
            )

        // Display other fields as needed (grade, created_at, etc.)
        // Example:
        // DetailRow("Grade:", workout.grade ?: "N/A", labelStyle = MaterialTheme.typography.bodySmall, valueStyle = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
fun DetailRow(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    labelStyle: TextStyle = MaterialTheme.typography.titleSmall, // Default Montserrat SemiBold 16sp
    valueStyle: TextStyle = MaterialTheme.typography.bodyLarge // Default Montserrat Regular 16sp
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp), // Increased padding
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label.uppercase(), // Uppercase labels per potential card style
            style = labelStyle,
            color = MaterialTheme.colorScheme.secondary, // Tactical Gray
            modifier = Modifier.width(120.dp) // Wider fixed width for alignment
        )
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = value,
            style = valueStyle, // Use passed style (Roboto Mono or Montserrat)
            color = if (valueStyle.fontFamily == RobotoMono) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onBackground
            // Use Accent (Brass Gold) for numbers, Command Black for text
        )
    }
}

// Helper to format duration from seconds
private fun formatDurationSeconds(totalSeconds: Int): String {
    if (totalSeconds < 0) return "00:00:00"
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return String.format("%02d:%02d:%02d", hours, minutes, seconds)
}

// Helper function to format date/time string
private fun formatDateTime(dateTimeString: String?): String { // Change parameter type back to String?
    if (dateTimeString.isNullOrBlank()) return "N/A"
    return try {
        val offsetDateTime = OffsetDateTime.parse(dateTimeString) // Parse the string
        val formatter = DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")
        offsetDateTime.format(formatter)
    } catch (e: Exception) {
        dateTimeString // Fallback to original string
    }
} 