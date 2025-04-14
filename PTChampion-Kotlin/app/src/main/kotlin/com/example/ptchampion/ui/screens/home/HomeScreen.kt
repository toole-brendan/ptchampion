package com.example.ptchampion.ui.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.BluetoothConnected
import androidx.compose.material.icons.outlined.BluetoothDisabled
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ptchampion.ui.theme.*

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = viewModel(),
    onNavigateToExercises: () -> Unit = {},
    onNavigateToPushups: () -> Unit = {},
    onNavigateToRun: () -> Unit = {},
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
                // App Logo
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    // Logo would go here - placeholder
                    Text(
                        text = "PT CHAMPION",
                        style = MaterialTheme.typography.headlineMedium,
                        color = PtCommandBlack,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Welcome Message - Using UPPERCASE headings as per style guide
                uiState.userName?.let {
                    Text(
                        text = "WELCOME, ${it.uppercase()}!",
                        style = MaterialTheme.typography.headlineMedium,
                        color = PtCommandBlack
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Quick Start Section
                Text(
                    text = "QUICK START",
                    style = MaterialTheme.typography.titleLarge,
                    color = PtSecondaryText,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(12.dp))

                // Quick Action Buttons - Now with just two primary actions
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    QuickActionButton(
                        icon = Icons.Default.FitnessCenter,
                        label = "START PUSH-UPS",
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToPushups
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    QuickActionButton(
                        icon = Icons.Default.DirectionsRun,
                        label = "START RUN",
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToRun
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Leaderboard Rank Section
                LeaderboardRankCard(userRank = uiState.userRank)
                
                Spacer(modifier = Modifier.height(24.dp))

                // Recent Activity Section
                Text(
                    text = "RECENT ACTIVITY",
                    style = MaterialTheme.typography.titleLarge,
                    color = PtSecondaryText,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                // Recent Activity Card
                RecentActivityCard(recentWorkout = uiState.recentWorkout)
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Bluetooth Status
                BluetoothStatusIndicator(isConnected = uiState.isBluetoothConnected)
            }
        }
    }
}

@Composable
fun QuickActionButton(
    icon: ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {}
) {
    ElevatedButton(
        onClick = onClick,
        modifier = modifier.height(96.dp),
        colors = ButtonDefaults.elevatedButtonColors(
            containerColor = PtPrimaryText, // Deep Ops Green background
            contentColor = PtBackground // Light text on dark background
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
                tint = PtAccent, // Brass Gold
                modifier = Modifier.size(36.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = PtBackground,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun LeaderboardRankCard(userRank: UserRank? = null) {
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
            // Leaderboard heading
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Leaderboard,
                        contentDescription = null,
                        tint = PtAccent,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "YOUR RANK (${userRank?.exerciseType?.uppercase() ?: "PUSH-UPS"})",
                        style = MaterialTheme.typography.titleMedium,
                        color = PtCommandBlack
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Leaderboard ranks
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                // Global Rank
                RankItem(
                    label = "GLOBAL",
                    rank = "#${userRank?.globalRank ?: 0}",
                    modifier = Modifier.weight(1f)
                )
                
                // Vertical divider
                Divider(
                    modifier = Modifier
                        .height(40.dp)
                        .width(1.dp),
                    color = PtSecondaryText.copy(alpha = 0.3f)
                )
                
                // Local Rank
                RankItem(
                    label = "LOCAL",
                    rank = "#${userRank?.localRank ?: 0}",
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun RankItem(
    label: String,
    rank: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = PtSecondaryText
        )
        Text(
            text = rank,
            style = MaterialTheme.typography.headlineMedium,
            color = PtAccent, // Brass Gold for importance
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun RecentActivityCard(recentWorkout: RecentWorkout? = null) {
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
        if (recentWorkout == null) {
            // No recent workouts
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "NO RECENT WORKOUTS",
                    style = MaterialTheme.typography.titleMedium,
                    color = PtSecondaryText
                )
            }
        } else {
            Column(
                modifier = Modifier.padding(16.dp) // 16px padding per styling guide
            ) {
                // Session heading with stats display
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.FitnessCenter,
                            contentDescription = null,
                            tint = PtAccent,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "LAST WORKOUT",
                            style = MaterialTheme.typography.titleMedium,
                            color = PtCommandBlack
                        )
                    }
                    
                    Text(
                        text = recentWorkout.date,
                        style = MaterialTheme.typography.bodySmall,
                        color = PtSecondaryText
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // 4-column layout for metrics with added duration
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
                            text = recentWorkout.type,
                            style = MaterialTheme.typography.titleMedium,
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
                            text = "${recentWorkout.reps}",
                            style = MaterialTheme.typography.titleMedium,
                            color = PtCommandBlack,
                            fontWeight = FontWeight.Bold
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
                            text = "${recentWorkout.score}",
                            style = MaterialTheme.typography.titleMedium,
                            color = PtAccent, // Brass Gold for important numbers
                            fontWeight = FontWeight.Bold
                        )
                    }
                    
                    // Duration
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "TIME",
                            style = MaterialTheme.typography.labelSmall,
                            color = PtSecondaryText
                        )
                        Text(
                            text = "${recentWorkout.durationMinutes}:${String.format("%02d", recentWorkout.durationSeconds)}",
                            style = MaterialTheme.typography.titleMedium,
                            color = PtCommandBlack
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun BluetoothStatusIndicator(isConnected: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = if (isConnected) 
                Icons.Outlined.BluetoothConnected 
            else 
                Icons.Outlined.BluetoothDisabled,
            contentDescription = if (isConnected) "Bluetooth Connected" else "Bluetooth Disconnected",
            tint = if (isConnected) PtAccent else PtSecondaryText
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = if (isConnected) "HRM CONNECTED" else "NO DEVICE CONNECTED",
            style = MaterialTheme.typography.bodyMedium,
            color = if (isConnected) PtAccent else PtSecondaryText
        )
    }
} 