package com.example.ptchampion.ui.screens.bluetooth

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.ptchampion.data.service.WatchBluetoothService
import com.example.ptchampion.di.GPSWatchBluetoothService
import com.example.ptchampion.domain.exercise.bluetooth.WatchDataRepository
import com.example.ptchampion.domain.service.BleDevice
import com.example.ptchampion.domain.service.BluetoothService
import com.example.ptchampion.domain.service.ConnectionState
import com.example.ptchampion.domain.util.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.content.Context
import android.os.Build

/**
 * Feature for watch UI
 */
enum class WatchFeature {
    GPS_TRACKING, HEART_RATE, STEP_COUNT, DISTANCE, PACE, CADENCE, BATTERY
}

/**
 * UI representation of a watch device
 */
data class WatchDevice(
    val name: String?,
    val address: String,
    val isConnected: Boolean = false,
    val batteryLevel: Int? = null,
    val features: List<WatchFeature> = emptyList()
)

@HiltViewModel
class WatchDeviceManagementViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    @GPSWatchBluetoothService private val bluetoothService: BluetoothService,
    private val watchDataRepository: WatchDataRepository
) : ViewModel() {

    // UI state for watch device management
    data class WatchUiState(
        val isScanning: Boolean = false,
        val discoveredWatches: List<WatchDevice> = emptyList(),
        val connectedWatch: WatchDevice? = null,
        val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
        val batteryLevel: Int? = null,
        val watchFeatures: List<WatchFeature> = emptyList(),
        val error: String? = null,
        val permissionsGranted: Boolean = false
    )
    
    private val _uiState = MutableStateFlow(WatchUiState())
    val uiState: StateFlow<WatchUiState> = _uiState.asStateFlow()
    
    init {
        viewModelScope.launch {
            // Update permissions state
            _uiState.update { it.copy(permissionsGranted = checkBluetoothPermissions()) }
            
            // Observe Bluetooth state changes
            bluetoothService.connectionState.collect { state ->
                _uiState.update { it.copy(connectionState = state) }
                
                if (state == ConnectionState.CONNECTED) {
                    // Update connected device and query capabilities
                    bluetoothService.connectedDevice.value?.let { device ->
                        updateConnectedDevice(device)
                        queryWatchCapabilities()
                    }
                } else if (state == ConnectionState.DISCONNECTED) {
                    // Clear connected device info
                    _uiState.update { 
                        it.copy(
                            connectedWatch = null,
                            batteryLevel = null,
                            watchFeatures = emptyList()
                        )
                    }
                }
            }
            
            // Observe discovered devices
            bluetoothService.discoveredDevices.collect { devices ->
                val watchDevices = devices.map { device ->
                    WatchDevice(
                        name = device.name,
                        address = device.address,
                        isConnected = device.address == bluetoothService.connectedDevice.value?.address
                    )
                }
                _uiState.update { it.copy(discoveredWatches = watchDevices) }
            }
        }
        
        // If the bluetoothService is a WatchBluetoothService, observe battery level
        if (bluetoothService is WatchBluetoothService) {
            viewModelScope.launch {
                bluetoothService.batteryLevel.collect { batteryLevel ->
                    if (batteryLevel != null) {
                        _uiState.update { it.copy(batteryLevel = batteryLevel) }
                        
                        // Also update the connected watch object
                        updateConnectedWatchBattery(batteryLevel)
                    }
                }
            }
        }
    }
    
    /**
     * Start scanning for devices
     */
    fun startScan() {
        if (!_uiState.value.permissionsGranted) {
            _uiState.update { it.copy(error = "Bluetooth permissions required.") }
            return
        }
        
        _uiState.update { it.copy(isScanning = true, error = null) }
        viewModelScope.launch {
            try {
                watchDataRepository.startDeviceScan()
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isScanning = false,
                        error = "Failed to start scan: ${e.message}"
                    ) 
                }
            }
        }
    }
    
    /**
     * Stop scanning for devices
     */
    fun stopScan() {
        _uiState.update { it.copy(isScanning = false) }
        viewModelScope.launch {
            watchDataRepository.stopDeviceScan()
        }
    }
    
    /**
     * Connect to a device by address
     */
    fun connectToDevice(address: String) {
        if (!_uiState.value.permissionsGranted) {
            _uiState.update { it.copy(error = "Bluetooth permissions required.") }
            return
        }
        
        _uiState.update { it.copy(error = null) }
        viewModelScope.launch {
            val result = watchDataRepository.connectToDevice(address)
            if (result is Resource.Error) {
                _uiState.update { it.copy(error = result.message) }
            }
        }
    }
    
    /**
     * Disconnect from the current device
     */
    fun disconnectFromDevice() {
        viewModelScope.launch {
            val result = watchDataRepository.disconnectFromDevice()
            if (result is Resource.Error) {
                _uiState.update { it.copy(error = result.message) }
            }
        }
    }
    
    /**
     * Update permissions status
     */
    fun updatePermissionStatus(granted: Boolean) {
        _uiState.update { it.copy(permissionsGranted = granted) }
        if (!granted) {
            stopScan()
            _uiState.update { it.copy(error = "Bluetooth permissions denied.") }
        } else {
            _uiState.update { it.copy(error = null) }
        }
    }
    
    /**
     * Check if required Bluetooth permissions are granted
     */
    private fun checkBluetoothPermissions(): Boolean {
        val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }
        
        return requiredPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Update the connected device in UI state
     */
    private fun updateConnectedDevice(device: BleDevice) {
        val features = detectWatchFeatures(device)
        val currentBattery = _uiState.value.batteryLevel
        
        _uiState.update { it ->
            it.copy(
                connectedWatch = WatchDevice(
                    name = device.name,
                    address = device.address,
                    isConnected = true,
                    batteryLevel = currentBattery,
                    features = features
                )
            )
        }
    }
    
    /**
     * Update battery level for the connected watch
     */
    private fun updateConnectedWatchBattery(batteryLevel: Int) {
        val currentWatch = _uiState.value.connectedWatch ?: return
        
        _uiState.update {
            it.copy(
                connectedWatch = currentWatch.copy(batteryLevel = batteryLevel)
            )
        }
    }
    
    /**
     * Query watch capabilities after connection
     */
    private suspend fun queryWatchCapabilities() {
        val device = bluetoothService.connectedDevice.value ?: return
        
        // For devices that support features detection, we'd implement here
        // For this version, we'll rely on device name heuristics
        val features = detectWatchFeatures(device)
        _uiState.update { it.copy(watchFeatures = features) }
    }
    
    /**
     * Detect watch features based on device name
     */
    private fun detectWatchFeatures(device: BleDevice): List<WatchFeature> {
        val features = mutableListOf<WatchFeature>()
        val deviceName = device.name?.lowercase() ?: ""
        
        // Garmin watches
        if (deviceName.contains("forerunner") || 
            deviceName.contains("fenix") || 
            deviceName.contains("garmin")) {
            features.add(WatchFeature.GPS_TRACKING)
            features.add(WatchFeature.HEART_RATE)
            features.add(WatchFeature.PACE)
            features.add(WatchFeature.DISTANCE)
        }
        
        // Polar watches
        if (deviceName.contains("polar")) {
            features.add(WatchFeature.HEART_RATE)
            features.add(WatchFeature.GPS_TRACKING)
        }
        
        // Suunto watches
        if (deviceName.contains("suunto")) {
            features.add(WatchFeature.GPS_TRACKING)
            features.add(WatchFeature.HEART_RATE)
        }
        
        // Always include battery if the service supports it
        if (bluetoothService is WatchBluetoothService && bluetoothService.batteryLevel.value != null) {
            features.add(WatchFeature.BATTERY)
        }
        
        return features
    }
} 