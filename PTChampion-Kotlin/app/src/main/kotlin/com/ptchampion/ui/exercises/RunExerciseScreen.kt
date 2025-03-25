package com.ptchampion.ui.exercises

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.BluetoothDisabled
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.StopCircle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.ptchampion.data.bluetooth.BluetoothDeviceInfo
import com.ptchampion.domain.model.Exercise

/**
 * Run exercise screen
 */
@Composable
fun RunExerciseScreen(
    exercise: Exercise,
    uiState: ExerciseUiState,
    availableDevices: List<BluetoothDeviceInfo>,
    onNavigateBack: () -> Unit,
    onStartExercise: () -> Unit,
    onCompleteExercise: (Int, Double) -> Unit,
    onConnectDevice: (String) -> Unit,
    onDisconnectDevice: (String) -> Unit
) {
    val context = LocalContext.current
    
    // State for showing Bluetooth permission request
    var showBluetoothPermissionDialog by remember { mutableStateOf(false) }
    
    // State for showing available devices dialog
    var showDevicesDialog by remember { mutableStateOf(false) }
    
    // Completion dialog
    if (uiState.isExerciseComplete) {
        AlertDialog(
            onDismissRequest = { },
            title = { Text("Exercise Complete") },
            text = {
                ExerciseCompletionSummary(
                    exerciseType = exercise.type,
                    timeInSeconds = uiState.runTime,
                    distance = uiState.runDistance,
                    score = calculateRunScore(uiState.runTime),
                    onClose = onNavigateBack
                )
            },
            confirmButton = { }
        )
    }
    
    // Bluetooth permission request launcher
    val bluetoothPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.values.all { it }
        
        if (allGranted) {
            showDevicesDialog = true
        }
    }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Header with exercise name and description
        ExerciseHeader(
            exercise = exercise,
            onNavigateBack = onNavigateBack
        )
        
        if (!uiState.isExerciseStarted) {
            // Exercise instructions and start button
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
                        text = "Connect your heart rate monitor and running sensor for better tracking. " +
                                "The app will track your distance and time.",
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center
                    )
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Connect device button
                        OutlinedButton(
                            onClick = {
                                val hasBtPermissions = ContextCompat.checkSelfPermission(
                                    context, Manifest.permission.BLUETOOTH_CONNECT
                                ) == PackageManager.PERMISSION_GRANTED &&
                                        ContextCompat.checkSelfPermission(
                                            context, Manifest.permission.BLUETOOTH_SCAN
                                        ) == PackageManager.PERMISSION_GRANTED
                                
                                if (hasBtPermissions) {
                                    showDevicesDialog = true
                                } else {
                                    showBluetoothPermissionDialog = true
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Bluetooth,
                                contentDescription = "Connect Devices"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Connect Devices")
                        }
                        
                        // Start run button
                        Button(
                            onClick = { onStartExercise() }
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = "Start Run"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Start Run")
                        }
                    }
                }
            }
        } else {
            // Run in progress
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Run metrics cards
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        // Time card
                        RunMetricCard(
                            title = "Time",
                            value = formatTime(uiState.runTime),
                            icon = Icons.Default.StopCircle,
                            modifier = Modifier.weight(1f)
                        )
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        // Distance card
                        RunMetricCard(
                            title = "Distance",
                            value = String.format("%.2f mi", uiState.runDistance),
                            icon = Icons.Default.DirectionsRun,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Heart rate
                    if (uiState.heartRate > 0) {
                        HeartRateDisplay(heartRate = uiState.heartRate)
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Connected devices
                    val connectedDevices = availableDevices.filter { it.connected }
                    if (connectedDevices.isNotEmpty()) {
                        Column(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = "Connected Devices",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            connectedDevices.forEach { device ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Bluetooth,
                                        contentDescription = "Connected",
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                    
                                    Spacer(modifier = Modifier.width(8.dp))
                                    
                                    Text(
                                        text = device.name,
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    
                                    if (device.heartRate > 0) {
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = "${device.heartRate} BPM",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                    
                                    Spacer(modifier = Modifier.weight(1f))
                                    
                                    TextButton(
                                        onClick = { onDisconnectDevice(device.id) }
                                    ) {
                                        Text("Disconnect")
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Connect more devices button
                    if (availableDevices.any { !it.connected }) {
                        OutlinedButton(
                            onClick = {
                                val hasBtPermissions = ContextCompat.checkSelfPermission(
                                    context, Manifest.permission.BLUETOOTH_CONNECT
                                ) == PackageManager.PERMISSION_GRANTED &&
                                        ContextCompat.checkSelfPermission(
                                            context, Manifest.permission.BLUETOOTH_SCAN
                                        ) == PackageManager.PERMISSION_GRANTED
                                
                                if (hasBtPermissions) {
                                    showDevicesDialog = true
                                } else {
                                    showBluetoothPermissionDialog = true
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Bluetooth,
                                contentDescription = "Connect Devices"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Connect More Devices")
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                    
                    // Complete run button
                    Button(
                        onClick = {
                            onCompleteExercise(uiState.runTime, uiState.runDistance)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Complete Run")
                    }
                }
            }
        }
    }
    
    // Bluetooth permission dialog
    if (showBluetoothPermissionDialog) {
        AlertDialog(
            onDismissRequest = { showBluetoothPermissionDialog = false },
            title = { Text("Bluetooth Permission Required") },
            text = {
                Text(
                    "This app needs Bluetooth permissions to connect to heart rate monitors and running sensors."
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showBluetoothPermissionDialog = false
                        bluetoothPermissionLauncher.launch(
                            arrayOf(
                                Manifest.permission.BLUETOOTH_SCAN,
                                Manifest.permission.BLUETOOTH_CONNECT
                            )
                        )
                    }
                ) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showBluetoothPermissionDialog = false }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Available devices dialog
    if (showDevicesDialog) {
        AlertDialog(
            onDismissRequest = { showDevicesDialog = false },
            title = { Text("Available Devices") },
            text = {
                if (availableDevices.isEmpty()) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        CircularProgressIndicator()
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "Scanning for devices...",
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = "Make sure your devices are turned on and in pairing mode.",
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.height(300.dp)
                    ) {
                        items(availableDevices) { device ->
                            DeviceListItem(
                                device = device,
                                onConnect = {
                                    if (!device.connected) {
                                        onConnectDevice(device.id)
                                    } else {
                                        onDisconnectDevice(device.id)
                                    }
                                }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = { showDevicesDialog = false }
                ) {
                    Text("Close")
                }
            }
        )
    }
}

/**
 * Run metric card for displaying time, distance, etc.
 */
@Composable
fun RunMetricCard(
    title: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

/**
 * Heart rate display component
 */
@Composable
fun HeartRateDisplay(heartRate: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = "Heart Rate",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                
                Text(
                    text = getHeartRateZone(heartRate),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                )
            }
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.FavoriteBorder,
                    contentDescription = "Heart Rate",
                    tint = Color.Red,
                    modifier = Modifier.size(32.dp)
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Text(
                    text = "$heartRate",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                
                Text(
                    text = " BPM",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}

/**
 * Device list item for Bluetooth device connection
 */
@Composable
fun DeviceListItem(
    device: BluetoothDeviceInfo,
    onConnect: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onConnect() }
            .padding(vertical = 12.dp, horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (device.connected) Icons.Default.Bluetooth else Icons.Default.BluetoothDisabled,
            contentDescription = if (device.connected) "Connected" else "Not Connected",
            tint = if (device.connected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = device.name,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (device.connected) FontWeight.Bold else FontWeight.Normal
            )
            
            if (device.connected && device.heartRate > 0) {
                Text(
                    text = "Heart Rate: ${device.heartRate} BPM",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
        
        TextButton(
            onClick = onConnect
        ) {
            Text(
                text = if (device.connected) "Disconnect" else "Connect"
            )
        }
    }
    
    Divider(modifier = Modifier.padding(horizontal = 16.dp))
}

/**
 * Format time in seconds to MM:SS display
 */
private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return "$minutes:${remainingSeconds.toString().padStart(2, '0')}"
}

/**
 * Get heart rate zone description based on BPM
 */
private fun getHeartRateZone(heartRate: Int): String {
    return when {
        heartRate < 60 -> "Resting"
        heartRate < 117 -> "Easy (50-60%)"
        heartRate < 137 -> "Fat Burn (60-70%)"
        heartRate < 156 -> "Aerobic (70-80%)"
        heartRate < 176 -> "Anaerobic (80-90%)"
        else -> "VO2 Max (90-100%)"
    }
}

/**
 * Calculate run score
 * - 100 points = 13:00 (780 seconds) or less
 * - 50 points = 16:36 (996 seconds)
 */
private fun calculateRunScore(timeInSeconds: Int): Int {
    return when {
        timeInSeconds <= 780 -> 100
        timeInSeconds >= 1212 -> 0
        else -> ((1212 - timeInSeconds) * 100) / 432
    }.coerceIn(0, 100)
}