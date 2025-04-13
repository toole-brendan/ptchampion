package com.example.ptchampion.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.sp

@Composable
fun PlaceholderScreen(screenName: String) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = screenName, fontSize = 24.sp)
    }
}

// Specific screen placeholders calling the generic one
@Composable fun HomeScreen() { PlaceholderScreen(screenName = "Home") }
@Composable fun ExerciseListScreen() { PlaceholderScreen(screenName = "Exercise List") }
@Composable fun ExerciseDetailScreen(exerciseId: String?) { PlaceholderScreen(screenName = "Exercise Detail: $exerciseId") }
@Composable fun LeaderboardScreen() { PlaceholderScreen(screenName = "Leaderboard") }
@Composable fun ProfileScreen() { PlaceholderScreen(screenName = "Profile") }
@Composable fun CameraScreen(exerciseType: String?) { PlaceholderScreen(screenName = "Camera: $exerciseType") } 