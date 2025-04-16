package com.example.ptchampion.domain.exercise.bluetooth

import java.util.UUID

/**
 * Constants for GPS Watch Bluetooth integration.
 * Contains manufacturer IDs and standard/custom UUIDs.
 */
object WatchConstants {
    
    /**
     * Bluetooth manufacturer IDs for common GPS watch makers
     */
    object Manufacturers {
        const val GARMIN = 89
        const val POLAR = 130
        const val SUUNTO = 198
        const val FITBIT = 224
        const val WAHOO = 257
    }
    
    /**
     * Standard Bluetooth GATT Services used by fitness devices
     */
    object Services {
        // Standard GATT services
        val HEART_RATE = UUID.fromString("0000180D-0000-1000-8000-00805f9b34fb")
        val RUNNING_SPEED_AND_CADENCE = UUID.fromString("00001814-0000-1000-8000-00805f9b34fb")
        val FITNESS_MACHINE = UUID.fromString("00001826-0000-1000-8000-00805f9b34fb")
        val DEVICE_INFORMATION = UUID.fromString("0000180A-0000-1000-8000-00805f9b34fb")
        val BATTERY = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb")
        val LOCATION_AND_NAVIGATION = UUID.fromString("00001819-0000-1000-8000-00805f9b34fb")
    }
    
    /**
     * Standard Bluetooth GATT Characteristics used by fitness devices
     */
    object Characteristics {
        // Standard GATT characteristics
        val HEART_RATE_MEASUREMENT = UUID.fromString("00002A37-0000-1000-8000-00805f9b34fb")
        val BATTERY_LEVEL = UUID.fromString("00002A19-0000-1000-8000-00805f9b34fb")
        val RSC_MEASUREMENT = UUID.fromString("00002A53-0000-1000-8000-00805f9b34fb") // Running Speed and Cadence
        val LOCATION_AND_SPEED = UUID.fromString("00002A67-0000-1000-8000-00805f9b34fb")
        val LN_FEATURE = UUID.fromString("00002A6A-0000-1000-8000-00805f9b34fb") // Location and Navigation
        val POSITION_QUALITY = UUID.fromString("00002A69-0000-1000-8000-00805f9b34fb")
    }
    
    /**
     * Common Descriptor UUIDs
     */
    object Descriptors {
        val CLIENT_CHARACTERISTIC_CONFIG = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
    
    /**
     * Garmin-specific service and characteristic UUIDs
     * Note: These are examples and may need to be updated based on actual research
     */
    object Garmin {
        // Garmin-specific services
        val FITNESS_SERVICE = UUID.fromString("6A4E3300-667B-11E3-949A-0800200C9A66")
        
        // Garmin-specific characteristics
        val GPS_FEATURE = UUID.fromString("6A4E3301-667B-11E3-949A-0800200C9A66")
        val GPS_LOCATION = UUID.fromString("6A4E3302-667B-11E3-949A-0800200C9A66")
    }
    
    /**
     * Polar-specific service and characteristic UUIDs
     * Note: These are examples and may need to be updated based on actual research
     */
    object Polar {
        // Polar-specific services and characteristics would go here
    }
    
    /**
     * Suunto-specific service and characteristic UUIDs
     * Note: These are examples and may need to be updated based on actual research
     */
    object Suunto {
        // Suunto-specific services and characteristics would go here
    }
    
    /**
     * Common scan parameters
     */
    object ScanSettings {
        const val SCAN_TIMEOUT_MS = 30000L // 30 seconds timeout for scan
        const val CONNECT_TIMEOUT_MS = 10000L // 10 seconds timeout for connection
        const val MAX_RETRY_COUNT = 3 // Maximum number of retry attempts for connection
    }
} 