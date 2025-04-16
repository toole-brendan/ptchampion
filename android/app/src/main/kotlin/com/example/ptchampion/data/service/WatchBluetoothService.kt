package com.example.ptchampion.data.service

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.ptchampion.domain.exercise.bluetooth.WatchConstants
import com.example.ptchampion.domain.service.BleDevice
import com.example.ptchampion.domain.service.BluetoothService
import com.example.ptchampion.domain.service.ConnectionState
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WatchBluetoothService @Inject constructor(
    @ApplicationContext private val context: Context
) : BluetoothService {

    private val TAG = "WatchBluetoothService"
    
    // BLE components
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
    private val bluetoothAdapter = bluetoothManager?.adapter
    private var bluetoothLeScanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner
    private var gatt: BluetoothGatt? = null
    
    // Coroutine scope and threading
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val handler = Handler(Looper.getMainLooper())
    private val SCAN_TIMEOUT_MS = WatchConstants.ScanSettings.SCAN_TIMEOUT_MS
    private val CONNECT_TIMEOUT_MS = WatchConstants.ScanSettings.CONNECT_TIMEOUT_MS
    private var connectJob: Job? = null
    
    // Data models for watch devices
    data class WatchDevice(
        val name: String?,
        val address: String,
        val manufacturer: WatchManufacturer,
        val supportedFeatures: Set<WatchFeature> = emptySet()
    )
    
    enum class WatchManufacturer {
        GARMIN, POLAR, SUUNTO, FITBIT, WAHOO, UNKNOWN
    }
    
    enum class WatchFeature {
        GPS_TRACKING, HEART_RATE, STEP_COUNT, DISTANCE, PACE, CADENCE, BATTERY
    }
    
    // StateFlow objects for reactive UI updates
    private val _discoveredDevices = MutableStateFlow<List<BleDevice>>(emptyList())
    override val discoveredDevices: StateFlow<List<BleDevice>> = _discoveredDevices.asStateFlow()
    
    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    override val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _connectedDevice = MutableStateFlow<BleDevice?>(null)
    override val connectedDevice: StateFlow<BleDevice?> = _connectedDevice.asStateFlow()
    
    private val _errors = MutableSharedFlow<String>()
    override val errors: Flow<String> = _errors.asSharedFlow()
    
    // Additional data streams specifically for watch data
    private val _heartRate = MutableStateFlow<Int?>(null)
    val heartRate: StateFlow<Int?> = _heartRate.asStateFlow()
    
    private val _batteryLevel = MutableStateFlow<Int?>(null)
    val batteryLevel: StateFlow<Int?> = _batteryLevel.asStateFlow()
    
    // Track scan results
    private val scanResults = mutableMapOf<String, WatchDevice>()
    
    // Track connection retry attempts
    private var connectionRetryCount = 0
    
    // Permission requirements based on Android version
    private val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
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
    
    // Implement permission checking
    private fun hasRequiredPermissions(): Boolean {
        return requiredPermissions.all { 
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED 
        }
    }
    
    // Watch filter - focus only on fitness watch devices
    private fun createScanFilters(): List<ScanFilter> {
        return listOf(
            // Filter for Garmin devices
            ScanFilter.Builder()
                .setManufacturerData(WatchConstants.Manufacturers.GARMIN, byteArrayOf())
                .build(),
            // Filter for Polar devices  
            ScanFilter.Builder()
                .setManufacturerData(WatchConstants.Manufacturers.POLAR, byteArrayOf())
                .build(),
            // Filter for Suunto devices
            ScanFilter.Builder()
                .setManufacturerData(WatchConstants.Manufacturers.SUUNTO, byteArrayOf())
                .build(),
            // Filter for Fitbit devices
            ScanFilter.Builder()
                .setManufacturerData(WatchConstants.Manufacturers.FITBIT, byteArrayOf())
                .build(),
            // Filter for Wahoo devices
            ScanFilter.Builder()
                .setManufacturerData(WatchConstants.Manufacturers.WAHOO, byteArrayOf())
                .build(),
            // Filter for devices advertising Heart Rate service
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(WatchConstants.Services.HEART_RATE))
                .build(),
            // Filter for devices advertising Running Speed and Cadence service
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(WatchConstants.Services.RUNNING_SPEED_AND_CADENCE))
                .build(),
            // Filter for devices advertising Fitness Machine service
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(WatchConstants.Services.FITNESS_MACHINE))
                .build(),
            // Filter for devices advertising Location and Navigation service
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(WatchConstants.Services.LOCATION_AND_NAVIGATION))
                .build()
        )
    }
    
    // Implement scan settings optimized for watch discovery
    private fun createScanSettings(): ScanSettings {
        return ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY) // Higher power for initial discovery
            .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
            .build()
    }
    
    // Determine manufacturer from device info
    private fun determineManufacturer(scanResult: ScanResult): WatchManufacturer {
        val manufacturerData = scanResult.scanRecord?.manufacturerSpecificData
        if (manufacturerData != null) {
            for (i in 0 until manufacturerData.size()) {
                when (manufacturerData.keyAt(i)) {
                    WatchConstants.Manufacturers.GARMIN -> return WatchManufacturer.GARMIN
                    WatchConstants.Manufacturers.POLAR -> return WatchManufacturer.POLAR
                    WatchConstants.Manufacturers.SUUNTO -> return WatchManufacturer.SUUNTO
                    WatchConstants.Manufacturers.FITBIT -> return WatchManufacturer.FITBIT
                    WatchConstants.Manufacturers.WAHOO -> return WatchManufacturer.WAHOO
                }
            }
        }
        return WatchManufacturer.UNKNOWN
    }
    
    // Determine supported features based on advertised services
    private fun determineSupportedFeatures(scanResult: ScanResult): Set<WatchFeature> {
        val features = mutableSetOf<WatchFeature>()
        val scanRecord = scanResult.scanRecord
        val services = scanRecord?.serviceUuids
        
        if (services != null) {
            for (serviceUuid in services) {
                when (serviceUuid.uuid) {
                    WatchConstants.Services.HEART_RATE -> features.add(WatchFeature.HEART_RATE)
                    WatchConstants.Services.RUNNING_SPEED_AND_CADENCE -> {
                        features.add(WatchFeature.CADENCE)
                        features.add(WatchFeature.PACE)
                    }
                    WatchConstants.Services.LOCATION_AND_NAVIGATION -> features.add(WatchFeature.GPS_TRACKING)
                    WatchConstants.Services.BATTERY -> features.add(WatchFeature.BATTERY)
                }
            }
        }
        
        return features
    }
    
    // Scan implementation with proper lifecycle awareness
    @SuppressLint("MissingPermission")
    override suspend fun startScan() {
        if (!hasRequiredPermissions()) {
            _errors.emit("Required permissions not granted")
            return
        }
        
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            _errors.emit("Bluetooth is not enabled")
            return
        }
        
        bluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner // Re-check scanner
        if (bluetoothLeScanner == null) {
            _errors.emit("Could not get BLE scanner")
            return
        }
        
        // Clear previous results
        scanResults.clear()
        _discoveredDevices.value = emptyList()
        
        Log.d(TAG, "Starting BLE scan for GPS watches...")
        try {
            bluetoothLeScanner?.startScan(
                createScanFilters(),
                createScanSettings(),
                scanCallback
            )
            
            // Add timeout to preserve battery
            handler.postDelayed({ stopScanInternal() }, SCAN_TIMEOUT_MS)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting scan", e)
            _errors.emit("Failed to start scan: ${e.message}")
        }
    }
    
    @SuppressLint("MissingPermission")
    override suspend fun stopScan() {
        stopScanInternal()
    }
    
    @SuppressLint("MissingPermission")
    private fun stopScanInternal() {
        if (bluetoothLeScanner == null) {
            Log.w(TAG, "Cannot stop scan: Scanner is null")
            return
        }
        
        Log.d(TAG, "Stopping BLE scan for GPS watches")
        try {
            bluetoothLeScanner?.stopScan(scanCallback)
            handler.removeCallbacksAndMessages(null) // Remove timeout callbacks
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping scan", e)
        }
    }
    
    // Connection implementation with watch-specific handling
    @SuppressLint("MissingPermission")
    override suspend fun connect(address: String) {
        if (!hasRequiredPermissions()) {
            _errors.emit("Required permissions not granted")
            return
        }
        
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            _errors.emit("Bluetooth is not enabled")
            return
        }
        
        if (_connectionState.value != ConnectionState.DISCONNECTED) {
            _errors.emit("Already connected or connecting to a device")
            return
        }
        
        // Stop any ongoing scan
        stopScanInternal()
        
        _connectionState.value = ConnectionState.CONNECTING
        connectionRetryCount = 0
        
        // Cancel any existing connection jobs
        connectJob?.cancel()
        
        connectJob = serviceScope.launch {
            try {
                val device = bluetoothAdapter.getRemoteDevice(address)
                if (device == null) {
                    _errors.emit("Device not found: $address")
                    _connectionState.value = ConnectionState.FAILED
                    return@launch
                }
                
                // Find the watch device in scan results if available
                val watchDevice = scanResults[address]
                _connectedDevice.value = BleDevice(device.name, device.address)
                
                Log.d(TAG, "Connecting to ${device.address} (${device.name ?: "Unknown"})")
                
                // Set up connection timeout
                val timeoutJob = launch {
                    delay(CONNECT_TIMEOUT_MS)
                    if (_connectionState.value == ConnectionState.CONNECTING) {
                        Log.w(TAG, "Connection timeout reached")
                        _errors.emit("Connection timeout reached")
                        _connectionState.value = ConnectionState.FAILED
                        _connectedDevice.value = null
                        gatt?.close()
                        gatt = null
                    }
                }
                
                // Connect on main thread to avoid issues
                withContext(Dispatchers.Main) {
                    gatt = device.connectGatt(
                        context, 
                        false, // Auto connect can cause issues with watches
                        gattCallback,
                        BluetoothDevice.TRANSPORT_LE // Ensure LE transport
                    )
                }
                
                // Wait for connection to complete or timeout
                while (_connectionState.value == ConnectionState.CONNECTING && isActive) {
                    delay(100)
                }
                
                // Cancel timeout job if connection completed
                timeoutJob.cancel()
                
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                
                Log.e(TAG, "Connection error", e)
                _errors.emit("Connection error: ${e.message}")
                _connectionState.value = ConnectionState.FAILED
                _connectedDevice.value = null
                gatt?.close()
                gatt = null
            }
        }
    }
    
    // Implement retry logic
    private suspend fun retryConnection(address: String) {
        if (connectionRetryCount < WatchConstants.ScanSettings.MAX_RETRY_COUNT) {
            connectionRetryCount++
            Log.d(TAG, "Retrying connection, attempt $connectionRetryCount of ${WatchConstants.ScanSettings.MAX_RETRY_COUNT}")
            
            // Small delay before retry
            delay(1000)
            connect(address)
        } else {
            Log.w(TAG, "Max retry count reached, giving up connection attempts")
            _errors.emit("Failed to connect after ${WatchConstants.ScanSettings.MAX_RETRY_COUNT} attempts")
            _connectionState.value = ConnectionState.FAILED
            _connectedDevice.value = null
        }
    }
    
    @SuppressLint("MissingPermission")
    override suspend fun disconnect() {
        Log.d(TAG, "Disconnecting from watch")
        
        // Cancel any ongoing connection job
        connectJob?.cancel()
        connectJob = null
        
        if (gatt == null) {
            Log.w(TAG, "No GATT connection to disconnect")
            _connectionState.value = ConnectionState.DISCONNECTED
            _connectedDevice.value = null
            return
        }
        
        try {
            gatt?.disconnect()
            // State change handled in gattCallback
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting", e)
            _errors.emit("Disconnect error: ${e.message}")
            
            // Force disconnect
            gatt?.close()
            gatt = null
            _connectionState.value = ConnectionState.DISCONNECTED
            _connectedDevice.value = null
        }
    }
    
    @SuppressLint("MissingPermission")
    override fun cleanup() {
        Log.d(TAG, "Cleaning up resources")
        stopScanInternal()
        
        // Cancel any ongoing jobs
        connectJob?.cancel()
        connectJob = null
        
        try {
            gatt?.disconnect()
            gatt?.close()
            gatt = null
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up", e)
        }
        
        _connectionState.value = ConnectionState.DISCONNECTED
        _connectedDevice.value = null
        _heartRate.value = null
        _batteryLevel.value = null
    }
    
    // Process watch services after discovery
    @SuppressLint("MissingPermission")
    private fun processWatchServices(gatt: BluetoothGatt) {
        Log.d(TAG, "Processing discovered services for ${gatt.device?.address}")
        
        val services = gatt.services
        for (service in services) {
            Log.d(TAG, "Service discovered: ${service.uuid}")
            
            when (service.uuid) {
                // Heart Rate Service
                WatchConstants.Services.HEART_RATE -> {
                    Log.d(TAG, "Heart rate service found")
                    setupCharacteristicNotification(
                        gatt,
                        service,
                        WatchConstants.Characteristics.HEART_RATE_MEASUREMENT
                    )
                }
                
                // Battery Service
                WatchConstants.Services.BATTERY -> {
                    Log.d(TAG, "Battery service found")
                    // Read battery level once
                    val batteryChar = service.getCharacteristic(WatchConstants.Characteristics.BATTERY_LEVEL)
                    if (batteryChar != null) {
                        gatt.readCharacteristic(batteryChar)
                    }
                }
                
                // Running Speed and Cadence Service
                WatchConstants.Services.RUNNING_SPEED_AND_CADENCE -> {
                    Log.d(TAG, "Running speed and cadence service found")
                    setupCharacteristicNotification(
                        gatt,
                        service,
                        WatchConstants.Characteristics.RSC_MEASUREMENT
                    )
                }
                
                // Location and Navigation Service
                WatchConstants.Services.LOCATION_AND_NAVIGATION -> {
                    Log.d(TAG, "Location and navigation service found")
                    setupCharacteristicNotification(
                        gatt,
                        service,
                        WatchConstants.Characteristics.LOCATION_AND_SPEED
                    )
                }
                
                // Check for Garmin-specific services
                WatchConstants.Garmin.FITNESS_SERVICE -> {
                    Log.d(TAG, "Garmin fitness service found")
                    // Setup notifications for Garmin GPS data
                    setupCharacteristicNotification(
                        gatt,
                        service,
                        WatchConstants.Garmin.GPS_LOCATION
                    )
                }
            }
        }
        
        Log.d(TAG, "Finished processing ${services.size} services")
    }
    
    // Setup notifications for a characteristic
    @SuppressLint("MissingPermission")
    private fun setupCharacteristicNotification(
        gatt: BluetoothGatt,
        service: BluetoothGattService,
        characteristicUuid: UUID
    ) {
        val characteristic = service.getCharacteristic(characteristicUuid)
        if (characteristic != null) {
            Log.d(TAG, "Setting up notifications for ${characteristicUuid}")
            
            // Enable notifications
            gatt.setCharacteristicNotification(characteristic, true)
            
            // Get the descriptor for enabling notifications
            val descriptor = characteristic.getDescriptor(WatchConstants.Descriptors.CLIENT_CHARACTERISTIC_CONFIG)
            
            if (descriptor != null) {
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                gatt.writeDescriptor(descriptor)
                Log.d(TAG, "Enabled notifications for ${characteristicUuid}")
            } else {
                Log.w(TAG, "Config descriptor not found for ${characteristicUuid}")
            }
        } else {
            Log.w(TAG, "Characteristic ${characteristicUuid} not found in service ${service.uuid}")
        }
    }
    
    // Process heart rate data from characteristic
    private fun processHeartRateData(value: ByteArray) {
        try {
            // The heart rate measurement profile defines the first byte as a flags field
            val flags = value[0].toInt()
            val isHeartRateValueFormat16Bit = flags and 0x01 != 0
            
            // Read heart rate value based on the format indicated by the flags
            val heartRate = if (isHeartRateValueFormat16Bit) {
                ((value[2].toInt() and 0xFF) shl 8) or (value[1].toInt() and 0xFF)
            } else {
                value[1].toInt() and 0xFF
            }
            
            Log.d(TAG, "Heart rate: $heartRate BPM")
            _heartRate.value = heartRate
        } catch (e: Exception) {
            Log.e(TAG, "Error processing heart rate data", e)
        }
    }
    
    // Process battery level data
    private fun processBatteryLevel(value: ByteArray) {
        try {
            if (value.isNotEmpty()) {
                val level = value[0].toInt() and 0xFF
                Log.d(TAG, "Battery level: $level%")
                _batteryLevel.value = level
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing battery level data", e)
        }
    }
    
    // Process running speed and cadence data
    private fun processRscData(value: ByteArray) {
        try {
            // First byte contains flags
            val flags = value[0].toInt()
            var index = 1
            
            // Check if speed data is present (bit 0)
            if (flags and 0x01 != 0) {
                // Speed is at index 1-2 (uint16) in unit of m/s with resolution of 1/256 s
                val speedRaw = ((value[index + 1].toInt() and 0xFF) shl 8) or (value[index].toInt() and 0xFF)
                val speedMps = speedRaw / 256.0 // Convert to m/s
                Log.d(TAG, "Running speed: $speedMps m/s")
                index += 2
            }
            
            // Check if cadence data is present (bit 1)
            if (flags and 0x02 != 0) {
                // Cadence is at index after speed (if present) - uint8 in rpm
                val cadence = value[index].toInt() and 0xFF
                Log.d(TAG, "Cadence: $cadence rpm")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing running speed and cadence data", e)
        }
    }
    
    // Process location and speed data
    /* // Temporarily commented out for debugging Kapt error
    private fun processLocationAndSpeedData(value: ByteArray) {
        try {
            // This is a complex data format - see Bluetooth GATT spec for details
            // Basic parsing example:
            val flags = value[0].toInt() | ((value[1].toInt() and 0xFF) shl 8)
            
            var index = 2
            
            // Check if position (lat/long) is present
            if (flags and 0x01 != 0) {
                // Position is present
                val latRaw = extractInt32(value, index)
                val latitude = latRaw / 10000000.0 // Re-typed line
                index += 4
                val longRaw = extractInt32(value, index)
                val longitude = longRaw / 10000000.0 // Re-typed line
                index += 4
                
                Log.d(TAG, "GPS Position: $latitude, $longitude")
            }
            
            // Check if elevation is present
            if (flags and 0x02 != 0) {
                val elevRaw = extractInt24(value, index)
                val elevation = elevRaw / 100.0 // Re-typed line
                index += 3
                Log.d(TAG, "Elevation: $elevation m")
            }
            
            // Additional data could be parsed based on the flags
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing location and speed data", e)
        }
    }
    */
    
    // Helper method to extract a 24-bit signed integer
    private fun extractInt24(bytes: ByteArray, offset: Int): Int {
        return (bytes[offset].toInt() and 0xFF) or
               ((bytes[offset + 1].toInt() and 0xFF) shl 8) or
               ((bytes[offset + 2].toInt() and 0xFF) shl 16)
    }
    
    // Helper method to extract a 32-bit signed integer
    private fun extractInt32(bytes: ByteArray, offset: Int): Int {
        return (bytes[offset].toInt() and 0xFF) or
               ((bytes[offset + 1].toInt() and 0xFF) shl 8) or
               ((bytes[offset + 2].toInt() and 0xFF) shl 16) or
               ((bytes[offset + 3].toInt() and 0xFF) shl 24)
    }
    
    // Process Garmin-specific GPS data
    private fun processGarminGpsData(value: ByteArray) {
        // This implementation would depend on Garmin's specific data format
        // This is a placeholder that would need real research to implement correctly
        Log.d(TAG, "Garmin GPS data received: ${value.contentToString()}")
    }
    
    // Generic data processor that routes to specific processors based on UUID
    private fun processCharacteristicData(uuid: UUID, value: ByteArray) {
        when (uuid) {
            WatchConstants.Characteristics.HEART_RATE_MEASUREMENT -> processHeartRateData(value)
            WatchConstants.Characteristics.BATTERY_LEVEL -> processBatteryLevel(value)
            WatchConstants.Characteristics.RSC_MEASUREMENT -> processRscData(value)
            WatchConstants.Characteristics.LOCATION_AND_SPEED -> {
                // Process location and speed data
                /* // Temporarily commented out for debugging Kapt error
                processLocationAndSpeedData(value)
                */
            }
            WatchConstants.Garmin.GPS_LOCATION -> processGarminGpsData(value)
            else -> Log.d(TAG, "Received data for characteristic $uuid: ${value.contentToString()}")
        }
    }
    
    // Scan callback implementation
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.let { scanResult ->
                val device = scanResult.device
                val address = device.address
                
                if (!scanResults.containsKey(address)) {
                    val manufacturer = determineManufacturer(scanResult)
                    val features = determineSupportedFeatures(scanResult)
                    
                    // Process all fitness watch manufacturers or unknown devices with relevant services
                    if (manufacturer != WatchManufacturer.UNKNOWN || features.isNotEmpty()) {
                        val watchDevice = WatchDevice(
                            name = device.name,
                            address = address,
                            manufacturer = manufacturer,
                            supportedFeatures = features
                        )
                        
                        Log.d(TAG, "Found fitness device: ${device.name ?: "Unknown"} ($address), " +
                                "Manufacturer: $manufacturer, Features: $features")
                        
                        scanResults[address] = watchDevice
                        
                        // Update discovered devices for UI
                        _discoveredDevices.value = scanResults.values.map { 
                            BleDevice(it.name, it.address) 
                        }
                    }
                }
            }
        }
        
        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            results?.forEach { result ->
                onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, result)
            }
        }
        
        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "BLE Scan Failed with error code: $errorCode")
            serviceScope.launch {
                _errors.emit("BLE Scan Failed with error code: $errorCode")
            }
            stopScanInternal()
        }
    }
    
    // GATT callback implementation for watches
    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            val deviceAddress = gatt?.device?.address
            Log.d(TAG, "Connection state changed: address=$deviceAddress, status=$status, newState=$newState")
            
            when (status) {
                BluetoothGatt.GATT_SUCCESS -> {
                    when (newState) {
                        BluetoothProfile.STATE_CONNECTED -> {
                            Log.d(TAG, "Connected to GATT server")
                            _connectionState.value = ConnectionState.CONNECTED
                            
                            // Discover services after connection
                            // Add a slight delay to improve reliability
                            serviceScope.launch {
                                delay(600) // Short delay to ensure connection is stable
                                gatt?.discoverServices()
                            }
                        }
                        BluetoothProfile.STATE_DISCONNECTED -> {
                            Log.d(TAG, "Disconnected from GATT server")
                            _connectionState.value = ConnectionState.DISCONNECTED
                            _connectedDevice.value = null
                            _heartRate.value = null
                            _batteryLevel.value = null
                            
                            // Clean up resources
                            gatt?.close()
                            this@WatchBluetoothService.gatt = null
                        }
                    }
                }
                else -> {
                    Log.e(TAG, "Connection error with status: $status")
                    _connectionState.value = ConnectionState.FAILED
                    _connectedDevice.value = null
                    
                    serviceScope.launch { 
                        _errors.emit("Connection failed with status: $status")
                    }
                    
                    // Clean up resources
                    gatt?.close()
                    this@WatchBluetoothService.gatt = null
                    
                    // Implement retry logic
                    deviceAddress?.let {
                        serviceScope.launch { 
                            retryConnection(it)
                        }
                    }
                }
            }
        }
        
        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Services discovered for ${gatt?.device?.address}")
                
                // Process discovered services
                gatt?.let { processWatchServices(it) }
            } else {
                Log.e(TAG, "Service discovery failed with status: $status")
                serviceScope.launch { 
                    _errors.emit("Service discovery failed with status: $status")
                }
            }
        }
        
        // Handle receiving notifications
        @SuppressLint("MissingPermission")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            Log.d(TAG, "Characteristic changed: ${characteristic.uuid}")
            processCharacteristicData(characteristic.uuid, value)
        }
        
        // Legacy support for Android < 8.0
        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?
        ) {
            characteristic?.let { c ->
                gatt?.let { g ->
                    c.value?.let { value ->
                        onCharacteristicChanged(g, c, value)
                    }
                }
            }
        }
        
        // Handle read operations
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int
        ) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Read characteristic ${characteristic.uuid}")
                processCharacteristicData(characteristic.uuid, value)
            } else {
                Log.e(TAG, "Failed to read characteristic ${characteristic.uuid}, status: $status")
                serviceScope.launch {
                    _errors.emit("Failed to read characteristic: $status")
                }
            }
        }
        
        // Legacy support for Android < 8.0
        @Deprecated("Deprecated in Java")
        override fun onCharacteristicRead(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            characteristic?.let { c ->
                gatt?.let { g ->
                    c.value?.let { value ->
                        onCharacteristicRead(g, c, value, status)
                    }
                }
            }
        }
        
        // Handle descriptor write operations (used for enabling notifications)
        override fun onDescriptorWrite(
            gatt: BluetoothGatt?,
            descriptor: BluetoothGattDescriptor?,
            status: Int
        ) {
            val uuid = descriptor?.characteristic?.uuid
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Descriptor write successful for characteristic: $uuid")
            } else {
                Log.e(TAG, "Descriptor write failed for characteristic: $uuid, status: $status")
                serviceScope.launch {
                    _errors.emit("Failed to enable notifications for $uuid: $status")
                }
            }
        }
    }
} 