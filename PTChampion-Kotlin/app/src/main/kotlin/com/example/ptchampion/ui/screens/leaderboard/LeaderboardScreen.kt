package com.example.ptchampion.ui.screens.leaderboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.LeaderboardEntry
import androidx.compose.material3.Divider

@Composable
fun LeaderboardScreen(
    viewModel: LeaderboardViewModel = viewModel()
) {
    val state = viewModel.state.value

    Column(modifier = Modifier.fillMaxSize()) {
        // Exercise Type Selector (e.g., Tabs or Buttons)
        ExerciseTypeSelector(state.selectedExerciseType) {
            viewModel.selectExerciseType(it)
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Content Area (Loading, Error, or List)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            contentAlignment = Alignment.TopCenter
        ) {
            when {
                state.isLoading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                state.error != null -> {
                    Text(
                        text = "Error: ${state.error}",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                state.leaderboard.isEmpty() -> {
                    Text("No leaderboard data available.", modifier = Modifier.align(Alignment.Center))
                }
                else -> {
                    LeaderboardList(leaderboard = state.leaderboard)
                }
            }
        }
    }
}

@Composable
fun ExerciseTypeSelector(
    selectedType: ExerciseType,
    onTypeSelected: (ExerciseType) -> Unit
) {
    // Using TabRow for selection
    val exerciseTypes = ExerciseType.values()
    val selectedTabIndex = exerciseTypes.indexOf(selectedType)

    TabRow(selectedTabIndex = selectedTabIndex) {
        exerciseTypes.forEachIndexed { index, type ->
            Tab(
                selected = selectedTabIndex == index,
                onClick = { onTypeSelected(type) },
                text = { Text(type.displayName) }
            )
        }
    }
}

@Composable
fun LeaderboardList(leaderboard: List<LeaderboardEntry>) {
    LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        itemsIndexed(leaderboard) { index, entry ->
            LeaderboardItem(rank = index + 1, entry = entry)
            if (index < leaderboard.size - 1) {
                Divider()
            }
        }
    }
}

@Composable
fun LeaderboardItem(rank: Int, entry: LeaderboardEntry) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "#$rank",
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.width(40.dp)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(text = entry.displayName, fontWeight = FontWeight.SemiBold)
            Text(text = "@${entry.username}", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = entry.score.toString(),
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )
    }
} 