package com.example.ptchampion.ui.screens.exercise

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.ptchampion.R

/**
 * Running tracking screen with watch integration
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RunningTrackingScreen(
    viewModel: RunningTrackingViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val trackingStatus by viewModel.trackingStatus.collectAsStateWithLifecycle()
    val watchConnected by viewModel.watchConnectionState.collectAsStateWithLifecycle()
    
    // Collect other states needed
    val watchName by viewModel.connectedWatchName.collectAsStateWithLifecycle()
    val watchBatteryLevel by viewModel.watchBatteryLevel.collectAsStateWithLifecycle()
    val currentHeartRate by viewModel.currentHeartRate.collectAsStateWithLifecycle()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Running Session") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Add watch connection status indicator
            if (watchConnected) {
                WatchConnectionBanner(
                    watchName = watchName,
                    batteryLevel = watchBatteryLevel
                )
            }
            
            // Main content
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier.weight(1f)
            ) {
                // Duration display
                StatDisplay(
                    label = "DURATION",
                    value = uiState.formattedDuration
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Distance display
                StatDisplay(
                    label = "DISTANCE",
                    value = uiState.formattedDistance
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Add heart rate display if watch is connected
                if (watchConnected) {
                    HeartRateDisplay(
                        heartRate = currentHeartRate
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                }
                
                // Add pace display
                StatDisplay(
                    label = "PACE",
                    value = uiState.formattedPace
                )
            }
            
            // Controls
            Row(
                horizontalArrangement = Arrangement.SpaceEvenly,
                modifier = Modifier.fillMaxWidth()
            ) {
                when (trackingStatus) {
                    TrackingStatus.IDLE -> {
                        Button(
                            onClick = { viewModel.startTracking() },
                            modifier = Modifier.width(160.dp)
                        ) {
                            Icon(Icons.Default.PlayArrow, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Start")
                        }
                    }
                    TrackingStatus.RUNNING -> {
                        Button(
                            onClick = { viewModel.pauseTracking() },
                            modifier = Modifier.width(160.dp)
                        ) {
                            Icon(Icons.Default.Pause, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Pause")
                        }
                        
                        Button(
                            onClick = { viewModel.stopTracking() },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            ),
                            modifier = Modifier.width(160.dp)
                        ) {
                            Icon(Icons.Default.Stop, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Stop")
                        }
                    }
                    TrackingStatus.PAUSED -> {
                        Button(
                            onClick = { viewModel.resumeTracking() },
                            modifier = Modifier.width(160.dp)
                        ) {
                            Icon(Icons.Default.PlayArrow, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Resume")
                        }
                        
                        Button(
                            onClick = { viewModel.stopTracking() },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            ),
                            modifier = Modifier.width(160.dp)
                        ) {
                            Icon(Icons.Default.Stop, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Stop")
                        }
                    }
                }
            }
        }
    }
}

/**
 * Display a statistic with a label and value
 */
@Composable
fun StatDisplay(
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.secondary
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.displayMedium,
            color = MaterialTheme.colorScheme.primary
        )
    }
}

/**
 * Display a banner showing connected watch information
 */
@Composable
fun WatchConnectionBanner(
    watchName: String?,
    batteryLevel: Int?
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 8.dp)
            .background(
                color = MaterialTheme.colorScheme.primaryContainer,
                shape = RoundedCornerShape(8.dp)
            )
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.Watch,
            contentDescription = "Connected Watch",
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = watchName ?: "GPS Watch",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )
        Spacer(modifier = Modifier.weight(1f))
        
        // Battery indicator if available
        batteryLevel?.let {
            Icon(
                imageVector = when {
                    it > 80 -> Icons.Default.BatteryFull
                    it > 40 -> Icons.Default.BatteryStd
                    it > 15 -> Icons.Default.BatteryAlert
                    else -> Icons.Default.BatteryAlert
                },
                contentDescription = "Battery Level: $it%",
                tint = when {
                    it <= 15 -> MaterialTheme.colorScheme.error
                    else -> MaterialTheme.colorScheme.onPrimaryContainer
                }
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "$it%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

/**
 * Display heart rate information
 */
@Composable
fun HeartRateDisplay(heartRate: Int?) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = "HEART RATE",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.secondary
        )
        Spacer(modifier = Modifier.height(4.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Default.Favorite,
                contentDescription = null,
                tint = Color.Red,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = heartRate?.toString() ?: "--",
                style = MaterialTheme.typography.displayMedium,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = " bpm",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier
                    .align(Alignment.Bottom)
                    .padding(bottom = 8.dp)
            )
        }
    }
} 