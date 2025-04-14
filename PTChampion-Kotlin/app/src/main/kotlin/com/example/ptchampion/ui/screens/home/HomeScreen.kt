package com.example.ptchampion.ui.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Leaderboard
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = viewModel(),
    // Add navigation callbacks if needed
    // onNavigateToExerciseList: () -> Unit,
) {
    val uiState by viewModel.uiState.collectAsState()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Tactical Cream background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp), // 20px global padding per style guide
            horizontalAlignment = Alignment.Start
        ) {
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = PtAccent) // Brass Gold color
                }
            } else if (uiState.error != null) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Error: ${uiState.error}",
                        color = MaterialTheme.colorScheme.error
                    )
                }
            } else {
                // Welcome Message - Using UPPERCASE headings as per style guide
                uiState.userName?.let {
                    Text(
                        text = "WELCOME, ${it.uppercase()}",
                        style = MaterialTheme.typography.headlineMedium,
                        color = PtCommandBlack
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Quick Actions Section
                Text(
                    text = "QUICK ACTIONS",
                    style = MaterialTheme.typography.titleLarge,
                    color = PtSecondaryText
                )
                Spacer(modifier = Modifier.height(12.dp))

                // Quick Action Buttons
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(quickActionItems) { item ->
                        QuickActionButton(
                            icon = item.icon,
                            label = item.label
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(32.dp))

                // Recent Activity Section
                Text(
                    text = "RECENT ACTIVITY",
                    style = MaterialTheme.typography.titleLarge,
                    color = PtSecondaryText
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                // Recent Activity Card
                RecentActivityCard()
            }
        }
    }
}

@Composable
fun QuickActionButton(
    icon: ImageVector,
    label: String
) {
    ElevatedButton(
        onClick = { /* TODO: Handle click */ },
        modifier = Modifier.size(width = 120.dp, height = 96.dp),
        colors = ButtonDefaults.elevatedButtonColors(
            containerColor = PtBackground,
            contentColor = PtCommandBlack
        ),
        elevation = ButtonDefaults.elevatedButtonElevation(
            defaultElevation = 1.dp, // Soft subtle shadow per styling guide
            pressedElevation = 0.dp
        ),
        shape = RoundedCornerShape(12.dp) // Card radius per styling guide
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = PtAccent,
                modifier = Modifier.size(36.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall.copy(
                    color = PtSecondaryText
                ),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun RecentActivityCard() {
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
        Column(
            modifier = Modifier.padding(16.dp) // 16px padding per styling guide
        ) {
            // Session heading with stats display
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "LAST WORKOUT",
                    style = MaterialTheme.typography.titleMedium,
                    color = PtCommandBlack
                )
                
                Text(
                    text = "April 13, 2025",
                    style = MaterialTheme.typography.bodySmall,
                    color = PtSecondaryText
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 3-column layout for metrics as per styling guide
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Exercise Type
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "EXERCISE",
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        text = "Push-ups",
                        style = MaterialTheme.typography.displaySmall,
                        color = PtCommandBlack
                    )
                }
                
                // Reps
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "REPS",
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        text = "24",
                        style = MaterialTheme.typography.displaySmall,
                        color = PtCommandBlack
                    )
                }
                
                // Score
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "SCORE",
                        style = MaterialTheme.typography.labelSmall,
                        color = PtSecondaryText
                    )
                    Text(
                        text = "92",
                        style = MaterialTheme.typography.displaySmall,
                        color = PtAccent // Brass Gold for important numbers
                    )
                }
            }
        }
    }
}

// Quick action data class and items
data class QuickActionItem(val icon: ImageVector, val label: String)

private val quickActionItems = listOf(
    QuickActionItem(Icons.Default.FitnessCenter, "START WORKOUT"),
    QuickActionItem(Icons.Default.History, "VIEW HISTORY"),
    QuickActionItem(Icons.Default.DirectionsRun, "TRACK RUN"),
    QuickActionItem(Icons.Default.Leaderboard, "LEADERBOARD")
) 