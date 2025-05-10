import Foundation
import Combine
import CoreBluetooth
import CoreLocation
import HealthKit

@MainActor
class FitnessDeviceManagerViewModel: ObservableObject {
    // Services
    private let bluetoothService: BluetoothServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Published state from the Bluetooth service
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var bluetoothDevices: [DiscoveredPeripheral] = []
    @Published var connectedBluetoothDevice: CBPeripheral? = nil
    @Published var deviceConnectionState: PeripheralConnectionState = .disconnected()
    @Published var isBluetoothScanning: Bool = false
    
    // Published error state
    @Published var showBluetoothError: Bool = false
    @Published var bluetoothErrorMessage: String = ""
    
    // Published device information
    @Published var connectedDeviceType: FitnessDeviceType = .unknown
    @Published var deviceBatteryLevel: Int? = nil
    @Published var deviceManufacturer: String? = nil
    
    // Published fitness metrics (real-time data)
    @Published var heartRate: Int = 0
    @Published var currentPace: RunningPace = RunningPace.zero
    @Published var currentCadence: RunningCadence = RunningCadence.zero
    @Published var currentLocation: CLLocation? = nil
    
    // Published HealthKit state
    @Published var isHealthKitAvailable: Bool = false
    @Published var isHealthKitAuthorized: Bool = false
    @Published var recentWorkouts: [HKWorkout] = []
    
    // Flags for active data sources
    @Published var isReceivingHeartRateData: Bool = false
    @Published var isReceivingLocationData: Bool = false
    @Published var isReceivingPaceData: Bool = false
    @Published var isReceivingCadenceData: Bool = false
    
    // Data source preference
    @Published var preferAppleWatchForHeartRate: Bool = true
    
    init(bluetoothService: BluetoothServiceProtocol = BluetoothService(),
         healthKitService: HealthKitServiceProtocol = HealthKitService()) {
        self.bluetoothService = bluetoothService
        self.healthKitService = healthKitService
        
        self.isHealthKitAvailable = healthKitService.isHealthDataAvailable
        
        setupPublishers()
    }
    
    private func setupPublishers() {
        // Bluetooth state
        bluetoothService.centralManagerStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.bluetoothState = state
                
                // Show error if Bluetooth is not available
                if state == .poweredOff {
                    self?.showBluetoothError = true
                    self?.bluetoothErrorMessage = "Bluetooth is powered off. Please turn on Bluetooth in Settings."
                } else if state == .unauthorized {
                    self?.showBluetoothError = true
                    self?.bluetoothErrorMessage = "Bluetooth permission denied. Please allow PT Champion to use Bluetooth in Settings."
                } else if state == .unsupported {
                    self?.showBluetoothError = true
                    self?.bluetoothErrorMessage = "Bluetooth is not supported on this device."
                } else {
                    self?.showBluetoothError = false
                }
            }
            .store(in: &cancellables)
        
        // Discovered devices
        bluetoothService.discoveredPeripheralsPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.bluetoothDevices, on: self)
            .store(in: &cancellables)
        
        // Connection state
        bluetoothService.connectionStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.deviceConnectionState = state
                
                // Handle connection failures with error message
                if case .failed(let error) = state {
                    self?.showBluetoothError = true
                    if let btError = error as? BluetoothError {
                        self?.bluetoothErrorMessage = btError.localizedDescription
                    } else {
                        self?.bluetoothErrorMessage = error?.localizedDescription ?? "Failed to connect to device"
                    }
                }
                
                // Reset metrics on disconnection
                if case .disconnected = state {
                    self?.resetMetrics()
                }
            }
            .store(in: &cancellables)
        
        // Connected peripheral
        bluetoothService.connectedPeripheralPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.connectedBluetoothDevice, on: self)
            .store(in: &cancellables)
        
        // Heart rate from Bluetooth
        bluetoothService.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                if !self.preferAppleWatchForHeartRate || self.heartRate == 0 {
                    self.heartRate = heartRate
                    self.isReceivingHeartRateData = true
                }
            }
            .store(in: &cancellables)
        
        // Pace from Bluetooth
        bluetoothService.pacePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] pace in
                self?.currentPace = pace
                self?.isReceivingPaceData = pace.metersPerSecond > 0
            }
            .store(in: &cancellables)
        
        // Cadence from Bluetooth
        bluetoothService.cadencePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] cadence in
                self?.currentCadence = cadence
                self?.isReceivingCadenceData = cadence.stepsPerMinute > 0
            }
            .store(in: &cancellables)
        
        // Location from Bluetooth
        bluetoothService.locationPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.isReceivingLocationData = true
            }
            .store(in: &cancellables)
        
        // Device type from Bluetooth
        bluetoothService.deviceTypePublisher
            .receive(on: RunLoop.main)
            .assign(to: \.connectedDeviceType, on: self)
            .store(in: &cancellables)
        
        // Battery level from Bluetooth
        bluetoothService.deviceBatteryPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.deviceBatteryLevel, on: self)
            .store(in: &cancellables)
        
        // Manufacturer name from Bluetooth
        bluetoothService.manufacturerNamePublisher
            .receive(on: RunLoop.main)
            .assign(to: \.deviceManufacturer, on: self)
            .store(in: &cancellables)
        
        // HealthKit authorization status
        healthKitService.authorizationStatusPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isHealthKitAuthorized, on: self)
            .store(in: &cancellables)
        
        // HealthKit heart rate (uses error handling publisher)
        healthKitService.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in }, // Handle error if needed
                receiveValue: { [weak self] heartRate in
                    guard let self = self, self.preferAppleWatchForHeartRate else { return }
                    self.heartRate = heartRate
                    self.isReceivingHeartRateData = true
                }
            )
            .store(in: &cancellables)
        
        // HealthKit workouts
        healthKitService.workoutsPublisher
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in }, // Handle error if needed
                receiveValue: { [weak self] workouts in
                    self?.recentWorkouts = workouts
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    // Bluetooth methods
    func startBluetoothScan() {
        guard bluetoothState == .poweredOn else { 
            if bluetoothState == .poweredOff {
                showBluetoothError = true
                bluetoothErrorMessage = "Bluetooth is powered off. Please turn on Bluetooth in Settings."
            }
            return 
        }
        isBluetoothScanning = true
        bluetoothService.startScan()
    }
    
    func stopBluetoothScan() {
        isBluetoothScanning = false
        bluetoothService.stopScan()
    }
    
    func connectToDevice(_ peripheral: DiscoveredPeripheral) {
        bluetoothService.connect(to: peripheral.peripheral)
    }
    
    func disconnectFromDevice() {
        bluetoothService.disconnect(from: nil)
    }
    
    // HealthKit methods
    func requestHealthKitAuthorization() async -> Bool {
        do {
            return try await healthKitService.requestAuthorization()
        } catch {
            print("FitnessDeviceManagerViewModel: Error requesting HealthKit authorization: \(error.localizedDescription)")
            
            #if targetEnvironment(simulator)
            // In simulator, handle gracefully and fake success
            print("FitnessDeviceManagerViewModel: Running in simulator - simulating successful authorization")
            return true
            #else
            // In real device, show proper error
            showBluetoothError = true
            bluetoothErrorMessage = "Could not access HealthKit: \(error.localizedDescription)"
            return false
            #endif
        }
    }
    
    func startMonitoringHealthKitData() {
        // Start monitoring heart rate from now
        healthKitService.startHeartRateQuery(withStartDate: Date())
    }
    
    func stopMonitoringHealthKitData() {
        healthKitService.stopHeartRateQuery()
    }
    
    func fetchRecentWorkouts() async {
        do {
            recentWorkouts = try await healthKitService.fetchLatestWorkouts(limit: 10)
        } catch {
            print("Error fetching workouts: \(error.localizedDescription)")
        }
    }
    
    // Combined functionality
    func startWorkoutTracking() {
        // Start monitoring both Bluetooth and HealthKit data sources
        startMonitoringHealthKitData()
        
        // If we have a GPS device connected, we don't need to use the phone's location
        // This could be handled by a separate location service
    }
    
    func stopWorkoutTracking() {
        stopMonitoringHealthKitData()
    }
    
    // Helpers
    private func resetMetrics() {
        heartRate = 0
        currentPace = RunningPace.zero
        currentCadence = RunningCadence.zero
        currentLocation = nil
        deviceBatteryLevel = nil
        deviceManufacturer = nil
        connectedDeviceType = .unknown
        
        isReceivingHeartRateData = false
        isReceivingLocationData = false
        isReceivingPaceData = false
        isReceivingCadenceData = false
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
        if let level = deviceBatteryLevel {
            return "\(level)%"
        } else {
            return "N/A"
        }
    }
    
    func deviceDisplayName() -> String {
        return deviceManufacturer ?? connectedDeviceType.rawValue
    }
    
    func primaryDataSource() -> String {
        if connectedBluetoothDevice != nil && isReceivingHeartRateData {
            return deviceDisplayName()
        } else if isHealthKitAuthorized && isReceivingHeartRateData {
            return "Apple Watch"
        } else {
            return "None"
        }
    }
    
    // New method to get the preferred device
    func hasPreferredDevice() -> Bool {
        return bluetoothService.getPreferredDeviceUUID() != nil
    }
    
    // New method to forget the preferred device
    func forgetPreferredDevice() {
        bluetoothService.clearPreferredDevice()
    }
    
    // Method to attempt reconnection to the preferred device
    func reconnectToPreferredDevice() {
        guard bluetoothState == .poweredOn else {
            if bluetoothState == .poweredOff {
                showBluetoothError = true
                bluetoothErrorMessage = "Bluetooth is powered off. Please turn on Bluetooth in Settings."
            }
            return
        }
        
        bluetoothService.attemptReconnectToPreferredDevice()
    }
} 