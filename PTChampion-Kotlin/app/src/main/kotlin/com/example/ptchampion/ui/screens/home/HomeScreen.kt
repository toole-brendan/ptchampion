package com.example.ptchampion.ui.screens.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = viewModel(),
    // Add navigation callbacks if needed (e.g., navigateToExerciseList)
    // onNavigateToExerciseList: () -> Unit,
) {
    val uiState by viewModel.uiState.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (uiState.isLoading) {
                CircularProgressIndicator()
            } else if (uiState.error != null) {
                Text(text = "Error: ${uiState.error}", color = MaterialTheme.colorScheme.error)
            } else {
                // Welcome Message
                uiState.userName?.let {
                    Text(text = "Welcome, $it!", style = MaterialTheme.typography.headlineMedium)
                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Quick Actions Section (Placeholder)
                Text(text = "Quick Actions", style = MaterialTheme.typography.titleLarge)
                Spacer(modifier = Modifier.height(8.dp))
                // TODO: Add Buttons or Cards for quick actions like "Start Workout", "View History"
                Text(text = "(Start Workout, View History, etc.)", style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.height(32.dp))

                // Recent Activity Section (Placeholder)
                Text(text = "Recent Activity", style = MaterialTheme.typography.titleLarge)
                Spacer(modifier = Modifier.height(8.dp))
                // TODO: Add a list or cards showing recent workouts/achievements
                Text(text = "(Your last workout details...)", style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
} 