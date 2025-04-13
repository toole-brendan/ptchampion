import Foundation
import CoreBluetooth
import Combine

// MARK: - Bluetooth Metrics

struct BluetoothMetrics {
    var heartRate: Int?
    var steps: Int?
    var distance: Double? // in meters
    var speed: Double? // in m/s
    var timeElapsed: TimeInterval?
    
    var formattedHeartRate: String {
        guard let hr = heartRate else { return "-- BPM" }
        return "\(hr) BPM"
    }
    
    var formattedDistance: String {
        guard let dist = distance else { return "-- m" }
        if dist < 1000 {
            return "\(Int(dist)) m"
        } else {
            let km = dist / 1000.0
            return String(format: "%.2f km", km)
        }
    }
    
    var formattedSpeed: String {
        guard let spd = speed else { return "-- m/s" }
        return String(format: "%.1f m/s", spd)
    }
    
    var formattedPace: String {
        guard let spd = speed, spd > 0 else { return "--:-- /km" }
        let paceSeconds = 1000.0 / spd // seconds per kilometer
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    var formattedTime: String {
        guard let time = timeElapsed else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Bluetooth Device

class BluetoothDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let advertisementData: [String: Any]
    let rssi: NSNumber
    var isConnected: Bool = false
    var isConnecting: Bool = false
    var metrics = BluetoothMetrics()
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
    
    var name: String {
        return peripheral.name ?? advertisementData["kCBAdvDataLocalName"] as? String ?? "Unknown Device"
    }
    
    var signalStrength: Int {
        return max(0, min(100, Int(truncating: rssi) + 100))
    }
}

// MARK: - Bluetooth Service Types

enum BluetoothServiceType: String, CaseIterable {
    case heartRate = "0x180D"
    case runningSpeedAndCadence = "0x1814"
    case fitnessMachine = "0x1826"
    
    var uuid: CBUUID {
        return CBUUID(string: rawValue)
    }
    
    var name: String {
        switch self {
        case .heartRate:
            return "Heart Rate Monitor"
        case .runningSpeedAndCadence:
            return "Running Speed & Cadence"
        case .fitnessMachine:
            return "Fitness Machine"
        }
    }
}

// MARK: - Bluetooth Manager

class BluetoothManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isScanning = false
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectedDevices: [BluetoothDevice] = []
    @Published var metrics = BluetoothMetrics()
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var heartRateCharacteristic: CBCharacteristic?
    private var rscCharacteristic: CBCharacteristic?
    private var timer: Timer?
    private var startTime: Date?
    
    // MARK: - Service UUIDs
    
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateCharacteristicUUID = CBUUID(string: "0x2A37")
    
    private let runningSpeedServiceUUID = CBUUID(string: "0x1814")
    private let rscMeasurementCharacteristicUUID = CBUUID(string: "0x2A53")
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        
        isScanning = true
        discoveredDevices = []
        
        let services = BluetoothServiceType.allCases.map { $0.uuid }
        centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
        // Auto-stop scan after 15 seconds to save battery
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to device: BluetoothDevice) {
        stopScanning()
        
        // Mark as connecting
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index].isConnecting = true
        }
        
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect(from device: BluetoothDevice) {
        centralManager.cancelPeripheralConnection(device.peripheral)
    }
    
    func disconnectAll() {
        for device in connectedDevices {
            centralManager.cancelPeripheralConnection(device.peripheral)
        }
        connectedDevices = []
        metrics = BluetoothMetrics()
        stopExerciseTracking()
    }
    
    // MARK: - Exercise Tracking
    
    func startExerciseTracking() {
        startTime = Date()
        metrics.timeElapsed = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.metrics.timeElapsed = Date().timeIntervalSince(startTime)
        }
    }
    
    func stopExerciseTracking() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
    
    func pauseExerciseTracking() {
        // Store current elapsed time
        if let startTime = startTime {
            metrics.timeElapsed = Date().timeIntervalSince(startTime)
        }
        timer?.invalidate()
        timer = nil
    }
    
    func resumeExerciseTracking() {
        if let elapsed = metrics.timeElapsed {
            // Calculate what the start time would have been
            startTime = Date().addingTimeInterval(-elapsed)
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                self.metrics.timeElapsed = Date().timeIntervalSince(startTime)
            }
        } else {
            startExerciseTracking()
        }
    }
    
    // MARK: - Data Processing
    
    private func parseHeartRate(from data: Data) -> Int? {
        guard data.count >= 2 else { return nil }
        
        let firstByte = data[0]
        let isContactDetected = (firstByte & 0x06) != 0
        let hasEnergyExpended = (firstByte & 0x08) != 0
        let isFormat16Bit = (firstByte & 0x01) != 0
        
        var hrValue: Int
        var byteIndex = 1
        
        if isFormat16Bit {
            // 16-bit value
            guard data.count >= 3 else { return nil }
            hrValue = Int(UInt16(data[byteIndex]) | (UInt16(data[byteIndex + 1]) << 8))
            byteIndex += 2
        } else {
            // 8-bit value
            hrValue = Int(data[byteIndex])
            byteIndex += 1
        }
        
        return hrValue
    }
    
    private func parseRunningData(from data: Data) -> (speed: Double, distance: Double?)? {
        guard data.count >= 4 else { return nil }
        
        let flags = data[0]
        let hasStrideLength = (flags & 0x01) != 0
        let hasDistance = (flags & 0x02) != 0
        let instantaneousSpeed = UInt16(data[1]) | (UInt16(data[2]) << 8)
        let speedInMetersPerSecond = Double(instantaneousSpeed) / 256.0
        
        var totalDistance: Double?
        let distanceStartIndex = hasStrideLength ? 6 : 4
        
        if hasDistance && data.count >= distanceStartIndex + 4 {
            let distanceData = data.subdata(in: distanceStartIndex..<(distanceStartIndex + 4))
            let distanceValue = distanceData.withUnsafeBytes { $0.load(as: UInt32.self) }
            totalDistance = Double(distanceValue) / 10.0 // Convert to meters
        }
        
        return (speedInMetersPerSecond, totalDistance)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isAuthorized = true
            errorMessage = nil
        case .poweredOff:
            isAuthorized = false
            errorMessage = "Bluetooth is turned off. Please enable it in settings."
        case .unauthorized:
            isAuthorized = false
            errorMessage = "Bluetooth permissions are required for device connectivity."
        case .unsupported:
            isAuthorized = false
            errorMessage = "Bluetooth LE is not supported on this device."
        default:
            isAuthorized = false
            errorMessage = "Bluetooth is not available."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // Check if device is already discovered
        if let existingDeviceIndex = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            // Update existing device
            let existingDevice = discoveredDevices[existingDeviceIndex]
            discoveredDevices[existingDeviceIndex] = BluetoothDevice(
                peripheral: peripheral,
                advertisementData: advertisementData,
                rssi: RSSI
            )
            discoveredDevices[existingDeviceIndex].isConnected = existingDevice.isConnected
            discoveredDevices[existingDeviceIndex].isConnecting = existingDevice.isConnecting
        } else {
            // Add new device
            let device = BluetoothDevice(
                peripheral: peripheral,
                advertisementData: advertisementData,
                rssi: RSSI
            )
            discoveredDevices.append(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        
        // Update device status
        if let index = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredDevices[index].isConnected = true
            discoveredDevices[index].isConnecting = false
            
            // Add to connected devices if not already there
            if !connectedDevices.contains(where: { $0.id == peripheral.identifier }) {
                connectedDevices.append(discoveredDevices[index])
            }
        }
        
        // Set delegate and discover services
        peripheral.delegate = self
        peripheral.discoverServices([heartRateServiceUUID, runningSpeedServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "Unknown error")")
        
        // Update device status
        if let index = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredDevices[index].isConnected = false
            discoveredDevices[index].isConnecting = false
        }
        
        errorMessage = "Failed to connect to \(peripheral.name ?? "device"): \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "No error")")
        
        // Update device status
        if let index = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredDevices[index].isConnected = false
            discoveredDevices[index].isConnecting = false
        }
        
        // Remove from connected devices
        connectedDevices.removeAll(where: { $0.id == peripheral.identifier })
        
        // Clear metrics if no devices left
        if connectedDevices.isEmpty {
            metrics = BluetoothMetrics()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            
            if service.uuid == heartRateServiceUUID {
                peripheral.discoverCharacteristics([heartRateCharacteristicUUID], for: service)
            } else if service.uuid == runningSpeedServiceUUID {
                peripheral.discoverCharacteristics([rscMeasurementCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            
            if characteristic.uuid == heartRateCharacteristicUUID {
                heartRateCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == rscMeasurementCharacteristicUUID {
                rscCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        if characteristic.uuid == heartRateCharacteristicUUID {
            if let heartRate = parseHeartRate(from: data) {
                DispatchQueue.main.async {
                    self.metrics.heartRate = heartRate
                    
                    // Update device metrics
                    if let index = self.connectedDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                        self.connectedDevices[index].metrics.heartRate = heartRate
                    }
                }
            }
        } else if characteristic.uuid == rscMeasurementCharacteristicUUID {
            if let runningData = parseRunningData(from: data) {
                DispatchQueue.main.async {
                    self.metrics.speed = runningData.speed
                    if let distance = runningData.distance {
                        self.metrics.distance = distance
                    }
                    
                    // Update device metrics
                    if let index = self.connectedDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                        self.connectedDevices[index].metrics.speed = runningData.speed
                        if let distance = runningData.distance {
                            self.connectedDevices[index].metrics.distance = distance
                        }
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications started for \(characteristic.uuid)")
        } else {
            print("Notifications stopped for \(characteristic.uuid)")
        }
    }
}

// MARK: - Bluetooth Device Mock

extension BluetoothDevice {
    static func mockHeartRateMonitor() -> BluetoothDevice {
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "HR Monitor")
        let device = BluetoothDevice(
            peripheral: mockPeripheral,
            advertisementData: ["kCBAdvDataLocalName": "HR Monitor"],
            rssi: -65
        )
        device.isConnected = true
        device.metrics.heartRate = 135
        return device
    }
    
    static func mockRunningDevice() -> BluetoothDevice {
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Running Pod")
        let device = BluetoothDevice(
            peripheral: mockPeripheral,
            advertisementData: ["kCBAdvDataLocalName": "Running Pod"],
            rssi: -72
        )
        device.isConnected = true
        device.metrics.speed = 3.5
        device.metrics.distance = 1254.3
        return device
    }
}

// MARK: - Mock CBPeripheral for SwiftUI Previews

class MockCBPeripheral: CBPeripheral {
    private let mockIdentifier: UUID
    private let mockName: String?
    
    init(identifier: UUID, name: String? = nil) {
        self.mockIdentifier = identifier
        self.mockName = name
        super.init()
    }
    
    override var identifier: UUID {
        return mockIdentifier
    }
    
    override var name: String? {
        return mockName
    }
}