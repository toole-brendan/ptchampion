package com.example.ptchampion.ui.screens.running

import android.Manifest
import android.os.Build
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.components.StyledButton
import com.example.ptchampion.ui.theme.PtAccent
import com.google.accompanist.permissions.*
import java.util.concurrent.TimeUnit

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun RunningTrackingScreen(
    viewModel: RunningTrackingViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val trackingStatus by viewModel.trackingStatus.collectAsState()

    // Permissions handling
    val locationPermissions = listOf(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION
    )
    val locationPermissionState = rememberMultiplePermissionsState(locationPermissions) {
        permissions ->
         viewModel.updatePermissionStatus(permissions.all { it.value })
    }

    // Effect to update ViewModel when permission state changes externally
    LaunchedEffect(locationPermissionState.allPermissionsGranted) {
         viewModel.updatePermissionStatus(locationPermissionState.allPermissionsGranted)
    }

    // Effect to request permissions when needed
    LaunchedEffect(key1 = Unit) {
        if (!locationPermissionState.allPermissionsGranted && !locationPermissionState.shouldShowRationale) {
            locationPermissionState.launchMultiplePermissionRequest()
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background
    ) {
        paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("RUNNING", style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(24.dp))

            if (locationPermissionState.allPermissionsGranted) {
                // Main content when permissions are granted
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.weight(1f)
                ) {
                    StatDisplay(label = "DURATION", value = formatDuration(uiState.durationMillis))
                    Spacer(modifier = Modifier.height(16.dp))
                    StatDisplay(label = "DISTANCE (KM)", value = String.format("%.2f", uiState.distanceMeters / 1000f))
                    Spacer(modifier = Modifier.height(16.dp))
                    StatDisplay(label = "AVG PACE (MIN/KM)", value = formatPace(uiState.averagePaceMinPerKm))
                    Spacer(modifier = Modifier.height(16.dp))
                    StatDisplay(label = "CURRENT PACE (MIN/KM)", value = formatPace(uiState.currentPaceMinPerKm))

                    if (uiState.isSaving) {
                        Spacer(modifier = Modifier.height(16.dp))
                        LinearProgressIndicator(color = PtAccent)
                        Text("Saving workout...", style = MaterialTheme.typography.bodySmall)
                    }
                    uiState.saveError?.let {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Save Error: $it", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                    uiState.locationError?.let {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Location Error: $it", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    when (trackingStatus) {
                        TrackingStatus.IDLE, TrackingStatus.STOPPED -> {
                            StyledButton(
                                onClick = { viewModel.startTracking() },
                                text = "Start Run",
                                modifier = Modifier.weight(1f)
                            )
                        }
                        TrackingStatus.TRACKING -> {
                            StyledButton(
                                onClick = { viewModel.pauseTracking() },
                                text = "Pause",
                                modifier = Modifier.weight(1f)
                            )
                            StyledButton(
                                onClick = { viewModel.stopTracking() },
                                text = "Stop & Save",
                                modifier = Modifier.weight(1f)
                            )
                        }
                        TrackingStatus.PAUSED -> {
                            StyledButton(
                                onClick = { viewModel.startTracking() },
                                text = "Resume",
                                modifier = Modifier.weight(1f)
                            )
                            StyledButton(
                                onClick = { viewModel.stopTracking() },
                                text = "Stop & Save",
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }

            } else {
                // Content when permissions are not granted
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.weight(1f)
                ) {
                    val textToShow = if (locationPermissionState.shouldShowRationale) {
                        "Location permission is required to track your run distance and pace. Please grant the permission."
                    } else {
                        "Location permission is needed for run tracking. Please enable Location access for this app in your device settings."
                    }
                    Text(textToShow, style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.height(16.dp))
                    StyledButton(
                        onClick = { locationPermissionState.launchMultiplePermissionRequest() },
                        text = "Request Permission"
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            StyledButton(onClick = onNavigateBack, text = "Back", modifier = Modifier.align(Alignment.CenterHorizontally))
        }
    }
}

@Composable
fun StatDisplay(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = label.uppercase(),
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

private fun formatDuration(millis: Long): String {
    if (millis < 0) return "00:00:00"
    val totalSeconds = TimeUnit.MILLISECONDS.toSeconds(millis)
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return String.format("%02d:%02d:%02d", hours, minutes, seconds)
}

private fun formatPace(paceMinPerKm: Float): String {
    if (paceMinPerKm <= 0f || paceMinPerKm.isInfinite() || paceMinPerKm.isNaN()) return "--:--"
    val minutes = paceMinPerKm.toInt()
    val seconds = ((paceMinPerKm - minutes) * 60).toInt()
    return String.format("%02d:%02d", minutes, seconds)
} 