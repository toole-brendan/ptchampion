package com.example.ptchampion.data.service // Place in data layer

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.* // Import necessary Bluetooth classes
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.ptchampion.domain.service.BleDevice
import com.example.ptchampion.domain.service.BluetoothService
import com.example.ptchampion.domain.service.ConnectionState
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.* // For UUIDs
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BluetoothServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : BluetoothService {

    private val TAG = "BluetoothServiceImpl"
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
    private val bluetoothAdapter = bluetoothManager?.adapter
    private var bluetoothLeScanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner
    private var gatt: BluetoothGatt? = null

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val handler = Handler(Looper.getMainLooper())
    private val scanTimeoutMillis = 15000L // Stop scan after 15 seconds

    private val _discoveredDevices = MutableStateFlow<List<BleDevice>>(emptyList())
    override val discoveredDevices: StateFlow<List<BleDevice>> = _discoveredDevices.asStateFlow()

    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    override val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()

    private val _connectedDevice = MutableStateFlow<BleDevice?>(null)
    override val connectedDevice: StateFlow<BleDevice?> = _connectedDevice.asStateFlow()

    private val _errors = MutableSharedFlow<String>()
    override val errors: Flow<String> = _errors.asSharedFlow()

    private val scanResults = mutableMapOf<String, BluetoothDevice>()

    // TODO: Implement permission checks properly before calling scan/connect
    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private val requiredPermissions:
    List<String>
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.ACCESS_FINE_LOCATION)
        }

    private fun allPermissionsGranted(): Boolean {
        return requiredPermissions.all { hasPermission(it) }
    }

    @SuppressLint("MissingPermission") // Permissions should be checked before calling
    override suspend fun startScan() {
        if (!allPermissionsGranted()) {
            _errors.emit("Required Bluetooth permissions not granted.")
            return
        }
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            _errors.emit("Bluetooth is not enabled.")
            return
        }
        if (_connectionState.value != ConnectionState.DISCONNECTED) {
            _errors.emit("Cannot scan while connected or connecting.")
            return
        }

        bluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner // Re-check scanner
        if (bluetoothLeScanner == null) {
             _errors.emit("Could not get BLE scanner.")
             return
        }

        Log.d(TAG, "Starting BLE scan...")
        scanResults.clear()
        _discoveredDevices.value = emptyList()

        // TODO: Add ScanSettings and ScanFilter if needed
        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            bluetoothLeScanner?.startScan(null, scanSettings, leScanCallback)
            handler.postDelayed({ stopScanInternal() }, scanTimeoutMillis) // Stop scan after timeout
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
        if (!allPermissionsGranted() || bluetoothLeScanner == null) {
             // Don't emit error here, just log, as it might be called automatically
             Log.w(TAG, "Cannot stop scan: Permissions missing or scanner null")
             return
        }
        Log.d(TAG, "Stopping BLE scan.")
        try {
            bluetoothLeScanner?.stopScan(leScanCallback)
            handler.removeCallbacksAndMessages(null) // Remove timeout callbacks
        } catch (e: Exception) {
             Log.e(TAG, "Error stopping scan", e)
            // Don't emit error to UI, might be expected during cleanup
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun connect(address: String) {
         if (!allPermissionsGranted()) {
            _errors.emit("Required Bluetooth permissions not granted.")
            return
        }
         if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            _errors.emit("Bluetooth is not enabled.")
            return
        }
        if (_connectionState.value != ConnectionState.DISCONNECTED) {
            Log.w(TAG, "Already connected or connecting.")
            return
        }

        stopScanInternal() // Stop scanning before connecting

        val device = bluetoothAdapter.getRemoteDevice(address)
        if (device == null) {
            _errors.emit("Device not found with address: $address")
            return
        }

        Log.d(TAG, "Attempting to connect to $address")
        _connectionState.value = ConnectionState.CONNECTING
        _connectedDevice.value = BleDevice(device.name, device.address) // Tentative

        // Connect on the main thread
        serviceScope.launch(Dispatchers.Main) {
            try {
                gatt = device.connectGatt(context, false, gattCallback)
            } catch (e: Exception) {
                 Log.e(TAG, "Error connecting to GATT", e)
                _errors.emit("Failed to initiate connection: ${e.message}")
                _connectionState.value = ConnectionState.FAILED
                _connectedDevice.value = null
                gatt = null
            }
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun disconnect() {
         if (!allPermissionsGranted()) {
            // Log error, but allow disconnect attempt anyway
             Log.w(TAG, "Permissions missing, attempting disconnect anyway")
        }
        Log.d(TAG, "Disconnecting...")
        gatt?.disconnect()
        // State change handled in gattCallback
    }

    @SuppressLint("MissingPermission")
    override fun cleanup() {
        Log.d(TAG, "Cleaning up BluetoothService")
        stopScanInternal()
        gatt?.close()
        gatt = null
        _connectionState.value = ConnectionState.DISCONNECTED
        _connectedDevice.value = null
    }

    private val leScanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            result?.device?.let {
                device ->
                if (device.address != null && !scanResults.containsKey(device.address)) {
                     // Check permissions again before accessing name
                    val deviceName = if (allPermissionsGranted()) device.name else "Name Unavailable"
                    Log.d(TAG, "Device found: ${deviceName ?: "Unknown"} (${device.address})")
                    scanResults[device.address] = device
                    _discoveredDevices.value = scanResults.values.map { BleDevice(if (allPermissionsGranted()) it.name else "Name Unavailable", it.address) }
                }
            }
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            super.onBatchScanResults(results)
            // Handle batch results if needed
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            Log.e(TAG, "BLE Scan Failed: $errorCode")
            serviceScope.launch {
                 _errors.emit("BLE Scan Failed with error code: $errorCode")
            }
            stopScanInternal()
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            val deviceAddress = gatt?.device?.address
            Log.d(TAG, "GATT Connection State Changed: Address=$deviceAddress, Status=$status, NewState=$newState")

            if (!allPermissionsGranted()) {
                Log.e(TAG, "Permissions missing during connection state change!")
                 // Attempt to close connection if something went wrong
                 gatt?.close()
                 this@BluetoothServiceImpl.gatt = null
                 _connectionState.value = ConnectionState.FAILED
                 _connectedDevice.value = null
                return
            }

            when (status) {
                BluetoothGatt.GATT_SUCCESS -> {
                    when (newState) {
                        BluetoothProfile.STATE_CONNECTED -> {
                            Log.i(TAG, "Connected to GATT server $deviceAddress")
                            _connectionState.value = ConnectionState.CONNECTED
                             _connectedDevice.value = gatt?.device?.let { BleDevice(it.name, it.address) }
                            // TODO: Discover services after connection
                            // serviceScope.launch { delay(500); gatt?.discoverServices() }
                        }
                        BluetoothProfile.STATE_DISCONNECTED -> {
                            Log.i(TAG, "Disconnected from GATT server $deviceAddress")
                            gatt?.close() // Clean up resources
                            this@BluetoothServiceImpl.gatt = null
                            _connectionState.value = ConnectionState.DISCONNECTED
                             _connectedDevice.value = null
                        }
                    }
                }
                else -> {
                     // Handle other GATT errors (e.g., 133, 8, etc.)
                     Log.e(TAG, "GATT Error: Status=$status, disconnecting $deviceAddress")
                     gatt?.close()
                     this@BluetoothServiceImpl.gatt = null
                     _connectionState.value = ConnectionState.FAILED
                     _connectedDevice.value = null
                     serviceScope.launch { _errors.emit("Connection failed with status: $status") }
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "Services discovered for ${gatt?.device?.address}")
                // TODO: Interact with services/characteristics now
                // Example: readHeartRateCharacteristic()
            } else {
                Log.w(TAG, "onServicesDiscovered received: $status")
                 serviceScope.launch { _errors.emit("Service discovery failed with status: $status") }
            }
        }

        // TODO: Implement onCharacteristicRead, onCharacteristicWrite, onCharacteristicChanged etc.
    }

} 