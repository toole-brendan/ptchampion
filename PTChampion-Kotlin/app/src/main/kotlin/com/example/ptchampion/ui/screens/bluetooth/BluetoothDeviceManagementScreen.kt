package com.example.ptchampion.ui.screens.bluetooth

import android.Manifest
import android.os.Build
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.components.StyledButton
import com.example.ptchampion.ui.theme.PtAccent
import com.google.accompanist.permissions.*

@OptIn(ExperimentalPermissionsApi::class, ExperimentalMaterial3Api::class)
@Composable
fun BluetoothDeviceManagementScreen(
    viewModel: BluetoothDeviceManagementViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    // Permissions handling
    val bluetoothPermissions = remember {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        } else {
            listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION // Needed for scan on older APIs
            )
        }
    }
    val permissionState = rememberMultiplePermissionsState(bluetoothPermissions) {
         permissions ->
         viewModel.updatePermissionStatus(permissions.all { it.value })
    }

    // Effect to update ViewModel when permission state changes externally
    LaunchedEffect(permissionState.allPermissionsGranted) {
        viewModel.updatePermissionStatus(permissionState.allPermissionsGranted)
    }

    // Effect to request permissions on screen entry if not granted
    LaunchedEffect(key1 = Unit) {
        if (!permissionState.allPermissionsGranted && !permissionState.shouldShowRationale) {
            permissionState.launchMultiplePermissionRequest()
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background, // Tactical Cream
        topBar = {
            TopAppBar(
                title = { Text("Bluetooth Devices", style = MaterialTheme.typography.headlineSmall) }, // Bebas Neue
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back", tint = MaterialTheme.colorScheme.onBackground)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground,
                    navigationIconContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) {
        paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            if (permissionState.allPermissionsGranted) {
                // Content when permissions are granted
                Row(verticalAlignment = Alignment.CenterVertically) {
                    StyledButton(
                        onClick = { if (uiState.isScanning) viewModel.stopScan() else viewModel.startScan() },
                        text = if (uiState.isScanning) "Stop Scan" else "Scan for Devices",
                        modifier = Modifier.weight(1f)
                    )
                    if (uiState.isScanning) {
                        Spacer(modifier = Modifier.width(16.dp))
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = PtAccent, // Brass Gold
                            strokeWidth = 2.dp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
                Text("Discovered Devices:", style = MaterialTheme.typography.titleMedium) // Montserrat SemiBold
                Spacer(modifier = Modifier.height(8.dp))

                LazyColumn(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    items(uiState.discoveredDevices, key = { it.address }) { device ->
                        DeviceItem(
                            name = device.name ?: "Unknown Device",
                            address = device.address,
                            isConnected = device.address == uiState.connectedDevice?.address,
                            onConnectClick = { viewModel.connectToDevice(device.address) },
                            onDisconnectClick = { viewModel.disconnectDevice() }
                        )
                        Divider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 1.dp)
                    }
                    if (uiState.discoveredDevices.isEmpty() && !uiState.isScanning) {
                        item {
                            Text(
                                "No devices found. Ensure Bluetooth is enabled and devices are discoverable.",
                                style = MaterialTheme.typography.bodyMedium,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(vertical = 32.dp)
                            )
                        }
                    }
                }

                // Connection Status & Error Display Area
                Column(modifier = Modifier.padding(vertical = 16.dp)) {
                    Text(
                        "Status: ${uiState.connectionStatus}",
                         style = MaterialTheme.typography.bodyLarge
                    )
                    uiState.connectedDevice?.let {
                        Text(
                            "Connected to: ${it.name ?: "Unknown"} (${it.address})",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                     uiState.error?.let {
                         Spacer(modifier = Modifier.height(8.dp))
                         Text("Error: $it", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                     }
                }

            } else {
                // Content when permissions are not granted
                 Column(
                     horizontalAlignment = Alignment.CenterHorizontally,
                     verticalArrangement = Arrangement.Center,
                     modifier = Modifier.fillMaxSize().padding(16.dp)
                 ) {
                     val textToShow = if (permissionState.shouldShowRationale) {
                         "Bluetooth permissions (Scan & Connect) are required to find and pair with fitness devices. Please grant the permissions to continue."
                     } else {
                         "Bluetooth permissions are needed to manage devices. Please enable Bluetooth Scan and Connect permissions for PT Champion in your phone's settings."
                     }
                     Text(textToShow, style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center)
                     Spacer(modifier = Modifier.height(16.dp))
                     StyledButton(
                         onClick = { permissionState.launchMultiplePermissionRequest() },
                         text = "Request Permissions"
                     )
                 }
            }
        }
    }
}

@Composable
fun DeviceItem(
    name: String,
    address: String,
    isConnected: Boolean,
    onConnectClick: () -> Unit,
    onDisconnectClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f, fill = false).padding(end = 16.dp)) {
            Text(name, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis)
            Text(address, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.secondary)
        }
        if (isConnected) {
            StyledButton(onClick = onDisconnectClick, text = "Disconnect")
        } else {
            StyledButton(onClick = onConnectClick, text = "Connect")
        }
    }
}

// Placeholder data class - REMOVE duplicate declaration
// data class BluetoothDeviceData(val name: String?, val address: String) 