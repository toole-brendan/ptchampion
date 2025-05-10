import Foundation
import Combine
import CoreBluetooth // Needed for CBManagerState
import CoreLocation

@MainActor // Ensure UI updates are on the main thread
class DeviceScanningViewModel: ObservableObject {
    
    private let bluetoothService: BluetoothServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var connectionState: PeripheralConnectionState = .disconnected()
    @Published var connectedPeripheral: CBPeripheral? = nil
    @Published var isScanning: Bool = false // Track scanning state explicitly
    
    // Published metrics from the connected device
    @Published var heartRate: Int = 0
    @Published var currentPace: RunningPace = RunningPace.zero
    @Published var currentCadence: RunningCadence = RunningCadence.zero
    @Published var currentLocation: CLLocation? = nil
    @Published var deviceType: FitnessDeviceType = .unknown
    @Published var batteryLevel: Int? = nil
    @Published var manufacturerName: String? = nil

    init(bluetoothService: BluetoothServiceProtocol = BluetoothService()) {
        self.bluetoothService = bluetoothService
        subscribeToBluetoothService() 
    }
    
    private func subscribeToBluetoothService() {
        // Subscribe to Bluetooth state changes
        bluetoothService.centralManagerStatePublisher
            .receive(on: DispatchQueue.main) // Ensure updates are on main thread for @Published
            .sink { [weak self] state in
                self?.bluetoothState = state
                // Stop scanning if Bluetooth powers off
                if state != .poweredOn {
                    self?.isScanning = false 
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to discovered peripherals
        bluetoothService.discoveredPeripheralsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.discoveredPeripherals, on: self)
            .store(in: &cancellables)
        
        // Subscribe to connection state changes
        bluetoothService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                // Reset metrics on disconnection
                if case .disconnected = state {
                    self?.resetMetrics()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to connected peripheral changes
        bluetoothService.connectedPeripheralPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectedPeripheral, on: self)
            .store(in: &cancellables)
            
        // Subscribe to heart rate updates
        bluetoothService.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.heartRate, on: self)
            .store(in: &cancellables)
            
        // Subscribe to pace updates
        bluetoothService.pacePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentPace, on: self)
            .store(in: &cancellables)
            
        // Subscribe to cadence updates
        bluetoothService.cadencePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentCadence, on: self)
            .store(in: &cancellables)
            
        // Subscribe to location updates
        bluetoothService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)
            
        // Subscribe to device type updates
        bluetoothService.deviceTypePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.deviceType, on: self)
            .store(in: &cancellables)
            
        // Subscribe to battery level updates
        bluetoothService.deviceBatteryPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.batteryLevel, on: self)
            .store(in: &cancellables)
            
        // Subscribe to manufacturer name updates
        bluetoothService.manufacturerNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.manufacturerName, on: self)
            .store(in: &cancellables)
    }
    
    func startScan() {
        guard bluetoothState == .poweredOn else {
            print("ViewModel: Cannot scan, Bluetooth not powered on.")
            return
        }
        isScanning = true
        discoveredPeripherals = [] // Clear previous results
        bluetoothService.startScan()
    }
    
    func stopScan() {
        isScanning = false
        bluetoothService.stopScan()
    }
    
    func connect(peripheral: DiscoveredPeripheral) {
        guard bluetoothState == .poweredOn else {
            print("ViewModel: Cannot connect, Bluetooth not powered on.")
            return
        }
        // Ask the service to connect
        bluetoothService.connect(to: peripheral.peripheral)
    }
    
    func disconnect() {
        bluetoothService.disconnect(from: nil)
    }
    
    private func resetMetrics() {
        heartRate = 0
        currentPace = RunningPace.zero
        currentCadence = RunningCadence.zero
        currentLocation = nil
        deviceType = .unknown
        batteryLevel = nil
        manufacturerName = nil
    }
    
    // Format functions for UI display
    func formattedPace(useImperial: Bool = false) -> String {
        return currentPace.formattedPace(useImperial: useImperial)
    }
    
    func formattedCadence() -> String {
        return "\(currentCadence.stepsPerMinute) spm"
    }
    
    func formattedHeartRate() -> String {
        return "\(heartRate) bpm"
    }
    
    func formattedBatteryLevel() -> String {
        if let level = batteryLevel {
            return "\(level)%"
        } else {
            return "N/A"
        }
    }
    
    func deviceDisplayName() -> String {
        return manufacturerName ?? deviceType.rawValue
    }
} 