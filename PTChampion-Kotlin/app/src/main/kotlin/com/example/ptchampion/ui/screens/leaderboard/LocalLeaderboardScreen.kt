package com.example.ptchampion.ui.screens.leaderboard

import android.Manifest
import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.domain.model.ExerciseResponse
import com.example.ptchampion.domain.model.LocalLeaderboardEntry
import com.example.ptchampion.ui.theme.PTChampionTheme
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtPrimaryText
import com.example.ptchampion.ui.theme.PtSecondaryText

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
                Button(
                    onClick = { showRationaleDialog = false },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = PtAccent,
                        contentColor = PtCommandBlack
                    )
                ) {
                    Text("GRANT PERMISSION")
                }
            },
            dismissButton = {
                Button(
                    onClick = { showRationaleDialog = false },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = PtAccent,
                        contentColor = PtCommandBlack
                    )
                ) {
                    Text("DISMISS")
                }
            }
        )
    }
    // --- End Rationale Dialog ---

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Tactical Cream background
    ) {
        Scaffold(
            topBar = { 
                TopAppBar(
                    title = { 
                        Text(
                            "LOCAL LEADERBOARD",
                            color = PtCommandBlack
                        ) 
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = PtBackground,
                        titleContentColor = PtCommandBlack
                    )
                ) 
            }
        ) { paddingValues ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .padding(20.dp), // 20px global padding per style guide
            ) {
                // Section title
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = null,
                        tint = PtAccent,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "NEARBY COMPETITORS",
                        style = MaterialTheme.typography.titleLarge,
                        color = PtSecondaryText
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))

                // --- Exercise Selector Dropdown ---
                if (uiState.exercises.isNotEmpty()) {
                    val selectedExerciseName = uiState.exercises.find { it.id == uiState.selectedExerciseId }?.name ?: "Select Exercise"
                    ExposedDropdownMenuBox(
                        expanded = uiState.isExerciseDropdownExpanded,
                        onExpandedChange = { viewModel.toggleExerciseDropdown(!uiState.isExerciseDropdownExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 20.dp)
                    ) {
                        OutlinedTextField(
                            value = selectedExerciseName,
                            onValueChange = {}, // Read-only
                            readOnly = true,
                            label = { Text("EXERCISE TYPE") },
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = PtAccent,
                                unfocusedBorderColor = PtSecondaryText,
                                focusedLabelColor = PtAccent,
                                unfocusedLabelColor = PtSecondaryText,
                                cursorColor = PtAccent,
                                focusedTextColor = PtCommandBlack,
                                unfocusedTextColor = PtCommandBlack
                            ),
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
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Text(
                                "Location permission is required for local leaderboards.",
                                textAlign = TextAlign.Center,
                                color = PtCommandBlack
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = { /* Permission request logic */ },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = PtAccent,
                                    contentColor = PtCommandBlack
                                )
                            ) {
                                Text("GRANT PERMISSION")
                            }
                        }
                    }
                    uiState.isLoading -> {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(color = PtAccent) // Brass Gold
                        }
                    }
                    uiState.error != null -> {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    "Error: ${uiState.error}", 
                                    color = MaterialTheme.colorScheme.error,
                                    textAlign = TextAlign.Center
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Button(
                                    onClick = { viewModel.fetchLocationAndLoadLeaderboard() },
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = PtAccent,
                                        contentColor = PtCommandBlack
                                    )
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Refresh,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("RETRY")
                                }
                            }
                        }
                    }
                    uiState.leaderboardEntries.isEmpty() -> {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(
                                "No local leaderboard entries found for this exercise near you.",
                                color = PtSecondaryText,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                    else -> {
                        // Header row for leaderboard
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp, horizontal = 16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "COMPETITOR",
                                style = MaterialTheme.typography.labelSmall,
                                color = PtSecondaryText
                            )
                            Text(
                                text = "SCORE",
                                style = MaterialTheme.typography.labelSmall,
                                color = PtSecondaryText
                            )
                        }
                        
                        Divider(color = PtSecondaryText.copy(alpha = 0.2f))
                        
                        // Leaderboard list
                        LazyColumn(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(12.dp) // 12px card gap per style guide
                        ) {
                            itemsIndexed(uiState.leaderboardEntries) { index, entry ->
                                LeaderboardItem(
                                    rank = index + 1,
                                    entry = entry
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LeaderboardItem(
    rank: Int,
    entry: LocalLeaderboardEntry
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = PtBackground
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
            // Rank indicator - circular with brass gold background
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(if (rank <= 3) PtAccent else PtSecondaryText.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = rank.toString(),
                    style = MaterialTheme.typography.labelLarge,
                    color = if (rank <= 3) PtCommandBlack else PtSecondaryText
                )
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Competitor name
            Text(
                text = entry.displayName ?: entry.username,
                style = MaterialTheme.typography.titleMedium,
                color = PtCommandBlack,
                modifier = Modifier.weight(1f)
            )
            
            // Score with mono font for numbers per styling guide
            Text(
                text = entry.score.toString(),
                style = MaterialTheme.typography.displaySmall,
                color = if (rank <= 3) PtAccent else PtCommandBlack // Top 3 scores in Brass Gold
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true)
@Composable
fun LocalLeaderboardScreenPreview() {
    PTChampionTheme {
        Surface(color = PtBackground) {
            Scaffold(
                topBar = { 
                    TopAppBar(
                        title = { Text("LOCAL LEADERBOARD", color = PtCommandBlack) },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = PtBackground,
                            titleContentColor = PtCommandBlack
                        )
                    ) 
                }
            ) {
                Box(
                    modifier = Modifier
                        .padding(it)
                        .fillMaxSize()
                        .padding(20.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "No leaderboard data available",
                        color = PtSecondaryText,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
} 