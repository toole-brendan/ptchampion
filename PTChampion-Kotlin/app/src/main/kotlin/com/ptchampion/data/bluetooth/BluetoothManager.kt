package com.ptchampion.data.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * Manages Bluetooth connections and data
 */
@SuppressLint("MissingPermission") // Caller needs to handle permissions
@Singleton
class BluetoothManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    companion object {
        private const val TAG = "BluetoothManager"
        
        // Services UUID
        val HEART_RATE_SERVICE_UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        val RUNNING_SPEED_SERVICE_UUID = UUID.fromString("00001814-0000-1000-8000-00805f9b34fb")
        
        // Characteristics UUID
        val HEART_RATE_MEASUREMENT_UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        val RSC_MEASUREMENT_UUID = UUID.fromString("00002a53-0000-1000-8000-00805f9b34fb")
        
        // Descriptor UUID
        val CLIENT_CHARACTERISTIC_CONFIG_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
    
    // System BLE manager
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter = bluetoothManager.adapter
    
    // Scanner
    private val bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
    private var isScanning = false
    
    // Connected devices
    private val connectedDevices = mutableMapOf<String, BluetoothGatt>()
    
    // Service data
    private val _serviceData = MutableStateFlow(BluetoothServiceData())
    val serviceData: StateFlow<BluetoothServiceData> = _serviceData.asStateFlow()
    
    // Available devices during scan
    private val _availableDevices = MutableStateFlow<List<BluetoothDeviceInfo>>(emptyList())
    val availableDevices: StateFlow<List<BluetoothDeviceInfo>> = _availableDevices.asStateFlow()
    
    /**
     * Start scanning for BLE devices
     */
    fun startScan() {
        if (isScanning || bluetoothLeScanner == null) return
        
        val serviceUuids = listOf(
            ParcelUuid(HEART_RATE_SERVICE_UUID),
            ParcelUuid(RUNNING_SPEED_SERVICE_UUID)
        )
        
        val filters = serviceUuids.map { 
            ScanFilter.Builder()
                .setServiceUuid(it)
                .build() 
        }
        
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        
        // Clear previous results
        _availableDevices.value = emptyList()
        
        isScanning = true
        bluetoothLeScanner.startScan(filters, settings, scanCallback)
        
        Log.d(TAG, "Started BLE scan")
    }
    
    /**
     * Stop scanning for BLE devices
     */
    fun stopScan() {
        if (!isScanning || bluetoothLeScanner == null) return
        
        isScanning = false
        bluetoothLeScanner.stopScan(scanCallback)
        
        Log.d(TAG, "Stopped BLE scan")
    }
    
    /**
     * Connect to a device by address
     */
    fun connectToDevice(deviceAddress: String) {
        val device = bluetoothAdapter?.getRemoteDevice(deviceAddress) ?: return
        
        Log.d(TAG, "Connecting to ${device.name ?: "Unknown Device"} (${device.address})")
        
        // Connect to GATT server on the device
        val gatt = device.connectGatt(context, false, gattCallback)
        connectedDevices[deviceAddress] = gatt
    }
    
    /**
     * Disconnect from a device
     */
    fun disconnectDevice(deviceAddress: String) {
        val gatt = connectedDevices[deviceAddress] ?: return
        
        gatt.disconnect()
        gatt.close()
        
        connectedDevices.remove(deviceAddress)
        
        Log.d(TAG, "Disconnected from device: $deviceAddress")
    }
    
    /**
     * Disconnect from all devices
     */
    fun disconnectAll() {
        Log.d(TAG, "Disconnecting from all devices")
        
        connectedDevices.forEach { (_, gatt) ->
            gatt.disconnect()
            gatt.close()
        }
        
        connectedDevices.clear()
    }
    
    /**
     * Check if Bluetooth is enabled
     */
    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }
    
    /**
     * Get a list of paired devices
     */
    fun getPairedDevices(): List<BluetoothDeviceInfo> {
        val pairedDevices = bluetoothAdapter?.bondedDevices ?: setOf()
        
        return pairedDevices.map { device ->
            BluetoothDeviceInfo(
                id = device.address,
                name = device.name ?: "Unknown Device",
                connected = false
            )
        }
    }
    
    /**
     * Callback for scan results
     */
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val deviceName = device.name ?: "Unknown Device"
            val deviceAddress = device.address
            
            // Skip unnamed devices
            if (device.name == null) return
            
            Log.d(TAG, "Found BLE device: $deviceName ($deviceAddress)")
            
            val deviceInfo = BluetoothDeviceInfo(
                id = deviceAddress,
                name = deviceName,
                connected = connectedDevices.containsKey(deviceAddress)
            )
            
            // Add to list if not already present
            val currentDevices = _availableDevices.value.toMutableList()
            if (!currentDevices.any { it.id == deviceAddress }) {
                currentDevices.add(deviceInfo)
                _availableDevices.value = currentDevices
            }
        }
        
        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "BLE scan failed with error: $errorCode")
            isScanning = false
        }
    }
    
    /**
     * Callback for GATT events
     */
    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val deviceAddress = gatt.device.address
            val deviceName = gatt.device.name ?: "Unknown Device"
            
            if (status == BluetoothGatt.GATT_SUCCESS) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    Log.d(TAG, "Connected to $deviceName")
                    
                    // Update devices list to show connected status
                    updateDeviceConnectionStatus(deviceAddress, true)
                    
                    // Discover services
                    gatt.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    Log.d(TAG, "Disconnected from $deviceName")
                    
                    // Update devices list to show disconnected status
                    updateDeviceConnectionStatus(deviceAddress, false)
                    
                    // Clean up
                    connectedDevices.remove(deviceAddress)
                    gatt.close()
                }
            } else {
                Log.e(TAG, "Error $status encountered for $deviceName! Disconnecting...")
                
                // Update devices list to show disconnected status
                updateDeviceConnectionStatus(deviceAddress, false)
                
                // Clean up
                connectedDevices.remove(deviceAddress)
                gatt.close()
            }
        }
        
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Services discovered for ${gatt.device.name}")
                
                // Set up notifications for heart rate and running speed
                setupHeartRateNotification(gatt)
                setupRunningSpeedNotification(gatt)
            } else {
                Log.e(TAG, "Service discovery failed for ${gatt.device.name}, status: $status")
            }
        }
        
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            when (characteristic.uuid) {
                HEART_RATE_MEASUREMENT_UUID -> {
                    val heartRate = parseHeartRate(value)
                    scope.launch {
                        _serviceData.value = _serviceData.value.copy(heartRate = heartRate)
                    }
                    Log.d(TAG, "Heart rate updated: $heartRate")
                }
                RSC_MEASUREMENT_UUID -> {
                    val runningData = parseRunningData(value)
                    scope.launch {
                        _serviceData.value = _serviceData.value.copy(
                            speed = runningData.speed,
                            distance = runningData.distance ?: _serviceData.value.distance
                        )
                    }
                    Log.d(TAG, "Running data updated: ${runningData.speed} m/s, distance: ${runningData.distance}")
                }
            }
        }
    }
    
    /**
     * Update device connection status in the available devices list
     */
    private fun updateDeviceConnectionStatus(deviceAddress: String, connected: Boolean) {
        val currentDevices = _availableDevices.value.toMutableList()
        val deviceIndex = currentDevices.indexOfFirst { it.id == deviceAddress }
        
        if (deviceIndex != -1) {
            val device = currentDevices[deviceIndex]
            currentDevices[deviceIndex] = device.copy(connected = connected)
            _availableDevices.value = currentDevices
        }
    }
    
    /**
     * Set up notification for heart rate measurement
     */
    private fun setupHeartRateNotification(gatt: BluetoothGatt) {
        val service = gatt.getService(HEART_RATE_SERVICE_UUID) ?: return
        val characteristic = service.getCharacteristic(HEART_RATE_MEASUREMENT_UUID) ?: return
        
        // Enable local notifications
        gatt.setCharacteristicNotification(characteristic, true)
        
        // Enable remote notifications
        val descriptor = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG_UUID)
        descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        gatt.writeDescriptor(descriptor)
        
        Log.d(TAG, "Heart rate notification set up")
    }
    
    /**
     * Set up notification for running speed measurement
     */
    private fun setupRunningSpeedNotification(gatt: BluetoothGatt) {
        val service = gatt.getService(RUNNING_SPEED_SERVICE_UUID) ?: return
        val characteristic = service.getCharacteristic(RSC_MEASUREMENT_UUID) ?: return
        
        // Enable local notifications
        gatt.setCharacteristicNotification(characteristic, true)
        
        // Enable remote notifications
        val descriptor = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG_UUID)
        descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        gatt.writeDescriptor(descriptor)
        
        Log.d(TAG, "Running speed notification set up")
    }
    
    /**
     * Parse heart rate from characteristic value
     */
    private fun parseHeartRate(value: ByteArray): Int {
        val format = if (value[0].toInt() and 0x01 == 0) {
            // Heart Rate value format is uint8
            0
        } else {
            // Heart Rate value format is uint16
            1
        }
        
        return if (format == 1) {
            ((value[1].toInt() and 0xFF) + (value[2].toInt() and 0xFF shl 8))
        } else {
            value[1].toInt() and 0xFF
        }
    }
    
    /**
     * Parse running speed and cadence from characteristic value
     */
    private fun parseRunningData(value: ByteArray): RunningData {
        val flags = value[0].toInt() and 0xFF
        
        // Instantaneous speed is always present (in m/s with resolution of 1/256 s)
        val speed = (value[1].toInt() and 0xFF + (value[2].toInt() and 0xFF shl 8)) / 256.0
        
        // Total distance is optional
        var distance: Double? = null
        if (flags and 0x01 != 0) {
            // Offset depends on if instantaneous cadence is present (flags bit 1)
            val offset = if (flags and 0x02 != 0) 5 else 3
            
            // Distance is in meters as uint32
            distance = (value[offset].toInt() and 0xFF +
                    (value[offset + 1].toInt() and 0xFF shl 8) +
                    (value[offset + 2].toInt() and 0xFF shl 16) +
                    (value[offset + 3].toInt() and 0xFF shl 24)).toDouble()
        }
        
        return RunningData(speed, distance)
    }
    
    /**
     * Start running timer and update elapsed time
     */
    fun startRunningTimer() {
        scope.launch {
            val startTime = System.currentTimeMillis()
            
            while (true) {
                val currentTime = System.currentTimeMillis()
                val elapsedSeconds = ((currentTime - startTime) / 1000).toInt()
                
                _serviceData.value = _serviceData.value.copy(timeElapsed = elapsedSeconds)
                
                kotlinx.coroutines.delay(1000)
            }
        }
    }
    
    /**
     * Reset service data
     */
    fun resetServiceData() {
        _serviceData.value = BluetoothServiceData()
    }
}

/**
 * Information about a Bluetooth device
 */
data class BluetoothDeviceInfo(
    val id: String,
    val name: String,
    val connected: Boolean
)

/**
 * Data from Bluetooth services
 */
data class BluetoothServiceData(
    val heartRate: Int = 0,
    val steps: Int = 0,
    val distance: Double = 0.0,
    val timeElapsed: Int = 0,
    val speed: Double = 0.0
)

/**
 * Running speed and cadence data
 */
private data class RunningData(
    val speed: Double,
    val distance: Double?
)