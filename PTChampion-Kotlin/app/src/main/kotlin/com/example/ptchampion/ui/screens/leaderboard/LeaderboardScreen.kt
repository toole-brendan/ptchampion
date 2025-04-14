package com.example.ptchampion.ui.screens.leaderboard

import android.Manifest
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.domain.model.LeaderboardEntry
import com.example.ptchampion.ui.theme.*
import com.google.accompanist.permissions.*

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun LeaderboardScreen(
    viewModel: LeaderboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val locationPermissionsState = rememberMultiplePermissionsState(
        listOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    )

    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current

    val onSelectLocalScope: () -> Unit = {
        if (locationPermissionsState.allPermissionsGranted) {
            viewModel.selectScope(LeaderboardScope.LOCAL)
        } else {
            locationPermissionsState.launchMultiplePermissionRequest()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) {
        Surface(
            modifier = Modifier.fillMaxSize().padding(it),
            color = PtBackground
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp)
            ) {
                Text(
                    text = "LEADERBOARD",
                    style = MaterialTheme.typography.headlineMedium,
                    color = PtCommandBlack,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 16.dp)
                )

                LeaderboardScopeToggle(
                    selectedScope = uiState.selectedScope,
                    onScopeSelected = {
                        scope ->
                        if (scope == LeaderboardScope.LOCAL) {
                            onSelectLocalScope()
                        } else {
                            viewModel.selectScope(LeaderboardScope.GLOBAL)
                        }
                    }
                )
                Spacer(modifier = Modifier.height(16.dp))

                if (!locationPermissionsState.allPermissionsGranted && locationPermissionsState.shouldShowRationale) {
                     Snackbar(
                        modifier = Modifier.padding(bottom = 8.dp),
                        action = {
                            Button(onClick = { locationPermissionsState.launchMultiplePermissionRequest() }) {
                                Text("Request Again")
                            }
                        }
                    ) {
                        Text("Location permission is needed to show the local leaderboard.")
                    }
                }

                ListHeader(leaderboardScope = uiState.selectedScope)
                Spacer(modifier = Modifier.height(8.dp))

                ExerciseTypeDropdown(
                    selectedType = uiState.selectedExerciseType,
                    availableTypes = uiState.availableExerciseTypes,
                    onTypeSelected = viewModel::selectExerciseType
                )
                Spacer(modifier = Modifier.height(16.dp))

                if (uiState.isLoadingLocation) {
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 8.dp)) {
                       CircularProgressIndicator(modifier = Modifier.size(20.dp))
                       Spacer(modifier = Modifier.width(8.dp))
                       Text("Getting location...", style = MaterialTheme.typography.bodySmall)
                    }
                }

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
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                    uiState.leaderboardEntries.isEmpty() -> {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(
                                text = "No leaderboard data found for ${uiState.selectedExerciseType}.",
                                color = PtSecondaryText,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                    else -> {
                        LeaderboardHeaderRow()
                        Spacer(modifier = Modifier.height(8.dp))
                        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(uiState.leaderboardEntries, key = { it.rank }) { entry ->
                                LeaderboardListItem(
                                    entry = entry,
                                    isCurrentUser = uiState.currentUserId != null && entry.userId == uiState.currentUserId
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
fun LeaderboardScopeToggle(
    selectedScope: LeaderboardScope,
    onScopeSelected: (LeaderboardScope) -> Unit
) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Button(
            onClick = { onScopeSelected(LeaderboardScope.LOCAL) },
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(topStart = 8.dp, bottomStart = 8.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedScope == LeaderboardScope.LOCAL) PtCommandBlack else PtBackground,
                contentColor = if (selectedScope == LeaderboardScope.LOCAL) PtAccent else PtCommandBlack
            ),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = if (selectedScope == LeaderboardScope.LOCAL) 2.dp else 0.dp)
        ) {
            Text(
                text = "LOCAL",
                fontWeight = if (selectedScope == LeaderboardScope.LOCAL) FontWeight.Bold else FontWeight.Normal,
                fontSize = 14.sp,
                color = if (selectedScope == LeaderboardScope.LOCAL) PtAccent else PtCommandBlack
            )
        }
        Button(
            onClick = { onScopeSelected(LeaderboardScope.GLOBAL) },
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(topEnd = 8.dp, bottomEnd = 8.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedScope == LeaderboardScope.GLOBAL) PtCommandBlack else PtBackground,
                contentColor = if (selectedScope == LeaderboardScope.GLOBAL) PtAccent else PtCommandBlack
            ),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = if (selectedScope == LeaderboardScope.GLOBAL) 2.dp else 0.dp)
        ) {
            Text(
                text = "GLOBAL",
                fontWeight = if (selectedScope == LeaderboardScope.GLOBAL) FontWeight.Bold else FontWeight.Normal,
                fontSize = 14.sp,
                color = if (selectedScope == LeaderboardScope.GLOBAL) PtAccent else PtCommandBlack
            )
        }
    }
}

@Composable
fun ListHeader(leaderboardScope: LeaderboardScope) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (leaderboardScope == LeaderboardScope.LOCAL) {
            Icon(
                imageVector = Icons.Default.LocationOn,
                contentDescription = "Nearby",
                tint = PtAccent,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
        }
        Text(
            text = if (leaderboardScope == LeaderboardScope.LOCAL) "NEARBY COMPETITORS" else "GLOBAL RANKING",
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
            onValueChange = {},
            readOnly = true,
            label = { Text("EXERCISE TYPE", style = MaterialTheme.typography.labelSmall, color = PtSecondaryText) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor()
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
            modifier = Modifier.background(PtBackground)
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
fun LeaderboardHeaderRow() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "RANK",
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText,
            modifier = Modifier.width(50.dp)
        )
        Text(
            text = "COMPETITOR",
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = "SCORE",
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText,
            textAlign = TextAlign.End,
            modifier = Modifier.width(60.dp)
        )
    }
}

@Composable
fun LeaderboardListItem(
    entry: LeaderboardEntry,
    isCurrentUser: Boolean
) {
    val backgroundColor = if (isCurrentUser) PtArmyTan.copy(alpha = 0.3f) else PtBackground
    val fontWeight = if (isCurrentUser) FontWeight.Bold else FontWeight.Normal
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

            Text(
                text = entry.displayName ?: entry.username,
                style = MaterialTheme.typography.bodyLarge,
                color = PtCommandBlack,
                modifier = Modifier.weight(1f),
                fontWeight = fontWeight
            )

            Spacer(modifier = Modifier.width(8.dp))

            Text(
                text = entry.score.toString(),
                style = MaterialTheme.typography.bodyLarge,
                color = if (isCurrentUser) PtAccent else PtCommandBlack,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.End,
                modifier = Modifier.width(60.dp)
            )
        }
    }
} 