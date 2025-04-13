package com.example.ptchampion.ui.screens.leaderboard

import android.Manifest
import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.LocalLeaderboardEntry
import com.example.ptchampion.ui.theme.PTChampionTheme

// TODO: Refactor LeaderboardScreen later to choose between Global and Local
// For now, this screen will focus on Local Leaderboard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LocalLeaderboardScreen(
    exerciseId: Int? = null,
    viewModel: LocalLeaderboardViewModel = androidx.lifecycle.viewmodel.compose.viewModel(
        factory = LocalLeaderboardViewModelFactory(exerciseId)
    )
) {
    val uiState by viewModel.uiState.collectAsState()
    var showRationaleDialog by remember { mutableStateOf(false) }

    // --- Location Permission Handling ---
    LaunchedEffect(Unit) {
        viewModel.onPermissionResult(mapOf(Manifest.permission.ACCESS_FINE_LOCATION to true))
        viewModel.fetchLocationAndLoadLeaderboard()
    }
    // --- End Permission Handling ---

    // --- Rationale Dialog ---
    if (showRationaleDialog) {
        AlertDialog(
            onDismissRequest = { showRationaleDialog = false },
            title = { Text("Location Permission Needed") },
            text = { Text("This app needs access to your location to show leaderboards based on your proximity to other users.") },
            confirmButton = {
                Button(onClick = { 
                    showRationaleDialog = false 
                }) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                Button(onClick = { showRationaleDialog = false }) {
                    Text("Dismiss")
                }
            }
        )
    }
    // --- End Rationale Dialog ---

    Scaffold(
        topBar = { TopAppBar(title = { Text("Local Leaderboard") }) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {

            // --- Exercise Selector Dropdown ---
            if (uiState.exercises.isNotEmpty()) {
                val selectedExerciseName = uiState.exercises.find { it.id == uiState.selectedExerciseId }?.name ?: "Select Exercise"
                @OptIn(ExperimentalMaterial3Api::class)
                ExposedDropdownMenuBox(
                    expanded = uiState.isExerciseDropdownExpanded,
                    onExpandedChange = { viewModel.toggleExerciseDropdown(!uiState.isExerciseDropdownExpanded) },
                    modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
                ) {
                    OutlinedTextField(
                        value = selectedExerciseName,
                        onValueChange = {}, // Read-only
                        readOnly = true,
                        label = { Text("Exercise") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = uiState.isExerciseDropdownExpanded) },
                        modifier = Modifier.menuAnchor() // Important for positioning
                    )
                    ExposedDropdownMenu(
                        expanded = uiState.isExerciseDropdownExpanded,
                        onDismissRequest = { viewModel.toggleExerciseDropdown(false) }
                    ) {
                        uiState.exercises.forEach { exercise ->
                            DropdownMenuItem(
                                text = { Text(exercise.name) },
                                onClick = { viewModel.selectExercise(exercise.id) }
                            )
                        }
                    }
                }
            }
            // --- End Exercise Selector ---

            when {
                false -> {
                    Column(
                        modifier = Modifier.fillMaxSize().padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            "Location permission is required for local leaderboards.",
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(onClick = { 
                            // Always request if not granted and rationale not shown
                            // if (!locationPermissionState.shouldShowRationale) { // Commented out
                            //    locationPermissionState.launchMultiplePermissionRequest() // Commented out
                            // } else {
                            //    // If rationale should be shown, trigger the dialog display again
                            //    showRationaleDialog = true 
                            // }
                        }) {
                            Text("Grant Permission")
                        }
                        // TODO: Add message/button to go to settings if permission denied permanently
                    }
                }
                uiState.isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                uiState.error != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize().padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                "Error: ${uiState.error}", 
                                color = MaterialTheme.colorScheme.error,
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )
                            // Add a retry button if the error is location-related?
                            if (uiState.error?.contains("location", ignoreCase = true) == true) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Button(onClick = { viewModel.fetchLocationAndLoadLeaderboard() }) {
                                    Text("Retry")
                                }
                            }
                        }
                    }
                }
                uiState.leaderboardEntries.isEmpty() -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No local leaderboard entries found for this exercise near you.")
                    }
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(uiState.leaderboardEntries) { entry ->
                            LocalLeaderboardListItem(entry = entry)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LocalLeaderboardListItem(entry: LocalLeaderboardEntry) {
    Card(modifier = Modifier.fillMaxWidth(), elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(entry.displayName ?: entry.username, style = MaterialTheme.typography.bodyLarge)
            Text("Score: ${entry.score}", style = MaterialTheme.typography.bodyLarge)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true)
@Composable
fun LocalLeaderboardScreenPreview() {
    PTChampionTheme {
        Scaffold(topBar = { TopAppBar(title = { Text("Local Leaderboard") }) }) {
            Box(modifier = Modifier.padding(it).fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Local Leaderboard Preview (No Data)")
            }
        }
    }
} 