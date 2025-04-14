package com.example.ptchampion.ui.screens.leaderboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.ui.theme.*
import java.util.concurrent.TimeUnit

@Composable
fun LeaderboardScreen(
    viewModel: LeaderboardViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Tactical Cream
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp)
        ) {
            // Screen Title
            Text(
                text = "LEADERBOARD",
                style = MaterialTheme.typography.headlineMedium,
                color = PtCommandBlack,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            // Local/Global Toggle Buttons
            LeaderboardTypeToggle(selectedType = uiState.selectedLeaderboardType, onTypeSelected = viewModel::selectLeaderboardType)
            Spacer(modifier = Modifier.height(16.dp))

            // Header for the list section
            ListHeader(leaderboardType = uiState.selectedLeaderboardType)
            Spacer(modifier = Modifier.height(8.dp))

            // Exercise Type Dropdown
            ExerciseTypeDropdown(selectedType = uiState.selectedExerciseType, availableTypes = uiState.availableExerciseTypes, onTypeSelected = viewModel::selectExerciseType)
            Spacer(modifier = Modifier.height(16.dp))

            // Leaderboard List or Loading/Error/Empty State
            when {
                uiState.isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = PtAccent)
                    }
                }
                uiState.error != null -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = "Error: ${uiState.error}", 
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center
                        )
                    }
                }
                uiState.leaderboardEntries.isEmpty() -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = "No leaderboard data found for ${uiState.selectedExerciseType}.",
                            color = PtSecondaryText,
                             textAlign = TextAlign.Center
                        )
                    }
                }
                else -> {
                    // Column Headers
                    LeaderboardHeaderRow(isTimeBased = uiState.selectedExerciseType == "running")
                    Spacer(modifier = Modifier.height(8.dp))
                    // List
                    LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(uiState.leaderboardEntries) { entry ->
                            LeaderboardListItem(
                                entry = entry,
                                isCurrentUser = entry.userId == uiState.currentUserId,
                                isTimeBased = uiState.selectedExerciseType == "running"
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LeaderboardTypeToggle(
    selectedType: LeaderboardType,
    onTypeSelected: (LeaderboardType) -> Unit
) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Button(
            onClick = { onTypeSelected(LeaderboardType.LOCAL) },
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(topStart = 8.dp, bottomStart = 8.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedType == LeaderboardType.LOCAL) PtPrimaryText else PtBackground,
                contentColor = PtAccent // Keep this for potential icon tinting if icons were added
            ),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = if (selectedType == LeaderboardType.LOCAL) 2.dp else 0.dp)
        ) {
            Text(
                text = "LOCAL",
                fontWeight = if (selectedType == LeaderboardType.LOCAL) FontWeight.Bold else FontWeight.Normal,
                fontSize = if (selectedType == LeaderboardType.LOCAL) 16.sp else 14.sp,
                color = if (selectedType == LeaderboardType.LOCAL) PtAccent else PtPrimaryText // Explicitly set text color
            )
        }
        Button(
            onClick = { onTypeSelected(LeaderboardType.GLOBAL) },
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(topEnd = 8.dp, bottomEnd = 8.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedType == LeaderboardType.GLOBAL) PtPrimaryText else PtBackground,
                contentColor = PtAccent // Keep this for potential icon tinting
            ),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = if (selectedType == LeaderboardType.GLOBAL) 2.dp else 0.dp)
        ) {
            Text(
                text = "GLOBAL",
                fontWeight = if (selectedType == LeaderboardType.GLOBAL) FontWeight.Bold else FontWeight.Normal,
                fontSize = if (selectedType == LeaderboardType.GLOBAL) 16.sp else 14.sp,
                color = if (selectedType == LeaderboardType.GLOBAL) PtAccent else PtPrimaryText // Explicitly set text color
            )
        }
    }
}

@Composable
fun ListHeader(leaderboardType: LeaderboardType) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (leaderboardType == LeaderboardType.LOCAL) {
            Icon(
                imageVector = Icons.Default.LocationOn,
                contentDescription = "Nearby",
                tint = PtAccent,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
        }
        Text(
            text = if (leaderboardType == LeaderboardType.LOCAL) "NEARBY COMPETITORS" else "GLOBAL RANKING",
            style = MaterialTheme.typography.titleMedium,
            color = PtSecondaryText,
            fontWeight = FontWeight.Bold
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExerciseTypeDropdown(
    selectedType: String,
    availableTypes: List<String>,
    onTypeSelected: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = !expanded },
        modifier = Modifier.fillMaxWidth()
    ) {
        OutlinedTextField(
            value = selectedType.replaceFirstChar { it.uppercase() },
            onValueChange = {}, // Read-only
            readOnly = true,
            label = { Text("EXERCISE TYPE", style = MaterialTheme.typography.labelSmall, color = PtSecondaryText) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor() // Important for positioning the dropdown
                .fillMaxWidth(),
            shape = RoundedCornerShape(8.dp),
            colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                focusedBorderColor = PtAccent,
                unfocusedBorderColor = PtSecondaryText.copy(alpha = 0.5f),
                focusedLabelColor = PtAccent,
                cursorColor = PtAccent,
                focusedTrailingIconColor = PtAccent,
            )
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(PtBackground) // Cream background for dropdown menu
        ) {
            availableTypes.forEach { type ->
                DropdownMenuItem(
                    text = { Text(type.replaceFirstChar { it.uppercase() }, color = PtCommandBlack) },
                    onClick = {
                        onTypeSelected(type)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
fun LeaderboardHeaderRow(isTimeBased: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Rank column is implicit
        Text(
            text = "COMPETITOR",
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = if (isTimeBased) "TIME" else "SCORE",
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText,
            textAlign = TextAlign.End
        )
    }
}

@Composable
fun LeaderboardListItem(
    entry: LeaderboardEntry,
    isCurrentUser: Boolean,
    isTimeBased: Boolean
) {
    val backgroundColor = if (isCurrentUser) PtArmyTan.copy(alpha = 0.3f) else PtBackground
    val rankColor = when (entry.rank) {
        1 -> Color(0xFFFFD700) // Gold
        2 -> Color(0xFFC0C0C0) // Silver
        3 -> Color(0xFFCD7F32) // Bronze
        else -> PtSecondaryText
    }
    val rankBackgroundColor = when (entry.rank) {
        1, 2, 3 -> rankColor.copy(alpha = 0.8f)
        else -> PtSecondaryText.copy(alpha = 0.1f)
    }
    val rankTextColor = when (entry.rank) {
        1, 2, 3 -> PtCommandBlack
        else -> PtSecondaryText
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isCurrentUser) 2.dp else 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Rank Circle
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(rankBackgroundColor),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = entry.rank.toString(),
                    fontWeight = FontWeight.Bold,
                    color = rankTextColor,
                    fontSize = 14.sp
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Competitor Name
            Text(
                text = entry.competitorName,
                style = MaterialTheme.typography.bodyLarge,
                color = PtCommandBlack,
                modifier = Modifier.weight(1f),
                fontWeight = if (isCurrentUser) FontWeight.Bold else FontWeight.Normal
            )

            Spacer(modifier = Modifier.width(8.dp))

            // Score or Time
            val scoreOrTimeText = if (isTimeBased) {
                 entry.timeMillis?.let { formatDuration(it) } ?: "--:--"
            } else {
                entry.score?.toString() ?: "-"
            }
            Text(
                text = scoreOrTimeText,
                style = MaterialTheme.typography.bodyLarge,
                color = if (isCurrentUser) PtAccent else PtCommandBlack,
                 fontWeight = FontWeight.Bold,
                 textAlign = TextAlign.End
            )
        }
    }
}

// Helper function to format milliseconds to MM:SS
fun formatDuration(millis: Long): String {
    val minutes = TimeUnit.MILLISECONDS.toMinutes(millis)
    val seconds = TimeUnit.MILLISECONDS.toSeconds(millis) % 60
    return String.format("%d:%02d", minutes, seconds)
} 