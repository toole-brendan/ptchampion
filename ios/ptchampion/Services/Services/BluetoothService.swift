import Foundation
import CoreBluetooth
import Combine

// Define known Service UUIDs (Add more as needed)
struct KnownServiceUUIDs {
    static let heartRate = CBUUID(string: "180D")
    static let locationAndNavigation = CBUUID(string: "1819")
    static let deviceInformation = CBUUID(string: "180A")
    // Add UUIDs specific to Garmin, Polar, etc. if known and useful for filtering
}

// Define known Characteristic UUIDs
struct KnownCharacteristicUUIDs {
    // Heart Rate Service
    static let heartRateMeasurement = CBUUID(string: "2A37") // Notify
    static let bodySensorLocation = CBUUID(string: "2A38")   // Read
    
    // Location and Navigation Service
    static let lnFeature = CBUUID(string: "2AB5")            // Read
    static let locationAndSpeed = CBUUID(string: "2A67")     // Notify
    // Add others like Position Quality (2A69), LN Control Point (2A6B) if needed
    
    // Device Information Service
    static let manufacturerName = CBUUID(string: "2A29")   // Read
    static let modelNumber = CBUUID(string: "2A24")      // Read
    static let firmwareRevision = CBUUID(string: "2A26")  // Read
}

// Represents a discovered peripheral with its advertisement data
struct DiscoveredPeripheral: Identifiable, Equatable {
    let peripheral: CBPeripheral
    let advertisementData: [String: Any]
    var rssi: NSNumber
    
    var id: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? "Unknown Device" }

    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        lhs.id == rhs.id
    }
}

// Enum representing the connection state of a peripheral
enum PeripheralConnectionState {
    case disconnected(error: Error? = nil)
    case connecting
    case connected(peripheral: CBPeripheral)
    case disconnecting
    case failed(error: Error?)
}

// Define potential Bluetooth errors
enum BluetoothError: Error, LocalizedError {
    case poweredOff
    case connectionTimeout
    case serviceNotFound
    case characteristicNotFound
    case readFailed(Error?)
    case writeFailed(Error?)
    case pairingFailed

    var errorDescription: String? {
        switch self {
        case .poweredOff: return "Bluetooth is currently powered off."
        case .connectionTimeout: return "Connection attempt timed out."
        case .serviceNotFound: return "Required service not found on the peripheral."
        case .characteristicNotFound: return "Required characteristic not found on the peripheral."
        case .readFailed(let err): return "Failed to read characteristic. Error: \(err?.localizedDescription ?? "Unknown")"
        case .writeFailed(let err): return "Failed to write characteristic. Error: \(err?.localizedDescription ?? "Unknown")"
        case .pairingFailed: return "Pairing with the peripheral failed."
        }
    }
}

// Protocol for Bluetooth interactions
protocol BluetoothServiceProtocol {
    var centralManagerStatePublisher: AnyPublisher<CBManagerState, Never> { get }
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> { get }
    var connectionStatePublisher: AnyPublisher<PeripheralConnectionState, Never> { get }
    var connectedPeripheralPublisher: AnyPublisher<CBPeripheral?, Never> { get }
    var heartRatePublisher: AnyPublisher<Int, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var manufacturerNamePublisher: AnyPublisher<String?, Never> { get }
    var locationServiceAvailablePublisher: AnyPublisher<Bool, Never> { get }
    
    func startScan()
    func stopScan()
    func connect(peripheral: CBPeripheral)
    func disconnect()
}

class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    private var centralManager: CBCentralManager!
    
    // Combine Publishers
    private let centralManagerStateSubject = CurrentValueSubject<CBManagerState, Never>(.unknown)
    var centralManagerStatePublisher: AnyPublisher<CBManagerState, Never> {
        centralManagerStateSubject.eraseToAnyPublisher()
    }
    
    private let discoveredPeripheralsSubject = CurrentValueSubject<[DiscoveredPeripheral], Never>([])
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> {
        discoveredPeripheralsSubject.eraseToAnyPublisher()
    }
    
    private let connectionStateSubject = CurrentValueSubject<PeripheralConnectionState, Never>(.disconnected())
    var connectionStatePublisher: AnyPublisher<PeripheralConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    private let connectedPeripheralSubject = CurrentValueSubject<CBPeripheral?, Never>(nil)
    var connectedPeripheralPublisher: AnyPublisher<CBPeripheral?, Never> {
        connectedPeripheralSubject.eraseToAnyPublisher()
    }
    
    private let heartRateSubject = PassthroughSubject<Int, Never>()
    var heartRatePublisher: AnyPublisher<Int, Never> {
        heartRateSubject.eraseToAnyPublisher()
    }
    
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    private let manufacturerNameSubject = CurrentValueSubject<String?, Never>(nil)
    var manufacturerNamePublisher: AnyPublisher<String?, Never> {
        manufacturerNameSubject.eraseToAnyPublisher()
    }
    
    private let locationServiceAvailableSubject = CurrentValueSubject<Bool, Never>(false)
    var locationServiceAvailablePublisher: AnyPublisher<Bool, Never> {
        locationServiceAvailableSubject.eraseToAnyPublisher()
    }
    
    private var peripheralToConnect: CBPeripheral?
    private var connectedPeripheralServices: [CBService]?

    override init() {
        super.init()
        // Initialize CBCentralManager on the main queue. 
        // A background queue can be used if lots of processing is needed, but delegate methods must be dispatched back to main thread for UI updates.
        centralManager = CBCentralManager(delegate: self, queue: nil) 
        print("BluetoothService: Initialized CBCentralManager.")
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else {
            print("BluetoothService: Cannot scan, Bluetooth is not powered on. State: \(centralManager.state.description)")
            return
        }
        
        // Clear previously discovered peripherals when starting a new scan
        discoveredPeripheralsSubject.send([]) 
        
        print("BluetoothService: Starting scan for Heart Rate and Location/Navigation services...")
        let serviceUUIDs: [CBUUID] = [KnownServiceUUIDs.heartRate, KnownServiceUUIDs.locationAndNavigation]
        
        // Scan only for peripherals advertising the specified services
        // Set allowDuplicates to true if you want updates for already discovered peripherals (e.g., RSSI changes)
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // To scan for *all* devices (useful for finding devices not advertising specific services):
        // centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScan() {
        guard centralManager.isScanning else { return }
        centralManager.stopScan()
        print("BluetoothService: Stopped scan.")
    }
    
    func connect(peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            print("BluetoothService: Cannot connect, Bluetooth is not powered on.")
            connectionStateSubject.send(.failed(error: BluetoothError.poweredOff))
            return
        }
        
        guard connectionStateSubject.value.isDisconnected else {
             print("BluetoothService: Cannot connect, already connected or connecting.")
             return
        }
        
        print("BluetoothService: Attempting to connect to \(peripheral.name ?? peripheral.identifier.uuidString)...")
        stopScan() // Stop scanning when attempting connection
        
        peripheralToConnect = peripheral // Store the target peripheral
        connectionStateSubject.send(.connecting)
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let connectedPeripheral = connectedPeripheralSubject.value else {
            print("BluetoothService: Cannot disconnect, no peripheral connected.")
            // If connecting, cancel the connection attempt
            if let peripheral = peripheralToConnect {
                 print("BluetoothService: Cancelling connection attempt to \(peripheral.name ?? "Unknown")")
                 centralManager.cancelPeripheralConnection(peripheral)
                 connectionStateSubject.send(.disconnected())
                 peripheralToConnect = nil
            }
            return
        }
        
        print("BluetoothService: Disconnecting from \(connectedPeripheral.name ?? "Unknown")")
        connectionStateSubject.send(.disconnecting)
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
    
    // TODO: Implement methods to interact with connected peripherals (read/write characteristics)
}

// MARK: - CBCentralManagerDelegate
extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerStateSubject.send(central.state)
        print("BluetoothService: Central Manager state updated: \(central.state.description)")
        
        switch central.state {
        case .poweredOn:
            print("BluetoothService: Bluetooth is Powered ON.")
            // Start scanning automatically or wait for explicit call
            // startScan()
        case .poweredOff:
            print("BluetoothService: Bluetooth is Powered OFF.")
            // Stop scan, invalidate connections etc.
            stopScan()
        case .resetting:
            print("BluetoothService: Bluetooth is resetting.")
            // Handle resetting state
        case .unauthorized:
            print("BluetoothService: Bluetooth is unauthorized.")
            // Handle unauthorized state (User denied permission)
        case .unsupported:
            print("BluetoothService: Bluetooth is unsupported on this device.")
            // Handle unsupported state
        case .unknown:
            print("BluetoothService: Bluetooth state is unknown.")
            // Handle unknown state
        @unknown default:
            print("BluetoothService: Unknown Bluetooth state encountered.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // This is where discovered peripherals are handled
        print("BluetoothService: Discovered peripheral: \(peripheral.name ?? "Unnamed") [\(peripheral.identifier.uuidString)] RSSI: \(RSSI)")
        
        let discovered = DiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        
        // Update the list of discovered peripherals
        var currentList = discoveredPeripheralsSubject.value
        if let existingIndex = currentList.firstIndex(where: { $0.id == discovered.id }) {
            // Update existing entry (e.g., RSSI)
            currentList[existingIndex].rssi = RSSI
            // Optionally update advertisementData if needed
        } else {
            // Add new peripheral
            currentList.append(discovered)
        }
        
        // Publish the updated list (consider sorting by RSSI or name)
        discoveredPeripheralsSubject.send(currentList.sorted { $0.name < $1.name }) 
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BluetoothService: Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        
        // Clear previous service/availability state
        connectedPeripheralServices = nil 
        locationServiceAvailableSubject.send(false) 
        
        // Ensure this is the peripheral we intended to connect to
        guard peripheral == peripheralToConnect else {
            print("BluetoothService: Connected to unexpected peripheral \(peripheral.identifier). Disconnecting.")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        connectedPeripheralSubject.send(peripheral)
        connectionStateSubject.send(.connected(peripheral: peripheral))
        peripheralToConnect = nil // Clear the target peripheral
        
        // Set delegate and discover services
        peripheral.delegate = self
        print("BluetoothService: Discovering services for \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices(nil) // Discover all services for now; specify UUIDs later if needed
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        print("BluetoothService: Failed to connect to peripheral: \(peripheral.name ?? "Unnamed"). Error: \(errorMessage)")
        
        // Ensure this is the peripheral we intended to connect to
        guard peripheral == peripheralToConnect else {
            print("BluetoothService: Failed to connect to unexpected peripheral \(peripheral.identifier).")
            return
        }
        
        connectionStateSubject.send(.failed(error: error))
        peripheralToConnect = nil // Clear the target peripheral
        connectedPeripheralSubject.send(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let reason = error == nil ? "Clean disconnect" : "Error: \(error!.localizedDescription)"
        print("BluetoothService: Disconnected from peripheral: \(peripheral.name ?? "Unnamed"). Reason: \(reason)")
        
        // Clear state if this was the active peripheral
        if peripheral == connectedPeripheralSubject.value {
            connectionStateSubject.send(.disconnected(error: error))
            connectedPeripheralSubject.send(nil)
            connectedPeripheralServices = nil // Clear services
            locationServiceAvailableSubject.send(false) // Reset availability
        }
        
        // If we were trying to connect to this peripheral and it disconnected unexpectedly, treat as failure
        if peripheral == peripheralToConnect {
             print("BluetoothService: Disconnected while attempting connection.")
             connectionStateSubject.send(.failed(error: error ?? BluetoothError.connectionTimeout)) // Or a more specific error
             peripheralToConnect = nil
        }
        
        // Optionally attempt to reconnect or notify the user
    }
}

// MARK: - CBPeripheralDelegate (Add Placeholder)
// We need this extension for service/characteristic discovery later
extension BluetoothService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("BluetoothService: Error discovering services for \(peripheral.identifier): \(error.localizedDescription)")
            // Handle error, maybe disconnect or retry?
            disconnect() // Example: Disconnect on failure
            return
        }
        
        guard let services = peripheral.services else {
            print("BluetoothService: No services found for \(peripheral.identifier)")
            connectedPeripheralServices = [] // Store empty list
            locationServiceAvailableSubject.send(false) // Mark as unavailable
            return
        }
        
        print("BluetoothService: Discovered \(services.count) services for \(peripheral.name ?? "Unknown")")
        connectedPeripheralServices = services // Store discovered services
        
        // Check if Location & Navigation service is among them
        let hasLocationService = services.contains { $0.uuid == KnownServiceUUIDs.locationAndNavigation }
        locationServiceAvailableSubject.send(hasLocationService)
        print("BluetoothService: Location & Navigation Service Available: \(hasLocationService)")

        for service in services {
            print("  -> Service: \(service.uuid.uuidString) (\(service.uuid.description))")
            // Discover characteristics only for services we are interested in
            let servicesToExplore = [
                KnownServiceUUIDs.heartRate,
                KnownServiceUUIDs.locationAndNavigation,
                KnownServiceUUIDs.deviceInformation
                // Add other custom service UUIDs if needed
            ]
            
            if servicesToExplore.contains(service.uuid) {
                print("    Discovering characteristics for service \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(nil, for: service) // Discover all characteristics for this service
            } else {
                 print("    Skipping characteristic discovery for service \(service.uuid.uuidString)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("BluetoothService: Error discovering characteristics for service \(service.uuid.uuidString): \(error.localizedDescription)")
            // Handle error for this specific service
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("BluetoothService: No characteristics found for service \(service.uuid.uuidString)")
            return
        }
        
        print("    Discovered \(characteristics.count) characteristics for service \(service.uuid.uuidString)")
        for characteristic in characteristics {
            print("      -> Characteristic: \(characteristic.uuid.uuidString) (\(characteristic.uuid.description)) | Properties: \(characteristic.properties.description)")
            
            // Check properties and interact (read value or subscribe to notifications)
            switch characteristic.uuid {
            // --- Heart Rate ---
            case KnownCharacteristicUUIDs.heartRateMeasurement:
                if characteristic.properties.contains(.notify) {
                    print("        Subscribing to Heart Rate Measurement notifications...")
                    peripheral.setNotifyValue(true, for: characteristic)
                } else {
                    print("        Heart Rate Measurement characteristic does not support notifications.")
                }
                
            // --- Location and Navigation ---
            case KnownCharacteristicUUIDs.locationAndSpeed:
                 if characteristic.properties.contains(.notify) {
                    print("        Subscribing to Location and Speed notifications...")
                    peripheral.setNotifyValue(true, for: characteristic)
                } else {
                    print("        Location and Speed characteristic does not support notifications.")
                }
                
            // --- Device Information (Example: Read Manufacturer Name) ---
            case KnownCharacteristicUUIDs.manufacturerName:
                if characteristic.properties.contains(.read) {
                    print("        Reading Manufacturer Name...")
                    peripheral.readValue(for: characteristic)
                }
                
            // Add cases for other characteristics you need (e.g., LN Feature, Model Number)
            default:
                 // print("        Ignoring characteristic \(characteristic.uuid.uuidString)")
                 break
            }
        }
        
        // TODO: Once all desired characteristics are found/subscribed, maybe publish a "ready" state?
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BluetoothService: Error updating value for characteristic \(characteristic.uuid.uuidString): \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("BluetoothService: Received nil data for characteristic \(characteristic.uuid.uuidString)")
            return
        }
        
        // Data received, now parse it based on the characteristic UUID
        print("BluetoothService: Received data for \(characteristic.uuid.uuidString): \(data.hexEncodedString())") // Log raw hex data
        
        switch characteristic.uuid {
            case KnownCharacteristicUUIDs.heartRateMeasurement:
                if let heartRate = parseHeartRate(data: data) {
                    heartRateSubject.send(heartRate)
                }
                break
                
            case KnownCharacteristicUUIDs.locationAndSpeed:
                if let location = parseLocationAndSpeed(data: data) {
                    locationSubject.send(location)
                }
                break
                
            case KnownCharacteristicUUIDs.manufacturerName:
                if let manufacturer = parseUTF8String(data: data) {
                    manufacturerNameSubject.send(manufacturer)
                }
                break
                
            // Add cases for other characteristics being read/notified
            default:
                 print("        Received update for unhandled characteristic: \(characteristic.uuid.uuidString)")
                 break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BluetoothService: Error changing notification state for \(characteristic.uuid.uuidString): \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
             print("BluetoothService: Successfully subscribed to notifications for \(characteristic.uuid.uuidString)")
             // If it's the last characteristic we needed to subscribe to, maybe update state to "ready"
        } else {
            print("BluetoothService: Unsubscribed from notifications for \(characteristic.uuid.uuidString)")
        }
    }
    
    // Add other CBPeripheralDelegate methods if needed (e.g., didWriteValueFor, didReadRSSI)
}

// MARK: - Data Parsing Helpers
private extension BluetoothService {
    
    // Parses Heart Rate Measurement characteristic data (UUID 2A37)
    // Reference: https://www.bluetooth.com/specifications/gatt/characteristics/
    func parseHeartRate(data: Data) -> Int? {
        guard data.count >= 2 else { return nil }
        
        let flags = data[0]
        let isUInt16Format = (flags & 0x01) != 0 // Check if HR value is UInt16 or UInt8
        
        if isUInt16Format {
            guard data.count >= 3 else { return nil }
            let hrValue = UInt16(data[2]) << 8 | UInt16(data[1]) // Little-endian
            return Int(hrValue)
        } else {
            let hrValue = data[1]
            return Int(hrValue)
        }
        // Note: This parser ignores other data like Energy Expended, RR-Intervals
    }
    
    // Parses Location and Speed characteristic data (UUID 2A67)
    // Reference: https://www.bluetooth.com/specifications/gatt/characteristics/
    func parseLocationAndSpeed(data: Data) -> CLLocation? {
        // Flags (first 2 bytes) indicate which fields are present
        guard data.count >= 2 else { return nil }
        let flags = UInt16(data[1]) << 8 | UInt16(data[0]) // Little-endian
        
        let instantaneousSpeedPresent = (flags & 0x0001) != 0
        let totalDistancePresent = (flags & 0x0002) != 0
        let locationPresent = (flags & 0x0004) != 0
        let elevationPresent = (flags & 0x0008) != 0
        let headingPresent = (flags & 0x0010) != 0
        let rollingTimePresent = (flags & 0x0020) != 0
        let utcTimePresent = (flags & 0x0040) != 0

        var currentOffset = 2 // Start reading after flags
        var speed: Double? = nil
        var latitude: Int32? = nil
        var longitude: Int32? = nil
        var elevation: Int? = nil // Stored as Sint24 technically
        var heading: UInt16? = nil
        var timestamp: Date? = nil

        if instantaneousSpeedPresent {
            guard data.count >= currentOffset + 2 else { return nil }
            let speedRaw = UInt16(data[currentOffset+1]) << 8 | UInt16(data[currentOffset])
            speed = Double(speedRaw) * 0.01 // Resolution is 0.01 m/s
            currentOffset += 2
        }
        
        if totalDistancePresent { 
            // Skip total distance (3 bytes)
             guard data.count >= currentOffset + 3 else { return nil }
             currentOffset += 3 
        }
        
        if locationPresent {
            guard data.count >= currentOffset + 8 else { return nil }
            latitude = data[currentOffset..<currentOffset+4].toInt32(littleEndian: true)
            longitude = data[currentOffset+4..<currentOffset+8].toInt32(littleEndian: true)
            currentOffset += 8
        }
        
        if elevationPresent { 
            guard data.count >= currentOffset + 3 else { return nil }
            // Sint24 parsing (handle sign extension manually)
            let rawValue = (UInt32(data[currentOffset+2]) << 16) | (UInt32(data[currentOffset+1]) << 8) | UInt32(data[currentOffset])
            if (rawValue & 0x800000) != 0 { // Check sign bit
                 elevation = Int(Int32(rawValue | 0xFF000000)) // Sign extend
            } else {
                 elevation = Int(rawValue)
            }
            // elevation resolution is 0.01 meters - adjust if needed
            currentOffset += 3 
        }
        
        if headingPresent { 
            guard data.count >= currentOffset + 2 else { return nil }
            heading = UInt16(data[currentOffset+1]) << 8 | UInt16(data[currentOffset])
            // heading resolution is 0.01 degrees
            currentOffset += 2 
        }
        
        if rollingTimePresent { 
            // Skip rolling time (1 byte)
             guard data.count >= currentOffset + 1 else { return nil }
             currentOffset += 1
         }
        
        if utcTimePresent { 
            // Skip UTC time (7 bytes - year, month, day, h, m, s)
             guard data.count >= currentOffset + 7 else { return nil }
             // TODO: Parse date if needed for CLLocation timestamp
             // year = UInt16(data[currentOffset+1]) << 8 | UInt16(data[currentOffset])
             // ... etc
             timestamp = Date() // Use current time as approximation for now
             currentOffset += 7
         }

        // --- Create CLLocation --- 
        guard let latInt = latitude, let lonInt = longitude else {
            return nil // Latitude and longitude are essential
        }
        
        let latDegrees = Double(latInt) * 1e-7 // Resolution 1e-7 degrees
        let lonDegrees = Double(lonInt) * 1e-7 // Resolution 1e-7 degrees
        
        let coordinate = CLLocationCoordinate2D(latitude: latDegrees, longitude: lonDegrees)
        
        var altitudeValue: CLLocationDistance = 0
        if let elev = elevation { altitudeValue = CLLocationDistance(Double(elev) * 0.01) } // Resolution 0.01m
        
        var speedValue: CLLocationSpeed = -1 // -1 indicates invalid
        if let spd = speed { speedValue = CLLocationSpeed(spd) } // Already in m/s
        
        var courseValue: CLLocationDirection = -1 // -1 indicates invalid
        if let head = heading { courseValue = CLLocationDirection(Double(head) * 0.01) } // Resolution 0.01 degrees

        // Accuracy values are not typically provided directly by this characteristic
        let horizontalAccuracy: CLLocationAccuracy = 10.0 // Assume some reasonable accuracy
        let verticalAccuracy: CLLocationAccuracy = 10.0  // Assume some reasonable accuracy

        let location = CLLocation(coordinate: coordinate, 
                                  altitude: altitudeValue, 
                                  horizontalAccuracy: horizontalAccuracy, 
                                  verticalAccuracy: verticalAccuracy, 
                                  course: courseValue, 
                                  courseAccuracy: -1, // Usually unknown from BLE
                                  speed: speedValue, 
                                  speedAccuracy: -1, // Usually unknown from BLE
                                  timestamp: timestamp ?? Date()) // Use parsed or current time
                                  
        return location
    }
    
    // Parses simple UTF-8 string characteristics (e.g., Manufacturer Name 2A29)
    func parseUTF8String(data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }
}

// Helper to convert Data slice to Int32
extension Data {
    func toInt32(littleEndian: Bool) -> Int32? {
        guard count == 4 else { return nil }
        let value = withUnsafeBytes { $0.load(as: Int32.self) }
        return littleEndian ? value.littleEndian : value.bigEndian
    }
}

// Helper extension to log raw data as hex
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// Helper to provide descriptive strings for CBManagerState
extension CBManagerState {
    var description: String {
        switch self {
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown State"
        }
    }
}

// Helper extension for PeripheralConnectionState
extension PeripheralConnectionState {
    var isDisconnected: Bool {
        if case .disconnected = self { return true }
        return false
    }
} 