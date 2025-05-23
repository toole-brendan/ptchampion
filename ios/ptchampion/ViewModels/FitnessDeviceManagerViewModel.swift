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
    @Published var dismissedBluetoothWarning: Bool = false
    
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
    
    // Enhanced scanning state
    @Published var lastScanTimestamp: Date? = nil
    @Published var scanDuration: TimeInterval = 0
    @Published var devicesFoundCount: Int = 0
    
    // Connection management
    @Published var isAutoReconnectEnabled: Bool = true
    @Published var connectionAttempts: Int = 0
    @Published var maxConnectionAttempts: Int = 3
    
    private var scanTimer: Timer?
    private var lastHeartRateUpdate: Date = .distantPast
    private let heartRateUpdateTimeout: TimeInterval = 10.0 // 10 seconds
    
    init(bluetoothService: BluetoothServiceProtocol = BluetoothService(),
         healthKitService: HealthKitServiceProtocol = HealthKitService()) {
        self.bluetoothService = bluetoothService
        self.healthKitService = healthKitService
        
        self.isHealthKitAvailable = healthKitService.isHealthDataAvailable
        
        setupPublishers()
        
        // Initialize auto-reconnect if we have a preferred device
        Task {
            await checkForAutoReconnect()
        }
    }
    
    private func setupPublishers() {
        // Bluetooth state
        bluetoothService.centralManagerStatePublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.bluetoothState = state
                
                print("FitnessDeviceManagerViewModel: Bluetooth state changed to \(state.stateDescription)")
                
                // Handle state changes with improved logic
                switch state {
                case .poweredOn:
                    // Clear any previous errors when Bluetooth becomes available
                    self.showBluetoothError = false
                    
                    // Attempt auto-reconnect if enabled and we have a preferred device
                    if self.isAutoReconnectEnabled && self.hasPreferredDevice() {
                        Task {
                            await self.attemptAutoReconnect()
                        }
                    }
                    
                case .poweredOff:
                    self.showBluetoothError = true
                    self.bluetoothErrorMessage = "Bluetooth is powered off. Please turn on Bluetooth in Settings to connect fitness devices."
                    self.stopBluetoothScan() // Stop any active scan
                    
                case .unauthorized:
                    self.showBluetoothError = true
                    self.bluetoothErrorMessage = "Bluetooth permission denied. Please allow PT Champion to use Bluetooth in Settings."
                    
                case .unsupported:
                    self.showBluetoothError = true
                    self.bluetoothErrorMessage = "Bluetooth Low Energy is not supported on this device."
                    
                case .resetting:
                    print("FitnessDeviceManagerViewModel: Bluetooth is resetting, will retry connection when ready")
                    
                default:
                    self.showBluetoothError = false
                }
            }
            .store(in: &cancellables)
        
        // Discovered devices with enhanced filtering
        bluetoothService.discoveredPeripheralsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] devices in
                guard let self else { return }
                
                // Filter and sort devices by signal strength and device type
                let filteredDevices = devices
                    .filter { device in
                        // Only show devices that are likely fitness devices
                        return device.deviceType != .unknown || 
                               (device.peripheral.name != nil && !device.peripheral.name!.isEmpty)
                    }
                    .sorted { device1, device2 in
                        // Sort by device type preference first, then by signal strength
                        let type1Priority = self.getDeviceTypePriority(device1.deviceType)
                        let type2Priority = self.getDeviceTypePriority(device2.deviceType)
                        
                        if type1Priority != type2Priority {
                            return type1Priority > type2Priority
                        }
                        
                        return device1.rssi.intValue > device2.rssi.intValue
                    }
                
                self.bluetoothDevices = filteredDevices
                self.devicesFoundCount = filteredDevices.count
                
                print("FitnessDeviceManagerViewModel: Found \(filteredDevices.count) fitness devices")
                
                // Log device types found for debugging
                let deviceTypes = Set(filteredDevices.map { $0.deviceType })
                print("FitnessDeviceManagerViewModel: Device types discovered: \(deviceTypes)")
            }
            .store(in: &cancellables)
        
        // Connection state with improved error handling
        bluetoothService.connectionStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.deviceConnectionState = state
                
                switch state {
                case .connecting:
                    print("FitnessDeviceManagerViewModel: Attempting to connect to device...")
                    self.connectionAttempts += 1
                    
                case .connected(let peripheral):
                    print("FitnessDeviceManagerViewModel: Successfully connected to \(peripheral.name ?? "Unknown Device")")
                    self.connectionAttempts = 0 // Reset connection attempts on success
                    self.showBluetoothError = false // Clear any connection errors
                    
                case .failed(let error):
                    print("FitnessDeviceManagerViewModel: Connection failed: \(error?.localizedDescription ?? "Unknown error")")
                    
                    // Show error with retry option if we haven't exceeded max attempts
                    if self.connectionAttempts < self.maxConnectionAttempts {
                        self.bluetoothErrorMessage = "Connection failed. Retrying... (Attempt \(self.connectionAttempts)/\(self.maxConnectionAttempts))"
                        
                        // Auto-retry after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.connectionAttempts < self.maxConnectionAttempts {
                                // Retry connection logic could go here
                                print("FitnessDeviceManagerViewModel: Auto-retry not implemented yet")
                            }
                        }
                    } else {
                        self.showBluetoothError = true
                        self.bluetoothErrorMessage = "Failed to connect after \(self.maxConnectionAttempts) attempts. Please try again or select a different device."
                        self.connectionAttempts = 0 // Reset for next attempt
                    }
                    
                case .disconnected(let error):
                    if let error = error {
                        print("FitnessDeviceManagerViewModel: Device disconnected with error: \(error.localizedDescription)")
                        
                        // Only show error if it was unexpected (not user-initiated)
                        if case .failed = self.deviceConnectionState {
                            // Don't show error for failed states transitioning to disconnected
                        } else {
                            self.bluetoothErrorMessage = "Device disconnected: \(error.localizedDescription)"
                            self.showBluetoothError = true
                        }
                    } else {
                        print("FitnessDeviceManagerViewModel: Device disconnected normally")
                    }
                    
                    // Reset metrics on disconnection
                    self.resetMetrics()
                    
                case .disconnecting:
                    print("FitnessDeviceManagerViewModel: Disconnecting from device...")
                }
            }
            .store(in: &cancellables)
        
        // Connected peripheral
        bluetoothService.connectedPeripheralPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.connectedBluetoothDevice, on: self)
            .store(in: &cancellables)
        
        // Heart rate from Bluetooth with timeout detection
        bluetoothService.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                if !self.preferAppleWatchForHeartRate || self.heartRate == 0 {
                    self.heartRate = heartRate
                    self.isReceivingHeartRateData = true
                    self.lastHeartRateUpdate = Date()
                    print("FitnessDeviceManagerViewModel: Received heart rate: \(heartRate) BPM")
                }
            }
            .store(in: &cancellables)
        
        // Pace from Bluetooth
        bluetoothService.pacePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] pace in
                guard let self = self else { return }
                self.currentPace = pace
                self.isReceivingPaceData = pace.metersPerSecond > 0
                if pace.metersPerSecond > 0 {
                    print("FitnessDeviceManagerViewModel: Received pace: \(pace.formattedPace())")
                }
            }
            .store(in: &cancellables)
        
        // Cadence from Bluetooth
        bluetoothService.cadencePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] cadence in
                guard let self = self else { return }
                self.currentCadence = cadence
                self.isReceivingCadenceData = cadence.stepsPerMinute > 0
                if cadence.stepsPerMinute > 0 {
                    print("FitnessDeviceManagerViewModel: Received cadence: \(cadence.stepsPerMinute) SPM")
                }
            }
            .store(in: &cancellables)
        
        // Location from Bluetooth
        bluetoothService.locationPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                self.currentLocation = location
                self.isReceivingLocationData = true
                print("FitnessDeviceManagerViewModel: Received location from device")
            }
            .store(in: &cancellables)
        
        // Device type from Bluetooth
        bluetoothService.deviceTypePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] deviceType in
                guard let self = self else { return }
                self.connectedDeviceType = deviceType
                print("FitnessDeviceManagerViewModel: Device type identified as: \(deviceType.rawValue)")
            }
            .store(in: &cancellables)
        
        // Battery level from Bluetooth
        bluetoothService.deviceBatteryPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] batteryLevel in
                guard let self = self else { return }
                self.deviceBatteryLevel = batteryLevel
                if let level = batteryLevel {
                    print("FitnessDeviceManagerViewModel: Device battery level: \(level)%")
                }
            }
            .store(in: &cancellables)
        
        // Manufacturer name from Bluetooth
        bluetoothService.manufacturerNamePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] manufacturer in
                guard let self = self else { return }
                self.deviceManufacturer = manufacturer
                if let name = manufacturer {
                    print("FitnessDeviceManagerViewModel: Device manufacturer: \(name)")
                }
            }
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
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("FitnessDeviceManagerViewModel: HealthKit heart rate error: \(error)")
                    }
                },
                receiveValue: { [weak self] heartRate in
                    guard let self = self else { return }
                    
                    print("DEBUG: ✅ Received heart rate from HealthKit: \(heartRate) BPM")
                    
                    // Always use HealthKit data when available and authorized
                    if self.isHealthKitAuthorized {
                        print("DEBUG: ✅ HealthKit authorized - updating heart rate to \(heartRate)")
                        self.heartRate = heartRate
                        self.isReceivingHeartRateData = true
                        self.lastHeartRateUpdate = Date()
                        print("DEBUG: ✅ Heart rate updated successfully from HealthKit: \(heartRate) BPM")
                    } else {
                        print("DEBUG: ⚠️ HealthKit not authorized - ignoring heart rate data")
                    }
                }
            )
            .store(in: &cancellables)
        
        // HealthKit workouts
        healthKitService.workoutsPublisher
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("FitnessDeviceManagerViewModel: HealthKit workouts error: \(error)")
                    }
                },
                receiveValue: { [weak self] workouts in
                    self?.recentWorkouts = workouts
                }
            )
            .store(in: &cancellables)
        
        // Start heart rate data timeout monitoring
        startHeartRateTimeoutMonitoring()
    }
    
    // MARK: - Enhanced Public Methods
    
    // Bluetooth methods with improved logic
    func startBluetoothScan() {
        guard bluetoothState == .poweredOn else { 
            handleBluetoothNotReady()
            return 
        }
        
        print("FitnessDeviceManagerViewModel: Starting enhanced Bluetooth scan")
        
        // Reset scan state
        bluetoothDevices = []
        devicesFoundCount = 0
        lastScanTimestamp = Date()
        isBluetoothScanning = true
        
        // Start the scan
        bluetoothService.startScan()
        
        // Start scan duration timer
        startScanTimer()
        
        // Auto-stop scan after 30 seconds to conserve battery
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self, self.isBluetoothScanning else { return }
            print("FitnessDeviceManagerViewModel: Auto-stopping scan after 30 seconds")
            self.stopBluetoothScan()
        }
    }
    
    func stopBluetoothScan() {
        guard isBluetoothScanning else { return }
        
        print("FitnessDeviceManagerViewModel: Stopping Bluetooth scan")
        isBluetoothScanning = false
        bluetoothService.stopScan()
        stopScanTimer()
        
        print("FitnessDeviceManagerViewModel: Scan completed. Found \(devicesFoundCount) devices in \(String(format: "%.1f", scanDuration)) seconds")
    }
    
    func connectToDevice(_ peripheral: DiscoveredPeripheral) {
        print("FitnessDeviceManagerViewModel: Attempting to connect to \(peripheral.name)")
        
        // Stop scanning when attempting to connect
        if isBluetoothScanning {
            stopBluetoothScan()
        }
        
        // Reset connection attempts
        connectionAttempts = 0
        
        // Clear any previous errors
        showBluetoothError = false
        
        bluetoothService.connect(to: peripheral.peripheral)
    }
    
    func disconnectFromDevice() {
        print("FitnessDeviceManagerViewModel: Disconnecting from current device")
        bluetoothService.disconnect(from: nil)
        resetMetrics()
    }
    
    // HealthKit methods
    func requestHealthKitAuthorization() async -> Bool {
        guard isHealthKitAvailable else { 
            print("FitnessDeviceManagerViewModel: HealthKit not available")
            return false 
        }
        
        print("FitnessDeviceManagerViewModel: About to request HealthKit authorization")
        
        // Check current status before requesting
        healthKitService.debugAuthorizationStatus()
        
        do {
            print("FitnessDeviceManagerViewModel: Calling healthKitService.requestAuthorization()")
            let authorized = try await healthKitService.requestAuthorization()
            print("FitnessDeviceManagerViewModel: HealthKit authorization result: \(authorized)")
            
            // Debug the final status
            healthKitService.debugAuthorizationStatus()
            
            return authorized
        } catch {
            print("FitnessDeviceManagerViewModel: HealthKit authorization error: \(error)")
            return false
        }
    }
    
    func startMonitoringHealthKitData() {
        print("FitnessDeviceManagerViewModel: Starting HealthKit data monitoring")
        healthKitService.startHeartRateQuery(withStartDate: Date())
    }
    
    func stopMonitoringHealthKitData() {
        print("FitnessDeviceManagerViewModel: Stopping HealthKit data monitoring")
        healthKitService.stopHeartRateQuery()
    }
    
    // New method for workout-specific monitoring
    func startMonitoringForWorkout() {
        guard isHealthKitAuthorized else { 
            print("FitnessDeviceManagerViewModel: Cannot start workout monitoring - HealthKit not authorized")
            return 
        }
        
        print("FitnessDeviceManagerViewModel: Starting HealthKit monitoring for workout")
        
        // Start monitoring heart rate from the current moment
        healthKitService.startHeartRateQuery(withStartDate: Date())
        
        print("DEBUG: Started monitoring HealthKit data for workout")
    }
    
    func fetchRecentWorkouts() async {
        do {
            recentWorkouts = try await healthKitService.fetchLatestWorkouts(limit: 10)
            print("FitnessDeviceManagerViewModel: Fetched \(recentWorkouts.count) recent workouts")
        } catch {
            print("FitnessDeviceManagerViewModel: Error fetching workouts: \(error.localizedDescription)")
        }
    }
    
    // Combined functionality
    func startWorkoutTracking() {
        print("FitnessDeviceManagerViewModel: Starting workout tracking")
        startMonitoringHealthKitData()
    }
    
    func stopWorkoutTracking() {
        print("FitnessDeviceManagerViewModel: Stopping workout tracking")
        stopMonitoringHealthKitData()
    }
    
    // MARK: - Enhanced Device Management
    
    func hasPreferredDevice() -> Bool {
        return bluetoothService.getPreferredDeviceUUID() != nil
    }
    
    func forgetPreferredDevice() {
        print("FitnessDeviceManagerViewModel: Forgetting preferred device")
        bluetoothService.clearPreferredDevice()
    }
    
    func reconnectToPreferredDevice() {
        guard bluetoothState == .poweredOn else {
            handleBluetoothNotReady()
            return
        }
        
        print("FitnessDeviceManagerViewModel: Attempting to reconnect to preferred device")
        bluetoothService.attemptReconnectToPreferredDevice()
    }
    
    // MARK: - Private Helper Methods
    
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
        
        print("FitnessDeviceManagerViewModel: Reset all device metrics")
    }
    
    private func handleBluetoothNotReady() {
        switch bluetoothState {
        case .poweredOff:
            showBluetoothError = true
            bluetoothErrorMessage = "Bluetooth is powered off. Please turn on Bluetooth in Settings."
        case .unauthorized:
            showBluetoothError = true
            bluetoothErrorMessage = "Bluetooth permission denied. Please enable Bluetooth access in Settings."
        case .unsupported:
            showBluetoothError = true
            bluetoothErrorMessage = "Bluetooth Low Energy is not supported on this device."
        default:
            showBluetoothError = true
            bluetoothErrorMessage = "Bluetooth is not ready. Please wait a moment and try again."
        }
    }
    
    private func getDeviceTypePriority(_ type: FitnessDeviceType) -> Int {
        // Higher numbers = higher priority
        switch type {
        case .garmin: return 6
        case .polar: return 5
        case .wahoo: return 4
        case .suunto: return 3
        case .appleWatch: return 2
        case .genericHeartRateMonitor: return 1
        case .genericFitnessTracker: return 1
        case .unknown: return 0
        }
    }
    
    private func startScanTimer() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let startTime = self.lastScanTimestamp {
                self.scanDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopScanTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    private func startHeartRateTimeoutMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if we haven't received heart rate data in a while
            if self.isReceivingHeartRateData &&
               Date().timeIntervalSince(self.lastHeartRateUpdate) > self.heartRateUpdateTimeout {
                print("FitnessDeviceManagerViewModel: Heart rate data timeout detected")
                self.isReceivingHeartRateData = false
                self.heartRate = 0
            }
        }
    }
    
    private func checkForAutoReconnect() async {
        await MainActor.run {
            if isAutoReconnectEnabled && hasPreferredDevice() && bluetoothState == .poweredOn {
                print("FitnessDeviceManagerViewModel: Auto-reconnect conditions met, attempting reconnection")
                reconnectToPreferredDevice()
            }
        }
    }
    
    private func attemptAutoReconnect() async {
        await MainActor.run {
            guard isAutoReconnectEnabled && hasPreferredDevice() else { return }
            
            // Wait a moment for Bluetooth to stabilize
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.reconnectToPreferredDevice()
            }
        }
    }
    
    // MARK: - Enhanced Display Methods
    
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
        if let manufacturer = deviceManufacturer, !manufacturer.isEmpty {
            return manufacturer
        } else {
            return connectedDeviceType.rawValue
        }
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
    
    func isGarminDevice() -> Bool {
        return connectedDeviceType == .garmin || 
               (deviceManufacturer?.lowercased().contains("garmin") ?? false)
    }
    
    func deviceSupportsLocation() -> Bool {
        if isReceivingLocationData {
            return true
        }
        return FitnessDeviceType.supportsLocation(connectedDeviceType)
    }
    
    func connectionStatusText() -> String {
        switch deviceConnectionState {
        case .disconnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        case .failed:
            return "Connection Failed"
        }
    }
    
    func connectionStatusColor() -> (red: Double, green: Double, blue: Double) {
        switch deviceConnectionState {
        case .connected:
            return (0.0, 0.8, 0.0) // Green
        case .connecting:
            return (1.0, 0.6, 0.0) // Orange
        case .failed:
            return (1.0, 0.0, 0.0) // Red
        default:
            return (0.5, 0.5, 0.5) // Gray
        }
    }
} 