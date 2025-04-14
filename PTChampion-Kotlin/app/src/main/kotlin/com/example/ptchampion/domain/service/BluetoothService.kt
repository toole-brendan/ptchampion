package com.example.ptchampion.domain.service

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

// Replace with your actual device representation
data class BleDevice(val name: String?, val address: String)

enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    FAILED
}

/**
 * Interface for managing Bluetooth LE interactions.
 */
interface BluetoothService {

    /** Flow emitting the current list of discovered BLE devices during a scan. */
    val discoveredDevices: StateFlow<List<BleDevice>>

    /** Flow emitting the current connection state. */
    val connectionState: StateFlow<ConnectionState>

    /** Flow emitting the currently connected device, or null if disconnected. */
    val connectedDevice: StateFlow<BleDevice?>

    /** Flow emitting errors encountered during Bluetooth operations. */
    val errors: Flow<String>

    /** Starts scanning for nearby BLE devices. Requires BLUETOOTH_SCAN permission. */
    suspend fun startScan()

    /** Stops scanning for BLE devices. */
    suspend fun stopScan()

    /** Attempts to connect to a device by its MAC address. Requires BLUETOOTH_CONNECT permission. */
    suspend fun connect(address: String)

    /** Disconnects from the currently connected device. */
    suspend fun disconnect()

    /** Cleans up resources used by the service (unregister receivers, etc.). */
    fun cleanup()

    // TODO: Add methods for reading/writing characteristics if needed
    // suspend fun readHeartRate(): Int?
    // suspend fun writeCommand(command: ByteArray)
} 