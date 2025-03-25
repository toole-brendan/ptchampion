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
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Timer
import java.util.TimerTask
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Bluetooth device representation
 */
data class BluetoothDeviceInfo(
    val id: String,
    val name: String,
    val device: BluetoothDevice,
    val connected: Boolean = false,
    val heartRate: Int = 0
)

/**
 * Service data for running metrics
 */
data class BluetoothServiceData(
    val heartRate: Int = 0,
    val steps: Int = 0,
    val distance: Double = 0.0,
    val timeElapsed: Int = 0,
    val speed: Double = 0.0
)

/**
 * Manager for Bluetooth operations
 */
@Singleton
class BluetoothManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "BluetoothManager"
        
        // Standard UUIDs for Heart Rate Service
        private val HEART_RATE_SERVICE_UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        private val HEART_RATE_MEASUREMENT_UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        
        // Standard UUIDs for Running Speed and Cadence Service
        private val RUNNING_SPEED_CADENCE_SERVICE_UUID = UUID.fromString("00001814-0000-1000-8000-00805f9b34fb")
        private val RSC_MEASUREMENT_UUID = UUID.fromString("00002a53-0000-1000-8000-00805f9b34fb")
        
        // Descriptor for enabling notifications
        private val CLIENT_CHARACTERISTIC_CONFIG_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
        
        // Scan timeout in milliseconds
        private const val SCAN_PERIOD = 15000L
    }
    
    // System Bluetooth adapter
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothManager.adapter
    }
    
    // BLE scanner
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    
    // Tracking connected devices
    private val connectedDevices = mutableMapOf<String, BluetoothGatt>()
    
    // Observable list of available devices
    private val _availableDevices = MutableStateFlow<List<BluetoothDeviceInfo>>(emptyList())
    val availableDevices: StateFlow<List<BluetoothDeviceInfo>> = _availableDevices.asStateFlow()
    
    // Service data for running metrics
    private val _serviceData = MutableStateFlow(BluetoothServiceData())
    val serviceData: StateFlow<BluetoothServiceData> = _serviceData.asStateFlow()
    
    // Scanning state
    private var isScanning = false
    
    // Handler for scan timeout
    private val handler = Handler(Looper.getMainLooper())
    
    // Timer for run tracking
    private var runTimer: Timer? = null
    private var runTimeSeconds = 0
    
    /**
     * Start scanning for BLE devices
     */
    @SuppressLint("MissingPermission")
    fun startScan() {
        if (isScanning) return
        
        if (bluetoothAdapter?.isEnabled == true) {
            bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
            
            // Set up filters for heart rate and running speed devices
            val filters = listOf(
                ScanFilter.Builder()
                    .setServiceUuid(ParcelUuid(HEART_RATE_SERVICE_UUID))
                    .build(),
                ScanFilter.Builder()
                    .setServiceUuid(ParcelUuid(RUNNING_SPEED_CADENCE_SERVICE_UUID))
                    .build()
            )
            
            // Set up scan settings for low power
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
            
            // Start scan with callback
            bluetoothLeScanner?.startScan(filters, settings, scanCallback)
            isScanning = true
            
            // Stop scanning after SCAN_PERIOD
            handler.postDelayed({
                stopScan()
            }, SCAN_PERIOD)
            
            Log.d(TAG, "Started BLE scan")
        } else {
            Log.w(TAG, "Bluetooth is not enabled")
        }
    }
    
    /**
     * Stop scanning for BLE devices
     */
    @SuppressLint("MissingPermission")
    fun stopScan() {
        if (!isScanning) return
        
        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false
        handler.removeCallbacksAndMessages(null)
        
        Log.d(TAG, "Stopped BLE scan")
    }
    
    /**
     * Connect to a specific device
     */
    @SuppressLint("MissingPermission")
    fun connectToDevice(deviceId: String) {
        // Find device in available devices
        val deviceInfo = _availableDevices.value.find { it.id == deviceId } ?: return
        
        // Connect to the device
        val gatt = deviceInfo.device.connectGatt(context, false, gattCallback)
        connectedDevices[deviceId] = gatt
        
        Log.d(TAG, "Connecting to device: ${deviceInfo.name}")
    }
    
    /**
     * Disconnect from a specific device
     */
    @SuppressLint("MissingPermission")
    fun disconnectDevice(deviceId: String) {
        connectedDevices[deviceId]?.let { gatt ->
            gatt.disconnect()
            gatt.close()
            connectedDevices.remove(deviceId)
            
            // Update device status in list
            updateDeviceConnectionStatus(deviceId, false)
            
            Log.d(TAG, "Disconnected from device: $deviceId")
        }
    }
    
    /**
     * Disconnect from all devices
     */
    @SuppressLint("MissingPermission")
    fun disconnectAll() {
        connectedDevices.forEach { (deviceId, gatt) ->
            gatt.disconnect()
            gatt.close()
            
            // Update device status in list
            updateDeviceConnectionStatus(deviceId, false)
        }
        connectedDevices.clear()
        
        Log.d(TAG, "Disconnected from all devices")
    }
    
    /**
     * Start the running timer
     */
    fun startRunningTimer() {
        runTimeSeconds = 0
        runTimer = Timer()
        runTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                runTimeSeconds++
                _serviceData.value = _serviceData.value.copy(timeElapsed = runTimeSeconds)
            }
        }, 0, 1000)
        
        Log.d(TAG, "Started run timer")
    }
    
    /**
     * Stop the running timer
     */
    fun stopRunningTimer() {
        runTimer?.cancel()
        runTimer = null
        
        Log.d(TAG, "Stopped run timer")
    }
    
    /**
     * Reset service data
     */
    fun resetServiceData() {
        runTimeSeconds = 0
        _serviceData.value = BluetoothServiceData()
        
        Log.d(TAG, "Reset service data")
    }
    
    /**
     * Get service data
     */
    fun getServiceData(): BluetoothServiceData {
        return _serviceData.value
    }
    
    /**
     * BLE scan callback
     */
    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val deviceName = device.name ?: "Unknown Device"
            val deviceId = device.address
            
            // Only add devices with names
            if (device.name != null) {
                val existingDevice = _availableDevices.value.find { it.id == deviceId }
                
                if (existingDevice == null) {
                    // Add new device to list
                    val deviceInfo = BluetoothDeviceInfo(
                        id = deviceId,
                        name = deviceName,
                        device = device
                    )
                    
                    val updatedDevices = _availableDevices.value.toMutableList()
                    updatedDevices.add(deviceInfo)
                    _availableDevices.value = updatedDevices
                    
                    Log.d(TAG, "Found device: $deviceName ($deviceId)")
                }
            }
        }
        
        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed with error: $errorCode")
        }
    }
    
    /**
     * GATT callback for handling connections and data
     */
    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val deviceId = gatt.device.address
            val deviceName = gatt.device.name ?: "Unknown Device"
            
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.d(TAG, "Connected to $deviceName")
                    
                    // Update device status in list
                    updateDeviceConnectionStatus(deviceId, true)
                    
                    // Discover services
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.d(TAG, "Disconnected from $deviceName")
                    
                    // Update device status in list
                    updateDeviceConnectionStatus(deviceId, false)
                    
                    // Remove from connected devices
                    connectedDevices.remove(deviceId)
                    gatt.close()
                }
            }
        }
        
        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                // Look for heart rate service
                val heartRateService = gatt.getService(HEART_RATE_SERVICE_UUID)
                heartRateService?.let {
                    val heartRateChar = it.getCharacteristic(HEART_RATE_MEASUREMENT_UUID)
                    heartRateChar?.let { characteristic ->
                        // Enable notifications for heart rate
                        enableNotifications(gatt, characteristic)
                    }
                }
                
                // Look for running speed service
                val rscService = gatt.getService(RUNNING_SPEED_CADENCE_SERVICE_UUID)
                rscService?.let {
                    val rscChar = it.getCharacteristic(RSC_MEASUREMENT_UUID)
                    rscChar?.let { characteristic ->
                        // Enable notifications for running speed
                        enableNotifications(gatt, characteristic)
                    }
                }
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
                    updateHeartRate(gatt.device.address, heartRate)
                }
                RSC_MEASUREMENT_UUID -> {
                    val rscData = parseRunningData(value)
                    updateRunningData(rscData.first, rscData.second)
                }
            }
        }
        
        // For compatibility with older Android versions
        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val value = characteristic.value
            when (characteristic.uuid) {
                HEART_RATE_MEASUREMENT_UUID -> {
                    val heartRate = parseHeartRate(value)
                    updateHeartRate(gatt.device.address, heartRate)
                }
                RSC_MEASUREMENT_UUID -> {
                    val rscData = parseRunningData(value)
                    updateRunningData(rscData.first, rscData.second)
                }
            }
        }
    }
    
    /**
     * Enable notifications for a characteristic
     */
    @SuppressLint("MissingPermission")
    private fun enableNotifications(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        // Enable local notifications
        gatt.setCharacteristicNotification(characteristic, true)
        
        // Enable remote notifications
        val descriptor = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG_UUID)
        if (descriptor != null) {
            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            gatt.writeDescriptor(descriptor)
            
            Log.d(TAG, "Enabled notifications for ${characteristic.uuid}")
        }
    }
    
    /**
     * Update device connection status in the list
     */
    private fun updateDeviceConnectionStatus(deviceId: String, connected: Boolean) {
        val devices = _availableDevices.value.toMutableList()
        val deviceIndex = devices.indexOfFirst { it.id == deviceId }
        
        if (deviceIndex != -1) {
            val device = devices[deviceIndex]
            devices[deviceIndex] = device.copy(connected = connected)
            _availableDevices.value = devices
        }
    }
    
    /**
     * Update heart rate for a device
     */
    private fun updateHeartRate(deviceId: String, heartRate: Int) {
        // Update device heart rate in the list
        val devices = _availableDevices.value.toMutableList()
        val deviceIndex = devices.indexOfFirst { it.id == deviceId }
        
        if (deviceIndex != -1) {
            val device = devices[deviceIndex]
            devices[deviceIndex] = device.copy(heartRate = heartRate)
            _availableDevices.value = devices
        }
        
        // Update service data
        _serviceData.value = _serviceData.value.copy(heartRate = heartRate)
        
        Log.d(TAG, "Updated heart rate: $heartRate bpm")
    }
    
    /**
     * Update running data in service data
     */
    private fun updateRunningData(speed: Double, distance: Double?) {
        var updatedServiceData = _serviceData.value.copy(speed = speed)
        
        // Update distance if provided
        if (distance != null) {
            updatedServiceData = updatedServiceData.copy(distance = distance)
        } else {
            // Calculate distance from speed and time if not provided
            val timeHours = runTimeSeconds / 3600.0
            val calculatedDistance = updatedServiceData.distance + (speed * timeHours / 60.0)
            updatedServiceData = updatedServiceData.copy(distance = calculatedDistance)
        }
        
        _serviceData.value = updatedServiceData
        
        Log.d(TAG, "Updated running data - Speed: $speed m/s, Distance: ${updatedServiceData.distance} miles")
    }
    
    /**
     * Parse heart rate from characteristic value
     */
    private fun parseHeartRate(data: ByteArray): Int {
        val format = data[0] and 0x01
        return if (format == 0x01) {
            // Heart rate format with full 16-bit value
            ((data[1].toInt() and 0xFF) + (data[2].toInt() and 0xFF shl 8))
        } else {
            // Heart rate format with 8-bit value
            data[1].toInt() and 0xFF
        }
    }
    
    /**
     * Parse running speed and cadence data
     */
    private fun parseRunningData(data: ByteArray): Pair<Double, Double?> {
        val flags = data[0].toInt() and 0xFF
        val instantSpeedPresent = flags and 0x01 != 0
        val distancePresent = flags and 0x02 != 0
        
        var speed = 0.0
        var distance: Double? = null
        var index = 1
        
        if (instantSpeedPresent) {
            // Speed is in units of 1/256 m/s
            val speedRaw = ((data[index].toInt() and 0xFF) + ((data[index + 1].toInt() and 0xFF) shl 8))
            speed = speedRaw / 256.0
            index += 2
        }
        
        if (distancePresent) {
            // Distance is in meters
            val distanceRaw = ((data[index].toInt() and 0xFF) +
                    ((data[index + 1].toInt() and 0xFF) shl 8) +
                    ((data[index + 2].toInt() and 0xFF) shl 16))
            // Convert to miles
            distance = distanceRaw / 1609.34
        }
        
        return Pair(speed, distance)
    }
    
    /**
     * Check if Bluetooth is available and enabled
     */
    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }
}