package com.ptchampion.ui.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.UserExercise
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * History screen showing past exercises
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onNavigateBack: () -> Unit,
    viewModel: HistoryViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showFilterMenu by remember { mutableStateOf(false) }
    
    // Show error
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Exercise History") },
                actions = {
                    // Filter button
                    IconButton(
                        onClick = { showFilterMenu = true }
                    ) {
                        Icon(
                            imageVector = Icons.Default.FilterList,
                            contentDescription = "Filter"
                        )
                    }
                    
                    // Filter dropdown menu
                    DropdownMenu(
                        expanded = showFilterMenu,
                        onDismissRequest = { showFilterMenu = false }
                    ) {
                        // All exercises option
                        DropdownMenuItem(
                            text = { Text("All Exercises") },
                            onClick = {
                                viewModel.filterByType(null)
                                showFilterMenu = false
                            }
                        )
                        
                        // Divider
                        Divider()
                        
                        // Exercise type options
                        val exerciseTypes = uiState.exercises.map { it.type }.distinct()
                        exerciseTypes.forEach { type ->
                            DropdownMenuItem(
                                text = { Text(formatExerciseType(type)) },
                                onClick = {
                                    viewModel.filterByType(type)
                                    showFilterMenu = false
                                }
                            )
                        }
                    }
                    
                    // Refresh button
                    IconButton(
                        onClick = { viewModel.loadData() }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = "Refresh"
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (uiState.filteredUserExercises.isEmpty()) {
                // Empty state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "No exercise history found",
                            style = MaterialTheme.typography.headlineSmall,
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = if (uiState.selectedType != null) {
                                "You haven't completed any ${formatExerciseType(uiState.selectedType)} exercises yet"
                            } else {
                                "Complete some exercises to see your history here"
                            },
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            } else {
                // Filter chips
                Column(
                    modifier = Modifier.fillMaxSize()
                ) {
                    // Current filter indicator
                    if (uiState.selectedType != null) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Showing:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            
                            Spacer(modifier = Modifier.width(8.dp))
                            
                            FilterChip(
                                selected = true,
                                onClick = { viewModel.filterByType(null) },
                                label = { Text(formatExerciseType(uiState.selectedType)) }
                            )
                        }
                    }
                    
                    // Exercise history list
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(uiState.filteredUserExercises) { userExercise ->
                            val exercise = viewModel.getExerciseById(userExercise.exerciseId)
                            if (exercise != null) {
                                ExerciseHistoryItem(
                                    userExercise = userExercise,
                                    exercise = exercise
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Exercise history item card
 */
@Composable
fun ExerciseHistoryItem(
    userExercise: UserExercise,
    exercise: Exercise
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                
                AssistChip(
                    onClick = { },
                    label = { Text("Score: ${userExercise.score}") }
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Exercise details
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    // Date
                    Text(
                        text = "Date: ${formatDate(userExercise.date)}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    // Exercise details
                    when {
                        userExercise.reps != null -> {
                            Text(
                                text = "Reps: ${userExercise.reps}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        userExercise.timeInSeconds != null -> {
                            Text(
                                text = "Time: ${formatTime(userExercise.timeInSeconds)}",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            
                            if (userExercise.distance != null) {
                                Spacer(modifier = Modifier.height(4.dp))
                                
                                Text(
                                    text = "Distance: ${String.format("%.2f", userExercise.distance)} miles",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                    }
                }
                
                // Performance rating
                Text(
                    text = getScoreRating(userExercise.score),
                    style = MaterialTheme.typography.titleMedium,
                    color = getScoreColor(userExercise.score)
                )
            }
        }
    }
}

/**
 * Format date from string to display format
 */
private fun formatDate(dateStr: String): String {
    return try {
        val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        val outputFormat = SimpleDateFormat("MMM d, yyyy", Locale.US)
        val date = inputFormat.parse(dateStr)
        outputFormat.format(date ?: Date())
    } catch (e: Exception) {
        dateStr // Return original if parsing fails
    }
}

/**
 * Format time in seconds to MM:SS display
 */
private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return "$minutes:${remainingSeconds.toString().padStart(2, '0')}"
}

/**
 * Get color based on score
 */
@Composable
private fun getScoreColor(score: Int): androidx.compose.ui.graphics.Color {
    return when {
        score >= 90 -> MaterialTheme.colorScheme.primary
        score >= 80 -> MaterialTheme.colorScheme.tertiary
        score >= 65 -> MaterialTheme.colorScheme.secondary
        score >= 50 -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.7f)
        else -> MaterialTheme.colorScheme.error
    }
}

/**
 * Get score rating
 */
private fun getScoreRating(score: Int): String {
    return when {
        score >= 90 -> "Excellent"
        score >= 80 -> "Good"
        score >= 65 -> "Satisfactory"
        score >= 50 -> "Marginal"
        else -> "Poor"
    }
}

/**
 * Format exercise type for display
 */
private fun formatExerciseType(type: String): String {
    return when (type.lowercase()) {
        "pushup" -> "Push-ups"
        "pullup" -> "Pull-ups"
        "situp" -> "Sit-ups"
        "run" -> "2-Mile Run"
        else -> type.replaceFirstChar { it.uppercase() }
    }
}