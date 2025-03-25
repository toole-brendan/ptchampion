import Foundation
import CoreBluetooth
import Combine

// MARK: - Bluetooth Types

struct BluetoothDevice: Identifiable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    var connected: Bool
    var heartRate: Int?
    var serviceData: ServiceData?
}

struct ServiceData {
    var heartRate: Int?
    var steps: Int?
    var distance: Double?
    var timeElapsed: Int?
    var speed: Double?
}

enum BluetoothError: Error {
    case notSupported
    case unauthorized
    case poweredOff
    case notConnected
    case noDeviceSelected
    case serviceNotFound
    case characteristicNotFound
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .notSupported:
            return "Bluetooth is not supported on this device"
        case .unauthorized:
            return "Bluetooth permission denied"
        case .poweredOff:
            return "Bluetooth is powered off"
        case .notConnected:
            return "Not connected to any device"
        case .noDeviceSelected:
            return "No device selected"
        case .serviceNotFound:
            return "Required service not found"
        case .characteristicNotFound:
            return "Required characteristic not found"
        case .unknown:
            return "An unknown Bluetooth error occurred"
        }
    }
}

// MARK: - Bluetooth Service UUIDs

extension CBUUID {
    // Standard BLE service UUIDs
    static let heartRateService = CBUUID(string: "180D")
    static let heartRateMeasurement = CBUUID(string: "2A37")
    static let runningSpeedService = CBUUID(string: "1814")
    static let rscMeasurement = CBUUID(string: "2A53")
}

// MARK: - Bluetooth Manager

class BluetoothManager: NSObject, ObservableObject {
    // Published properties for SwiftUI
    @Published var devices: [BluetoothDevice] = []
    @Published var isScanning = false
    @Published var error: BluetoothError?
    @Published var serviceData = ServiceData()
    
    // Run tracking properties
    @Published var isRunning = false
    @Published var runStartTime: Date?
    @Published var totalTimeElapsed: Int = 0
    @Published var totalDistance: Double = 0
    
    // CoreBluetooth objects
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    private var peripheralDiscoverySubject = PassthroughSubject<CBPeripheral, Never>()
    
    // For simulation mode
    private var useSimulation = false
    private var simulationTimer: Timer?
    
    // Initialize Bluetooth manager
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    // Start scanning for Bluetooth devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            handleBluetoothNotReady()
            return
        }
        
        isScanning = true
        error = nil
        
        if useSimulation {
            simulateDeviceDiscovery()
        } else {
            // Scan for devices with Heart Rate service and Running Speed service
            centralManager.scanForPeripherals(
                withServices: [.heartRateService, .runningSpeedService],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }
    }
    
    // Stop scanning for Bluetooth devices
    func stopScanning() {
        if !useSimulation {
            centralManager.stopScan()
        }
        isScanning = false
    }
    
    // Connect to a device
    func connectToDevice(withId id: UUID) -> AnyPublisher<Bool, BluetoothError> {
        let resultSubject = PassthroughSubject<Bool, BluetoothError>()
        
        guard let device = devices.first(where: { $0.id == id }) else {
            resultSubject.send(completion: .failure(.noDeviceSelected))
            return resultSubject.eraseToAnyPublisher()
        }
        
        if useSimulation {
            simulateConnection(for: device.peripheral)
            
            // Update device state
            updateDeviceConnectionState(device.peripheral, isConnected: true)
            
            // Start simulating heart rate data
            simulateHeartRateData(for: device.id)
            
            resultSubject.send(true)
            resultSubject.send(completion: .finished)
        } else {
            // Real connection logic
            centralManager.connect(device.peripheral, options: nil)
            
            // Wait for connection event
            NotificationCenter.default.addObserver(forName: .deviceConnected, object: nil, queue: .main) { [weak self] notification in
                if let peripheral = notification.object as? CBPeripheral,
                   peripheral.identifier == device.peripheral.identifier {
                    self?.updateDeviceConnectionState(peripheral, isConnected: true)
                    resultSubject.send(true)
                    resultSubject.send(completion: .finished)
                }
            }
            
            NotificationCenter.default.addObserver(forName: .deviceFailedToConnect, object: nil, queue: .main) { notification in
                if let peripheral = notification.object as? CBPeripheral,
                   peripheral.identifier == device.peripheral.identifier {
                    resultSubject.send(completion: .failure(.notConnected))
                }
            }
        }
        
        return resultSubject.eraseToAnyPublisher()
    }
    
    // Disconnect from a device
    func disconnectDevice(withId id: UUID) {
        guard let device = devices.first(where: { $0.id == id }) else {
            return
        }
        
        if useSimulation {
            // Stop simulating data
            simulationTimer?.invalidate()
            simulationTimer = nil
            
            // Update device state
            updateDeviceConnectionState(device.peripheral, isConnected: false)
        } else {
            // Real disconnection logic
            centralManager.cancelPeripheralConnection(device.peripheral)
        }
    }
    
    // Start run tracking
    func startRun() {
        runStartTime = Date()
        totalDistance = 0
        totalTimeElapsed = 0
        isRunning = true
        
        // Start a timer to update elapsed time
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let startTime = self.runStartTime else {
                timer.invalidate()
                return
            }
            
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            self.totalTimeElapsed = elapsedSeconds
            
            // If using simulation, update distance based on time
            if self.useSimulation || self.serviceData.distance == nil {
                // Simulate a realistic pace of ~9 min/mile (2.98 m/s)
                let distanceInMeters = Double(elapsedSeconds) * 2.98
                self.totalDistance = distanceInMeters
                
                // Update service data
                var newServiceData = self.serviceData
                newServiceData.timeElapsed = elapsedSeconds
                newServiceData.distance = distanceInMeters
                self.serviceData = newServiceData
            }
        }
    }
    
    // Complete run tracking
    func completeRun() -> (timeInSeconds: Int, distanceInMiles: Double) {
        isRunning = false
        
        // Calculate final distance in miles (convert from meters)
        let distanceInMeters = serviceData.distance ?? totalDistance
        let distanceInMiles = distanceInMeters / 1609.34
        
        return (timeInSeconds: totalTimeElapsed, distanceInMiles: (distanceInMiles * 100).rounded() / 100)
    }
    
    // Enable simulation mode for testing without real devices
    func enableSimulationMode() {
        useSimulation = true
    }
    
    // MARK: - Private Methods
    
    private func handleBluetoothNotReady() {
        switch centralManager.state {
        case .unauthorized:
            error = .unauthorized
        case .poweredOff:
            error = .poweredOff
        case .unsupported:
            error = .notSupported
        default:
            error = .unknown
        }
    }
    
    private func updateDeviceConnectionState(_ peripheral: CBPeripheral, isConnected: Bool) {
        guard let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            return
        }
        
        devices[index].connected = isConnected
    }
    
    private func updateDeviceHeartRate(_ peripheral: CBPeripheral, heartRate: Int) {
        guard let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else {
            return
        }
        
        devices[index].heartRate = heartRate
        
        // Also update service data
        var newServiceData = serviceData
        newServiceData.heartRate = heartRate
        serviceData = newServiceData
    }
    
    // MARK: - Simulation Methods
    
    private func simulateDeviceDiscovery() {
        // Delay to simulate scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Create simulated device objects
            let simulatedDevices = [
                CBPeripheral.createSimulated(name: "Apple Watch Series 8"),
                CBPeripheral.createSimulated(name: "Garmin Forerunner 955"),
                CBPeripheral.createSimulated(name: "Fitbit Versa 4")
            ]
            
            // Add them to the devices list
            for peripheral in simulatedDevices {
                self.devices.append(BluetoothDevice(
                    id: peripheral.identifier,
                    name: peripheral.name ?? "Unknown Device",
                    peripheral: peripheral,
                    connected: false
                ))
            }
            
            // End scanning after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isScanning = false
            }
        }
    }
    
    private func simulateConnection(for peripheral: CBPeripheral) {
        // Simulate connection delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.discoverServices(for: peripheral)
        }
    }
    
    private func simulateHeartRateData(for deviceId: UUID) {
        var heartRate = 75 // Starting heart rate
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            // Simulate a realistic heart rate during exercise (between 75-180)
            heartRate += Int.random(in: -1...2)
            heartRate = min(max(heartRate, 75), 180)
            
            guard let self = self,
                  let device = self.devices.first(where: { $0.id == deviceId }),
                  let index = self.devices.firstIndex(where: { $0.id == deviceId }) else {
                return
            }
            
            // Update device heart rate
            self.devices[index].heartRate = heartRate
            
            // Update service data
            var newServiceData = self.serviceData
            newServiceData.heartRate = heartRate
            
            // Also simulate speed and distance for run tracking if running
            if self.isRunning {
                // Simulate speed variations (in m/s, around 2.98 m/s which is ~11 min/mile pace)
                let speed = 2.98 + Double.random(in: -0.2...0.2)
                newServiceData.speed = speed
            }
            
            self.serviceData = newServiceData
        }
    }
    
    // MARK: - Bluetooth Service Discovery
    
    private func discoverServices(for peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        if !useSimulation {
            peripheral.discoverServices([.heartRateService, .runningSpeedService])
        } else {
            // Simulate services discovery
            simulateServiceDiscovery(for: peripheral)
        }
    }
    
    private func simulateServiceDiscovery(for peripheral: CBPeripheral) {
        // This would normally be handled by the CBPeripheralDelegate methods
        // For simulation, we directly update the heart rate
        simulateHeartRateData(for: peripheral.identifier)
    }
    
    // Parse heart rate data from characteristic value
    private func parseHeartRate(from data: Data) -> Int {
        let heartRateFormat = data[0] & 0x01
        var heartRate: Int = 0
        
        if heartRateFormat == 0 {  // 8-bit format
            heartRate = Int(data[1])
        } else {  // 16-bit format
            heartRate = Int(data[1]) | (Int(data[2]) << 8)
        }
        
        return heartRate
    }
    
    // Parse running speed data from characteristic value
    private func parseRunningData(from data: Data) -> (speed: Double, distance: Double?) {
        let flags = data[0]
        let speedPresent = (flags & 0x01) != 0
        let distancePresent = (flags & 0x04) != 0
        
        var speed: Double = 0
        var distance: Double?
        
        var offset = 1
        
        if speedPresent {
            // Speed is in units of 1/256 m/s
            let rawSpeed = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
            speed = Double(rawSpeed) / 256.0
            offset += 2
        }
        
        // Skip cadence if present
        if (flags & 0x02) != 0 {
            offset += 1
        }
        
        if distancePresent {
            // Distance is in meters
            let rawDistance = UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) |
                             (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24)
            distance = Double(rawDistance)
        }
        
        return (speed, distance)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            handleBluetoothNotReady()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Avoid duplicates
        if devices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            return
        }
        
        // Create device object
        let device = BluetoothDevice(
            id: peripheral.identifier,
            name: peripheral.name ?? "Unknown Device",
            peripheral: peripheral,
            connected: false
        )
        
        // Add to devices list
        DispatchQueue.main.async { [weak self] in
            self?.devices.append(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Update connection state
        updateDeviceConnectionState(peripheral, isConnected: true)
        
        // Discover services
        discoverServices(for: peripheral)
        
        // Post notification
        NotificationCenter.default.post(name: .deviceConnected, object: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Update connection state
        updateDeviceConnectionState(peripheral, isConnected: false)
        
        // Post notification
        NotificationCenter.default.post(name: .deviceFailedToConnect, object: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Update connection state
        updateDeviceConnectionState(peripheral, isConnected: false)
        
        // Post notification
        NotificationCenter.default.post(name: .deviceDisconnected, object: peripheral)
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            if service.uuid == .heartRateService {
                peripheral.discoverCharacteristics([.heartRateMeasurement], for: service)
            } else if service.uuid == .runningSpeedService {
                peripheral.discoverCharacteristics([.rscMeasurement], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid == .heartRateMeasurement || characteristic.uuid == .rscMeasurement {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let data = characteristic.value else {
            return
        }
        
        if characteristic.uuid == .heartRateMeasurement {
            let heartRate = parseHeartRate(from: data)
            DispatchQueue.main.async { [weak self] in
                self?.updateDeviceHeartRate(peripheral, heartRate: heartRate)
            }
        }
        else if characteristic.uuid == .rscMeasurement {
            let (speed, distance) = parseRunningData(from: data)
            DispatchQueue.main.async { [weak self] in
                var newServiceData = self?.serviceData ?? ServiceData()
                newServiceData.speed = speed
                if let distance = distance {
                    newServiceData.distance = distance
                }
                self?.serviceData = newServiceData
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let deviceConnected = Notification.Name("BluetoothDeviceConnected")
    static let deviceFailedToConnect = Notification.Name("BluetoothDeviceFailedToConnect")
    static let deviceDisconnected = Notification.Name("BluetoothDeviceDisconnected")
}

// MARK: - Simulated Peripheral Extension

extension CBPeripheral {
    static func createSimulated(name: String) -> CBPeripheral {
        // This is a mock implementation since we can't create CBPeripherals directly
        // In a real app, we would use proper dependency injection or mocking frameworks
        let mock = MockPeripheral(name: name)
        return mock as! CBPeripheral
    }
}

// This would be properly implemented with a mocking framework
private class MockPeripheral: CBPeripheral {
    let mockName: String
    let mockIdentifier = UUID()
    
    init(name: String) {
        self.mockName = name
        super.init()
    }
    
    override var name: String? {
        return mockName
    }
    
    override var identifier: UUID {
        return mockIdentifier
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}