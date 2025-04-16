package com.example.ptchampion.domain.exercise.bluetooth

import android.util.Log
import com.example.ptchampion.data.service.WatchBluetoothService
import com.example.ptchampion.di.GPSWatchBluetoothService
import com.example.ptchampion.domain.service.BleDevice
import com.example.ptchampion.domain.service.BluetoothService
import com.example.ptchampion.domain.service.ConnectionState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service to process and provide GPS and other metrics from fitness watches
 */
@Singleton
class GpsWatchService @Inject constructor(
    @GPSWatchBluetoothService private val bluetoothService: BluetoothService,
    private val parserFactory: WatchParserFactory
) {
    private val TAG = "GpsWatchService"
    
    // Coroutine scope for background processing
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    // Data streams
    private val _watchGpsData = MutableStateFlow<GpsLocation?>(null)
    val watchGpsData: StateFlow<GpsLocation?> = _watchGpsData.asStateFlow()
    
    private val _watchHeartRate = MutableStateFlow<Int?>(null)
    val watchHeartRate: StateFlow<Int?> = _watchHeartRate.asStateFlow()
    
    private val _watchPace = MutableStateFlow<Float?>(null)
    val watchPace: StateFlow<Float?> = _watchPace.asStateFlow()
    
    // Holds the current parser for the connected watch
    private var currentParser: WatchDataParser? = null
    private var connectedManufacturer: WatchBluetoothService.WatchManufacturer = WatchBluetoothService.WatchManufacturer.UNKNOWN
    
    init {
        // Initialize by observing Bluetooth service state
        observeBluetoothService()
        
        // If the bluetoothService is a WatchBluetoothService, observe its heartRate stream
        if (bluetoothService is WatchBluetoothService) {
            observeWatchBluetoothServiceData()
        }
    }
    
    private fun observeBluetoothService() {
        // Observe connection state
        serviceScope.launch {
            bluetoothService.connectionState.collectLatest { state ->
                Log.d(TAG, "Bluetooth connection state changed: $state")
                if (state == ConnectionState.CONNECTED) {
                    // Get connected device details and set up parser
                    bluetoothService.connectedDevice.value?.let { device ->
                        setupParserForDevice(device)
                    }
                } else if (state == ConnectionState.DISCONNECTED) {
                    resetDataStreams()
                }
            }
        }
    }
    
    private fun observeWatchBluetoothServiceData() {
        // Only relevant if we have a WatchBluetoothService
        val watchService = bluetoothService as? WatchBluetoothService ?: return
        
        // Observe built-in heart rate
        serviceScope.launch {
            watchService.heartRate.collectLatest { heartRate ->
                _watchHeartRate.value = heartRate
            }
        }
    }
    
    private fun setupParserForDevice(device: BleDevice) {
        // Determine the manufacturer based on device info
        connectedManufacturer = detectManufacturer(device)
        currentParser = parserFactory.getParserForManufacturer(connectedManufacturer)
        
        Log.d(TAG, "Set up parser for ${device.name} (${device.address}): $connectedManufacturer")
    }
    
    private fun resetDataStreams() {
        _watchGpsData.value = null
        _watchHeartRate.value = null
        _watchPace.value = null
        currentParser = null
        connectedManufacturer = WatchBluetoothService.WatchManufacturer.UNKNOWN
    }
    
    // Process GPS data received from the watch
    fun processGpsData(data: ByteArray) {
        currentParser?.parseGpsData(data)?.let { location ->
            _watchGpsData.value = location
            Log.d(TAG, "Parsed GPS data: ${location.latitude}, ${location.longitude}")
        }
    }
    
    // Process heart rate data received from the watch
    fun processHeartRateData(data: ByteArray) {
        currentParser?.parseHeartRate(data)?.let { heartRate ->
            _watchHeartRate.value = heartRate
            Log.d(TAG, "Parsed heart rate: $heartRate BPM")
        }
    }
    
    // Process pace data received from the watch
    fun processPaceData(data: ByteArray) {
        currentParser?.parsePace(data)?.let { pace ->
            _watchPace.value = pace
            Log.d(TAG, "Parsed pace: $pace min/km")
        }
    }
    
    // Helper method to determine watch manufacturer from device info
    private fun detectManufacturer(device: BleDevice): WatchBluetoothService.WatchManufacturer {
        val deviceName = device.name?.lowercase() ?: ""
        
        return when {
            deviceName.contains("garmin") -> WatchBluetoothService.WatchManufacturer.GARMIN
            deviceName.contains("polar") -> WatchBluetoothService.WatchManufacturer.POLAR
            deviceName.contains("suunto") -> WatchBluetoothService.WatchManufacturer.SUUNTO
            deviceName.contains("fitbit") -> WatchBluetoothService.WatchManufacturer.FITBIT
            deviceName.contains("wahoo") -> WatchBluetoothService.WatchManufacturer.WAHOO
            else -> WatchBluetoothService.WatchManufacturer.UNKNOWN
        }
    }
    
    // Public API for scanning watches
    suspend fun startScan() {
        bluetoothService.startScan()
    }
    
    suspend fun stopScan() {
        bluetoothService.stopScan()
    }
    
    suspend fun connectToWatch(address: String) {
        bluetoothService.connect(address)
    }
    
    suspend fun disconnectFromWatch() {
        bluetoothService.disconnect()
    }
    
    val discoveredWatches = bluetoothService.discoveredDevices
    val connectionState = bluetoothService.connectionState
    val connectedWatch = bluetoothService.connectedDevice
} 