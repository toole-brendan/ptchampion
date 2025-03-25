package com.ptchampion.ui.exercises

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.ptchampion.domain.model.Exercise
import com.ptchampion.domain.model.RunData
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Run exercise screen
 */
@Composable
fun RunExerciseScreen(
    exercise: Exercise,
    uiState: ExerciseUiState,
    onNavigateBack: () -> Unit,
    onStartExercise: () -> Unit,
    onUpdateRunData: (RunData) -> Unit,
    onCompleteExercise: (Int, Double) -> Unit
) {
    val context = LocalContext.current
    var showBluetoothPermissionDialog by remember { mutableStateOf(false) }
    var showLocationPermissionDialog by remember { mutableStateOf(false) }
    var isRunning by remember { mutableStateOf(false) }
    var isPaused by remember { mutableStateOf(false) }
    var elapsedTimeInSeconds by remember { mutableIntStateOf(0) }
    var distanceInMiles by remember { mutableDoubleStateOf(0.0) }
    var currentPace by remember { mutableDoubleStateOf(0.0) }
    var heartRate by remember { mutableIntStateOf(0) }
    var lastUpdateTime by remember { mutableLongStateOf(0L) }
    
    // Timer effect
    LaunchedEffect(isRunning, isPaused) {
        var startTimeMillis = System.currentTimeMillis()
        
        while (isRunning && !isPaused) {
            kotlinx.coroutines.delay(1000)
            elapsedTimeInSeconds++
            
            if (elapsedTimeInSeconds % 10 == 0) {
                // Simulate GPS data update every 10 seconds
                val currentTimeMillis = System.currentTimeMillis()
                val timeDelta = (currentTimeMillis - lastUpdateTime) / 1000.0
                lastUpdateTime = currentTimeMillis
                
                if (timeDelta > 0) {
                    // Calculate new distance based on current pace (miles per hour)
                    val hourFraction = timeDelta / 3600.0
                    val distanceDelta = currentPace * hourFraction
                    distanceInMiles += distanceDelta
                    
                    // Update run data
                    onUpdateRunData(
                        RunData(
                            timeInSeconds = elapsedTimeInSeconds,
                            distance = distanceInMiles,
                            pace = currentPace,
                            heartRate = heartRate
                        )
                    )
                }
            }
        }
    }
    
    // Completion dialog
    if (uiState.isExerciseComplete) {
        AlertDialog(
            onDismissRequest = { },
            title = { Text("Run Complete") },
            text = {
                RunCompletionSummary(
                    timeInSeconds = elapsedTimeInSeconds,
                    distanceInMiles = distanceInMiles,
                    score = calculateRunScore(elapsedTimeInSeconds),
                    onClose = onNavigateBack
                )
            },
            confirmButton = { }
        )
    }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        ExerciseHeader(
            exercise = exercise,
            onNavigateBack = onNavigateBack
        )
        
        if (!uiState.isExerciseStarted) {
            // Exercise instructions
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Get ready for your Run",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Connect a heart rate monitor (optional) and track your 2-mile run performance. " +
                                "The app will measure your time, distance, and pace.",
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Button(
                            onClick = {
                                showBluetoothPermissionDialog = true
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.DirectionsRun,
                                contentDescription = "Start with HR"
                            )
                            Spacer(modifier = Modifier.size(8.dp))
                            Text("With HR Monitor")
                        }
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        OutlinedButton(
                            onClick = {
                                showLocationPermissionDialog = true
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = "Start without HR"
                            )
                            Spacer(modifier = Modifier.size(8.dp))
                            Text("Without HR")
                        }
                    }
                }
            }
        } else {
            // Run in progress UI
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    // Run stats
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            // Time
                            Text(
                                text = formatTime(elapsedTimeInSeconds),
                                style = MaterialTheme.typography.displayMedium,
                                fontWeight = FontWeight.Bold
                            )
                            
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            // Distance
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(
                                        text = "Distance",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        text = String.format("%.2f mi", distanceInMiles),
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(
                                        text = "Pace",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        text = String.format("%.1f mph", currentPace),
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(
                                        text = "Heart Rate",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        text = if (heartRate > 0) "$heartRate bpm" else "-- bpm",
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                            
                            if (distanceInMiles > 0) {
                                Spacer(modifier = Modifier.height(16.dp))
                                
                                // Progress towards 2 miles
                                Column(
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        text = "Progress: ${(distanceInMiles * 50).roundToInt()}%",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    
                                    Spacer(modifier = Modifier.height(4.dp))
                                    
                                    LinearProgressIndicator(
                                        progress = (distanceInMiles / 2.0).toFloat().coerceIn(0f, 1f),
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                }
                            }
                        }
                    }
                    
                    // Controls
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 16.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        // Pause/Resume
                        IconButton(
                            onClick = { 
                                isPaused = !isPaused
                            },
                            modifier = Modifier
                                .size(64.dp)
                                .border(
                                    width = 2.dp,
                                    color = MaterialTheme.colorScheme.primary,
                                    shape = RoundedCornerShape(32.dp)
                                )
                        ) {
                            Icon(
                                imageVector = if (isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                                contentDescription = if (isPaused) "Resume" else "Pause",
                                modifier = Modifier.size(32.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                        
                        // Stop
                        IconButton(
                            onClick = {
                                isRunning = false
                                if (distanceInMiles >= 2.0) {
                                    onCompleteExercise(elapsedTimeInSeconds, distanceInMiles)
                                } else {
                                    // Prompt to confirm
                                    showCompletionConfirmation(
                                        elapsedTimeInSeconds,
                                        distanceInMiles,
                                        onConfirm = {
                                            onCompleteExercise(elapsedTimeInSeconds, distanceInMiles)
                                        }
                                    )
                                }
                            },
                            modifier = Modifier
                                .size(64.dp)
                                .background(
                                    color = MaterialTheme.colorScheme.error,
                                    shape = RoundedCornerShape(32.dp)
                                )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Stop,
                                contentDescription = "Stop",
                                modifier = Modifier.size(32.dp),
                                tint = MaterialTheme.colorScheme.onError
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Bluetooth permission handling
    if (showBluetoothPermissionDialog) {
        val bluetoothPermissionLauncher = rememberLauncherForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { permissions ->
            val bluetoothGranted = permissions[Manifest.permission.BLUETOOTH_CONNECT] ?: false
            if (bluetoothGranted) {
                // Now check for location permission
                showLocationPermissionDialog = true
            } else {
                // Proceed without Bluetooth
                showBluetoothPermissionDialog = false
                showLocationPermissionDialog = true
            }
        }
        
        BluetoothPermissionRequest(
            onPermissionGranted = {
                showBluetoothPermissionDialog = false
                // Connect to heart rate device here
                // ...
                showLocationPermissionDialog = true
            },
            onCancel = {
                showBluetoothPermissionDialog = false
                showLocationPermissionDialog = true
            },
            permissionLauncher = bluetoothPermissionLauncher
        )
    }
    
    // Location permission handling
    if (showLocationPermissionDialog) {
        val locationPermissionLauncher = rememberLauncherForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { permissions ->
            val fineLocationGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
            val coarseLocationGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
            
            if (fineLocationGranted || coarseLocationGranted) {
                // Start run tracking with location
                onStartExercise()
                isRunning = true
                lastUpdateTime = System.currentTimeMillis()
                
                // Simulate different paces during run
                currentPace = 6.0 + (Math.random() * 2.0) // 6-8 mph
            } else {
                // Start without location - just time tracking
                onStartExercise()
                isRunning = true
                lastUpdateTime = System.currentTimeMillis()
            }
            showLocationPermissionDialog = false
        }
        
        LocationPermissionRequest(
            onPermissionGranted = {
                showLocationPermissionDialog = false
                onStartExercise()
                isRunning = true
                lastUpdateTime = System.currentTimeMillis()
                
                // Simulate different paces during run
                currentPace = 6.0 + (Math.random() * 2.0) // 6-8 mph
            },
            onCancel = {
                showLocationPermissionDialog = false
                // Start without location - just time tracking
                onStartExercise()
                isRunning = true
                lastUpdateTime = System.currentTimeMillis()
            },
            permissionLauncher = locationPermissionLauncher
        )
    }
    
    // Clean up when leaving the screen
    DisposableEffect(Unit) {
        onDispose {
            isRunning = false
            // Disconnect any heart rate monitors, etc.
        }
    }
}

/**
 * Format time from seconds to MM:SS
 */
private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return String.format(Locale.US, "%02d:%02d", minutes, remainingSeconds)
}

/**
 * Calculate run score
 * - 100 points = 13:00 (780 seconds) or less
 * - 50 points = 16:36 (996 seconds)
 */
private fun calculateRunScore(timeInSeconds: Int): Int {
    return when {
        timeInSeconds <= 780 -> 100
        timeInSeconds >= 1200 -> 0
        else -> ((1200 - timeInSeconds) * 100) / 420
    }.coerceIn(0, 100)
}

/**
 * Confirmation dialog for stopping run
 */
@Composable
private fun showCompletionConfirmation(
    timeInSeconds: Int,
    distanceInMiles: Double,
    onConfirm: () -> Unit
) {
    var showDialog by remember { mutableStateOf(true) }
    
    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("End Run?") },
            text = {
                Column {
                    Text("You've only completed ${String.format("%.2f", distanceInMiles)} miles.")
                    Text("Are you sure you want to end this run?")
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        showDialog = false
                        onConfirm()
                    }
                ) {
                    Text("Yes, End Run")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showDialog = false }
                ) {
                    Text("Continue Running")
                }
            }
        )
    }
}

/**
 * Run completion summary
 */
@Composable
fun RunCompletionSummary(
    timeInSeconds: Int,
    distanceInMiles: Double,
    score: Int,
    onClose: () -> Unit
) {
    Column(
        modifier = Modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Run Complete!",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = score.toString(),
            style = MaterialTheme.typography.displayLarge,
            fontWeight = FontWeight.Bold
        )
        
        Text(
            text = "Your Score",
            style = MaterialTheme.typography.titleMedium
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Time",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = formatTime(timeInSeconds),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            }
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Distance",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = String.format("%.2f mi", distanceInMiles),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            }
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Pace",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = String.format("%s/mi", formatTime((timeInSeconds / distanceInMiles).toInt())),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onClose,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Done")
        }
    }
}

/**
 * Bluetooth permission request dialog
 */
@Composable
fun BluetoothPermissionRequest(
    onPermissionGranted: () -> Unit,
    onCancel: () -> Unit,
    permissionLauncher: androidx.activity.result.ActivityResultLauncher<Array<String>>
) {
    val context = LocalContext.current
    val hasBtPermission = ContextCompat.checkSelfPermission(
        context, Manifest.permission.BLUETOOTH_CONNECT
    ) == PackageManager.PERMISSION_GRANTED
    
    if (hasBtPermission) {
        onPermissionGranted()
    } else {
        AlertDialog(
            onDismissRequest = onCancel,
            title = { Text("Connect Heart Rate Monitor") },
            text = {
                Text("To use a heart rate monitor, the app needs Bluetooth permissions.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        permissionLauncher.launch(
                            arrayOf(
                                Manifest.permission.BLUETOOTH_CONNECT,
                                Manifest.permission.BLUETOOTH_SCAN
                            )
                        )
                    }
                ) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = onCancel
                ) {
                    Text("Skip")
                }
            }
        )
    }
}

/**
 * Location permission request dialog
 */
@Composable
fun LocationPermissionRequest(
    onPermissionGranted: () -> Unit,
    onCancel: () -> Unit,
    permissionLauncher: androidx.activity.result.ActivityResultLauncher<Array<String>>
) {
    val context = LocalContext.current
    val hasFineLocation = ContextCompat.checkSelfPermission(
        context, Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
    val hasCoarseLocation = ContextCompat.checkSelfPermission(
        context, Manifest.permission.ACCESS_COARSE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
    
    if (hasFineLocation || hasCoarseLocation) {
        onPermissionGranted()
    } else {
        AlertDialog(
            onDismissRequest = onCancel,
            title = { Text("Track Your Route") },
            text = {
                Text("To track your running distance and route, the app needs location permissions.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        permissionLauncher.launch(
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            )
                        )
                    }
                ) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = onCancel
                ) {
                    Text("Skip")
                }
            }
        )
    }
}