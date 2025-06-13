import Foundation
import Combine
import CoreLocation
import SwiftData
import SwiftUI
import CoreBluetooth
import HealthKit
#if os(iOS)
import UIKit
#endif

@MainActor
class RunWorkoutViewModel: ObservableObject {

    // Unit Preference
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .miles

    private let locationService: LocationServiceProtocol
    private let workoutService: WorkoutService
    private let keychainService: KeychainServiceProtocol
    private let bluetoothService: BluetoothServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    var modelContext: ModelContext?

    private var cancellables = Set<AnyCancellable>()

    // Run State
    enum RunState: Equatable {
        case idle
        case requestingPermission
        case permissionDenied
        case ready // Permission granted, ready to start
        case running
        case paused
        case finished
        case error(String)
    }

    // Location Source
    enum LocationSource {
        case phone
        case watch
    }

    @Published var runState: RunState = .idle
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil

    // Metrics
    @Published var elapsedTimeFormatted: String = "00:00:00"
    @Published var distanceFormatted: String = "0.00 mi" // Or km based on locale
    @Published var currentPaceFormatted: String = "--:-- /mi" // Pace
    @Published var averagePaceFormatted: String = "--:-- /mi"

    // Bluetooth Metrics / Status
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var deviceConnectionState: PeripheralConnectionState = .disconnected()
    @Published var connectedDeviceName: String? = nil
    @Published var currentHeartRate: Int? = nil
    @Published var locationSource: LocationSource = .phone // Track active location source
    @Published var isWatchLocationAvailable: Bool = false // Track if connected watch provides GPS
    @Published var completedWorkoutForDetail: WorkoutResultSwiftData? = nil

    // HealthKit integration for Apple Watch
    @Published var isUsingAppleWatch: Bool = false
    @Published var workoutSessionState: Int = 1 // 1 = notStarted, 2 = running, 3 = paused, 4 = ended
    
    // Fallback priority (add to existing properties section)
    @AppStorage("preferAppleWatchForHeartRate") private var preferAppleWatchForHeartRate: Bool = true

    // Internal Tracking
    private var workoutStartDate: Date?
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var totalDistanceMeters: Double = 0.0
    private var locationUpdates: [CLLocation] = []
    private var isTimerRunning: Bool = false
    private var locationSubscription: AnyCancellable?
    
    // Metric Samples Collection for History
    private var heartRateSamples: [(timestamp: Date, elapsedSeconds: TimeInterval, value: Int)] = []
    private var paceSamples: [(timestamp: Date, elapsedSeconds: TimeInterval, metersPerSecond: Double)] = []
    @Published var currentCadence: Int? = nil // Make this property accessible from views
    private var cadenceSamples: [(timestamp: Date, elapsedSeconds: TimeInterval, stepsPerMinute: Int)] = []
    private var lastSampleTime: Date?

    // Constants
    private let milesPerMeter = 0.000621371
    private let kilometersPerMeter = 0.001
    private let goalDistanceMeters = 4828.03  // 3 miles in meters for USMC PFT
    
    // Sample collection settings
    private let sampleIntervalSeconds: TimeInterval = 5 // Collect detailed samples every 5 seconds

    private var useWatchGPS: Bool { // Computed property to check if watch should be preferred
        // Prefer watch if connected AND location service is available on it
        if case .connected = deviceConnectionState, isWatchLocationAvailable { return true }
        return false
    }

    init(locationService: LocationServiceProtocol = LocationService(),
         workoutService: WorkoutService = WorkoutService(),
         keychainService: KeychainServiceProtocol = KeychainService(),
         bluetoothService: BluetoothServiceProtocol = BluetoothService(),
         healthKitService: HealthKitServiceProtocol = HealthKitService(),
         modelContext: ModelContext? = nil) {
        self.locationService = locationService
        self.workoutService = workoutService
        self.keychainService = keychainService
        self.bluetoothService = bluetoothService
        self.healthKitService = healthKitService
        self.modelContext = modelContext
        
        print("RunWorkoutViewModel: Initializing...")
        subscribeToLocationStatus()
        subscribeToBluetoothStatus()
        subscribeToHealthKitStatus()
        updateDistanceDisplay()
        updatePaceDisplay(elapsedSeconds: 0)
        updateCurrentPaceDisplay(speed: 0)
    }

    private func subscribeToBluetoothStatus() {
        print("RunWorkoutViewModel: Subscribing to Bluetooth status...")
        bluetoothService.centralManagerStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.bluetoothState, on: self)
            .store(in: &cancellables)

        bluetoothService.connectionStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                 guard let self = self else { return }
                 let previousConnectionState = self.deviceConnectionState
                 self.deviceConnectionState = state
                 print("RunWorkoutViewModel: Received connection state update: \(state)")

                 switch state {
                 case .connected(let peripheral):
                     self.connectedDeviceName = peripheral.name ?? "Connected Device"
                     // If run is active, switch location source if needed
                     if self.runState == .running || self.runState == .paused {
                         self.updateLocationSubscription() // Re-evaluate source
                     }
                 case .disconnected, .failed:
                     self.connectedDeviceName = nil
                     self.currentHeartRate = nil
                     self.currentCadence = nil
                     // If run was active & using watch, switch back to phone
                     if (self.runState == .running || self.runState == .paused) && self.locationSource == .watch {
                          print("RunWorkoutViewModel: Watch disconnected during run, switching to phone GPS.")
                          self.updateLocationSubscription() // Re-evaluate source
                     }
                 default:
                     break
                 }
            }
            .store(in: &cancellables)
            
        bluetoothService.heartRatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.currentHeartRate = heartRate
                
                // If workout is running, log heart rate sample
                if self.runState == .running, let startDate = self.workoutStartDate {
                    let now = Date()
                    let elapsed = now.timeIntervalSince(startDate) + self.accumulatedTime
                    self.heartRateSamples.append((timestamp: now, elapsedSeconds: elapsed, value: heartRate))
                    
                    // Attempt to create a complete metric sample
                    self.collectMetricSample(at: now)
                }
            }
            .store(in: &cancellables)
            
        // Subscribe to cadence updates
        bluetoothService.cadencePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cadence in
                guard let self = self else { return }
                self.currentCadence = cadence.stepsPerMinute
                
                // If workout is running, log cadence sample
                if self.runState == .running, let startDate = self.workoutStartDate {
                    let now = Date()
                    let elapsed = now.timeIntervalSince(startDate) + self.accumulatedTime
                    self.cadenceSamples.append((timestamp: now, elapsedSeconds: elapsed, stepsPerMinute: cadence.stepsPerMinute))
                    
                    // Attempt to create a complete metric sample
                    self.collectMetricSample(at: now)
                }
            }
            .store(in: &cancellables)
            
        // Subscribe to pace updates
        bluetoothService.pacePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pace in
                guard let self = self else { return }
                
                // Only update if we get valid pace data and we're running
                if pace.metersPerSecond > 0 && self.runState == .running, let startDate = self.workoutStartDate {
                    let now = Date()
                    let elapsed = now.timeIntervalSince(startDate) + self.accumulatedTime
                    self.paceSamples.append((timestamp: now, elapsedSeconds: elapsed, metersPerSecond: pace.metersPerSecond))
                    self.updateCurrentPaceDisplay(speed: pace.metersPerSecond)
                    
                    // Attempt to create a complete metric sample
                    self.collectMetricSample(at: now)
                }
            }
            .store(in: &cancellables)

        // Subscribe to watch location service availability
        bluetoothService.locationServiceAvailablePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                 guard let self = self else { return }
                 print("RunWorkoutViewModel: Watch Location Service Available: \(isAvailable)")
                 let wasAvailable = self.isWatchLocationAvailable
                 self.isWatchLocationAvailable = isAvailable
                 // If availability changed during a run, re-evaluate location source
                 if isAvailable != wasAvailable && (self.runState == .running || self.runState == .paused) {
                      print("RunWorkoutViewModel: Watch location availability changed, updating subscription.")
                      self.updateLocationSubscription()
                 }
            }
            .store(in: &cancellables)

        // Subscribe to location data from the WATCH
        bluetoothService.locationPublisher
           .receive(on: DispatchQueue.main)
           .sink { [weak self] location in
               guard let self = self, self.locationSource == .watch else { return } // Only process if watch is the source
               print("RunWorkoutViewModel: Received location from WATCH")
               self.processLocationUpdate(location)
               
               // Attempt to create a complete metric sample when we get location data
               if self.runState == .running {
                   self.collectMetricSample(at: location.timestamp)
               }
           }
           .store(in: &cancellables)
    }

    private func subscribeToLocationStatus() {
        print("RunWorkoutViewModel: Subscribing to Location status...")
        locationService.authorizationStatusPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationPermissionStatus = status
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)

         locationService.errorPublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] error in
                 print("RunWorkoutViewModel: Location Service Error: \(error.localizedDescription)")
                 self?.errorMessage = "Location Error: \(error.localizedDescription)"
                 if self?.runState == .running || self?.runState == .paused {
                     self?.pauseRun()
                     self?.runState = .error("Location failed during run.")
                 }
             }
             .store(in: &cancellables)
    }

    private func subscribeToHealthKitStatus() {
        // Subscribe to HealthKit workout session state changes
        healthKitService.workoutSessionStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.workoutSessionState = state
                
                // Handle the workout session state changes
                switch state {
                case 2: // Running
                    print("RunWorkoutViewModel: HealthKit workout session is running")
                    self.isUsingAppleWatch = true
                case 3: // Paused
                    print("RunWorkoutViewModel: HealthKit workout session is paused")
                case 4: // Ended
                    print("RunWorkoutViewModel: HealthKit workout session has ended")
                    self.isUsingAppleWatch = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to HealthKit heart rate updates
        healthKitService.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("RunWorkoutViewModel: HealthKit heart rate error: \(error)")
                    }
                },
                receiveValue: { [weak self] heartRate in
                    guard let self = self else { return }
                    
                    print("DEBUG: 🏃‍♂️ RunWorkoutViewModel received HealthKit heart rate: \(heartRate) BPM")
                    
                    // Only process heart rate during active runs
                    guard self.runState == .running else { 
                        print("DEBUG: ⚠️ Not running - ignoring heart rate data")
                        return 
                    }
                    
                    // Only use Apple Watch heart rate if we prefer it or don't have a BLE device
                    if self.preferAppleWatchForHeartRate || self.currentHeartRate == nil {
                        print("DEBUG: ✅ Using HealthKit heart rate: \(heartRate) BPM")
                        self.currentHeartRate = heartRate
                        
                        // Log the heart rate sample
                        if let startDate = self.workoutStartDate {
                            let now = Date()
                            let elapsed = now.timeIntervalSince(startDate) + self.accumulatedTime
                            self.heartRateSamples.append((timestamp: now, elapsedSeconds: elapsed, value: heartRate))
                            
                            // Attempt to create a complete metric sample
                            self.collectMetricSample(at: now)
                        }
                    } else {
                        print("DEBUG: ⚠️ Ignoring HealthKit heart rate - using Bluetooth device instead")
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
        guard runState != .running, runState != .paused else {
             print("RunWorkoutViewModel: Ignoring status change during active run.")
             return
        }
        print("RunWorkoutViewModel: Handling location status change: \(status)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if runState != .error("") {
                 runState = .ready
                 errorMessage = nil
             }
        case .notDetermined:
            runState = .requestingPermission
        case .denied, .restricted:
            runState = .permissionDenied
            errorMessage = "Location access denied. Please enable it in Settings to track runs."
        @unknown default:
            runState = .error("Unknown location authorization status.")
            errorMessage = "An unknown error occurred with location permissions."
        }
     }

    private func startTimer() {
        guard !isTimerRunning else { return }
        print("RunWorkoutViewModel: Starting timer.")
        if workoutStartDate == nil {
            workoutStartDate = Date()
        }
        let resumeDate = Date()
        isTimerRunning = true

        timerSubscription = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] firedDate in
                guard let self = self, self.isTimerRunning, let startDate = self.workoutStartDate else { return }
                let currentSegmentTime = firedDate.timeIntervalSince(resumeDate)
                let totalElapsed = self.accumulatedTime + currentSegmentTime
                
                self.updateTimerDisplay(totalElapsed)
                self.updatePaceDisplay(elapsedSeconds: totalElapsed)
            }
    }

    private func pauseTimer() {
        guard isTimerRunning, let startDate = workoutStartDate else { return }
        print("RunWorkoutViewModel: Pausing timer.")
        accumulatedTime += Date().timeIntervalSince(startDate)
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func stopTimer() {
        print("RunWorkoutViewModel: Stopping timer.")
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
        accumulatedTime = 0
        workoutStartDate = nil
        updateTimerDisplay(0)
    }

    private func updateTimerDisplay(_ timeInterval: TimeInterval) {
        let totalSeconds = Int(max(0, timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        elapsedTimeFormatted = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Run Metrics Logic

    // Centralized method to handle location updates from EITHER source
    private func processLocationUpdate(_ newLocation: CLLocation) {
         print("RunWorkoutViewModel: Processing location update from source: \(locationSource)")
         guard runState == .running else { return } // Only process while running

         if let lastLocation = self.locationUpdates.last {
             let distanceIncrement = newLocation.distance(from: lastLocation)
             if distanceIncrement > 1 && distanceIncrement < 500 {
                self.totalDistanceMeters += distanceIncrement
                self.updateDistanceDisplay()
                let timeIncrement = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
                if timeIncrement > 0.1 {
                    let speedMetersPerSecond = max(0, distanceIncrement / timeIncrement)
                    self.updateCurrentPaceDisplay(speed: speedMetersPerSecond)
                }
             } else if distanceIncrement <= 1 {
                  if newLocation.speed > 0 && newLocation.speedAccuracy >= 0 && newLocation.speedAccuracy < 10 {
                      self.updateCurrentPaceDisplay(speed: newLocation.speed)
                  }
             }
         } else {
             print("RunWorkoutViewModel: Received first location update for this run segment.")
             updateCurrentPaceDisplay(speed: newLocation.speed > 0 ? newLocation.speed : 0)
         }
         self.locationUpdates.append(newLocation)
         
                     // Check if 3 miles (4828.03 meters) has been reached and stop the run if so
            // Check if 3 miles has been reached and stop the run if so
            if totalDistanceMeters >= goalDistanceMeters && runState == .running {
                print("RunWorkoutViewModel: 3 miles reached, stopping run.")
             
                             // Trigger haptic feedback on 3-mile completion
             #if os(iOS)
             let generator = UINotificationFeedbackGenerator()
             generator.notificationOccurred(.success)
             #endif
             
             stopRun()
         }
    }

    // This method now DECIDES which source to subscribe to
    private func updateLocationSubscription() {
        locationSubscription?.cancel() // Cancel previous subscription
        locationSubscription = nil
        locationService.stopUpdatingLocation() // Stop phone GPS explicitly

        // Decide source based on preference and connection state
        if useWatchGPS {
            print("RunWorkoutViewModel: Using WATCH for location updates.")
            locationSource = .watch
            locationService.stopUpdatingLocation()
        } else {
            print("RunWorkoutViewModel: Using PHONE for location updates.")
            locationSource = .phone
            locationService.startUpdatingLocation()
            locationSubscription = locationService.locationPublisher
                .receive(on: DispatchQueue.main)
                .compactMap { $0 } // Ensure non-nil location
                .filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy < 100 } // Basic accuracy filter
                .sink { [weak self] location in
                    guard let self = self, self.locationSource == .phone else { return }
                    print("RunWorkoutViewModel: Received location from PHONE")
                    self.processLocationUpdate(location)
                }
            
            // Store the subscription correctly
            if let subscription = locationSubscription {
                cancellables.insert(subscription)
            }
        }
        print("RunWorkoutViewModel: Location source set to: \(locationSource)")
    }

    private func unsubscribeFromLocationUpdates() {
        print("RunWorkoutViewModel: Unsubscribing from location updates (stopping all sources).")
        locationSubscription?.cancel()
        locationSubscription = nil
        locationService.stopUpdatingLocation()
        // No need to unsubscribe from BT publisher, just ignore based on locationSource state
     }

    private func updateDistanceDisplay() {
        let displayValue: Double
        let unitLabel: String

        switch distanceUnit {
        case .miles:
            displayValue = totalDistanceMeters * milesPerMeter
            unitLabel = "mi"
        case .kilometers:
            displayValue = totalDistanceMeters * kilometersPerMeter
            unitLabel = "km"
        }
        distanceFormatted = String(format: "%.2f ", max(0, displayValue)) + unitLabel
    }

    private func updatePaceDisplay(elapsedSeconds: TimeInterval) {
        let unitLabel = distanceUnit == .miles ? "/mi" : "/km"
        guard totalDistanceMeters > 10 && elapsedSeconds > 5 else {
            averagePaceFormatted = "--:-- " + unitLabel
            return
        }

        let averageSpeedMetersPerSec = totalDistanceMeters / elapsedSeconds
        let distanceFactor = distanceUnit == .miles ? milesPerMeter : kilometersPerMeter

        guard averageSpeedMetersPerSec > 0.1 else {
             averagePaceFormatted = "--:-- " + unitLabel
             return
         }

        let minutesPerUnitDistance = (elapsedSeconds / 60.0) / (totalDistanceMeters * distanceFactor)

        if minutesPerUnitDistance.isFinite && minutesPerUnitDistance > 0 && minutesPerUnitDistance < 60 {
            let paceMinutes = Int(minutesPerUnitDistance)
            let paceSeconds = Int((minutesPerUnitDistance - Double(paceMinutes)) * 60)
            averagePaceFormatted = String(format: "%d:%02d ", paceMinutes, paceSeconds) + unitLabel
        } else {
            averagePaceFormatted = "--:-- " + unitLabel
        }
    }

     private func updateCurrentPaceDisplay(speed: Double) {
        let unitLabel = distanceUnit == .miles ? "/mi" : "/km"
         guard speed > 0.1 else {
              currentPaceFormatted = "--:-- " + unitLabel
              return
         }

         let distanceFactor = distanceUnit == .miles ? milesPerMeter : kilometersPerMeter
         let minutesPerUnitDistance = (1.0 / 60.0) / (speed * distanceFactor)

         if minutesPerUnitDistance.isFinite && minutesPerUnitDistance > 0 && minutesPerUnitDistance < 60 {
             let paceMinutes = Int(minutesPerUnitDistance)
             let paceSeconds = Int((minutesPerUnitDistance - Double(paceMinutes)) * 60)
             currentPaceFormatted = String(format: "%d:%02d ", paceMinutes, paceSeconds) + unitLabel
         } else {
             currentPaceFormatted = "--:-- " + unitLabel
         }
     }

    // MARK: - Run Control Actions

    func startRun() {
        if locationPermissionStatus == .notDetermined {
             runState = .requestingPermission
             print("RunWorkoutViewModel: Requesting location permission...")
             locationService.requestLocationPermission()
             return
        }
        
        guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
            print("RunWorkoutViewModel: Cannot start run, permission denied.")
            runState = .permissionDenied
            errorMessage = "Location access denied. Please enable it in Settings to track runs."
            return
        }
        
        guard runState == .ready || runState == .idle || runState == .finished || runState == .error("") else {
             print("RunWorkoutViewModel: Cannot start run from state \(runState)")
             return
        }
        
        print("RunWorkoutViewModel: Starting run...")
        locationUpdates = []
        heartRateSamples = []
        paceSamples = []
        cadenceSamples = []
        lastSampleTime = nil
        totalDistanceMeters = 0.0
        accumulatedTime = 0
        errorMessage = nil
        updateDistanceDisplay()
        updatePaceDisplay(elapsedSeconds: 0)
        updateCurrentPaceDisplay(speed: 0)
        
        runState = .running
        startTimer()
        updateLocationSubscription() // Decide source and subscribe
        
        // Start HealthKit workout session if authorized
        Task {
            do {
                print("DEBUG: Starting HealthKit workout session")
                // Start workout session - this triggers Apple Watch to stream data
                let isAuthorized = try await healthKitService.requestAuthorization()
                if isAuthorized {
                    try await healthKitService.startWorkoutSession(workoutType: .running)
                    
                    // Start monitoring heart rate from Apple Watch
                    healthKitService.startHeartRateQuery(withStartDate: Date())
                    
                    print("DEBUG: HealthKit workout session started successfully")
                } else {
                    print("DEBUG: HealthKit authorization denied")
                }
            } catch {
                print("DEBUG: Failed to start HealthKit workout session: \(error)")
            }
        }
        
        print("RunWorkoutViewModel: Run started")
    }

    func pauseRun() {
        guard runState == .running else { return }
        print("RunWorkoutViewModel: Pausing run...")
        runState = .paused
        pauseTimer()
        unsubscribeFromLocationUpdates() // Stop location updates from current source
        
        // Pause HealthKit workout session if active
        Task {
            do {
                if workoutSessionState == 2 { // 2 = running
                    try await healthKitService.pauseWorkoutSession()
                }
            } catch {
                print("RunWorkoutViewModel: Failed to pause HealthKit workout session: \(error.localizedDescription)")
                // Continue with local pause even if HealthKit fails
            }
        }
    }

    func resumeRun() {
        guard runState == .paused else { return }
        print("RunWorkoutViewModel: Resuming run...")
        runState = .running
        startTimer()
        updateLocationSubscription() // Re-subscribe to appropriate source
        
        // Resume HealthKit workout session if active
        Task {
            do {
                if workoutSessionState == 3 { // 3 = paused
                    try await healthKitService.resumeWorkoutSession()
                }
            } catch {
                print("RunWorkoutViewModel: Failed to resume HealthKit workout session: \(error.localizedDescription)")
                // Continue with local resume even if HealthKit fails
            }
        }
    }

    func stopRun() {
        guard runState == .running || runState == .paused else { return }
        print("RunWorkoutViewModel: Stopping run...")
        let wasPaused = runState == .paused
        runState = .finished
        let endTime = Date()
        
        var finalElapsedTime = accumulatedTime
        if !wasPaused, let startDate = workoutStartDate {
             finalElapsedTime += endTime.timeIntervalSince(startDate)
        }
        finalElapsedTime = workoutStartDate != nil ? endTime.timeIntervalSince(workoutStartDate!) : accumulatedTime
        
        stopTimer()
        unsubscribeFromLocationUpdates() // Stop location updates

        updateTimerDisplay(finalElapsedTime)
        updatePaceDisplay(elapsedSeconds: finalElapsedTime)
        if locationUpdates.isEmpty {
            updateCurrentPaceDisplay(speed: 0)
        }
        
        // End HealthKit workout session if active
        Task {
            do {
                if workoutSessionState == 2 || workoutSessionState == 3 { // 2 = running, 3 = paused
                    try await healthKitService.endWorkoutSession()
                }
            } catch {
                print("RunWorkoutViewModel: Failed to end HealthKit workout session: \(error.localizedDescription)")
                // Continue with saving local workout even if HealthKit fails
            }
            
            // Save to server and local storage after HealthKit is finished
            await saveWorkoutToServerAndLocal(elapsedTime: finalElapsedTime)
        }
    }

    private func saveWorkoutToServerAndLocal(elapsedTime: TimeInterval) async {
         print("RunWorkoutViewModel: Preparing to save workout...")
         guard let userId = keychainService.getUserID() else {
              print("RunWorkoutViewModel: Error - User ID not found. Cannot save workout.")
              errorMessage = "Could not save run: User not logged in."
              runState = .error("Save failed: Missing User ID")
              return
         }
         let runExerciseId = 4

         // Determine the proper source attribution for the workout
         let sourceName: String
         if isUsingAppleWatch { 
             sourceName = "Apple Watch" 
         } else if let deviceName = connectedDeviceName {
             sourceName = deviceName 
         } else {
             sourceName = "Phone GPS"
         }

         let metadataDict: [String: Any] = [
             "source": sourceName,
             "distance_unit": distanceUnit.rawValue,
             "auto_stopped": totalDistanceMeters >= goalDistanceMeters  // USMC 3-mile run
         ]
         let metadataString = try? JSONSerialization.data(withJSONObject: metadataDict)
                                     .base64EncodedString()
         
         // Calculate USMC PFT 3-mile run score
         let runScore = calculateRunScore(seconds: Int(max(0, elapsedTime)))

         let workoutData = InsertUserExerciseRequest(
             exerciseId: runExerciseId,
             repetitions: nil,
             formScore: nil,
             timeInSeconds: Int(max(0, elapsedTime)),
             grade: runScore,
             completedAt: Date()
         )

         var savedServerId: Int? = nil
         do {
             print("RunWorkoutViewModel: Attempting to save workout to server...")
             let authToken = try keychainService.loadToken() ?? ""
             try await workoutService.saveWorkout(result: workoutData, authToken: authToken)
             savedServerId = nil // Since we don't have a return value, set to nil for now
             print("RunWorkoutViewModel: Saved workout successfully to server")
             errorMessage = nil
         } catch {
             print("RunWorkoutViewModel: Failed to save workout to server: \(error)")
             errorMessage = "Failed to sync run: \(error.localizedDescription)"
             runState = .error("Sync failed")
         }
         
         saveWorkoutLocally(workoutData: workoutData, serverId: savedServerId)
    }

    private func saveWorkoutLocally(workoutData: InsertUserExerciseRequest, serverId: Int?) {
        guard let context = modelContext else {
            print("RunWorkoutViewModel: ModelContext not available, cannot save locally.")
            return
        }
        
        print("RunWorkoutViewModel: Attempting to save workout locally (Server ID: \(serverId ?? -1))...")
        
        // Create the local record with the correct initializer
        let localRecord = WorkoutResultSwiftData(
            exerciseType: "run",
            startTime: Date().addingTimeInterval(-Double(workoutData.timeInSeconds ?? 0)), // Approximate start time
            endTime: Date(), // Current time as end time
            durationSeconds: Int(String(workoutData.timeInSeconds ?? 0)) ?? 0,
            repCount: workoutData.repetitions,
            score: workoutData.grade != nil ? Double(workoutData.grade!) : nil,
            distanceMeters: Double(totalDistanceMeters)
        )
        
        // Insert and save
        context.insert(localRecord)
        
        // Save detailed run metrics
        saveRunMetricSamples(for: localRecord)
        
        do {
            try context.save()
            print("RunWorkoutViewModel: Workout saved locally successfully.")
            self.completedWorkoutForDetail = localRecord
        } catch {
            print("RunWorkoutViewModel: Failed to save workout locally: \(error)")
            errorMessage = (errorMessage ?? "") + "\nFailed to save run locally."
        }
    }

    // MARK: - Formatting Helpers

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00:00"
    }

    private func formatDistance(_ meters: Double) -> String {
        let value: Double
        let unitString: String

        switch distanceUnit {
        case .kilometers:
            value = meters * kilometersPerMeter
            unitString = "km"
        case .miles:
            value = meters * milesPerMeter
            unitString = "mi"
        }
        return String(format: "%.2f \(unitString)", value)
    }

    private func formatPace(secondsPerMeter: Double) -> String {
        // Get unit string based on distanceUnit enum
        let unitStr = distanceUnit == .miles ? "mi" : "km"
        guard secondsPerMeter > 0 && secondsPerMeter.isFinite else { return "--:-- /" + unitStr }

        let secondsPerUnit: Double
        switch distanceUnit {
        case .kilometers:
            secondsPerUnit = secondsPerMeter * 1000
        case .miles:
            secondsPerUnit = secondsPerMeter * 1609.34 // Meters per mile
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return (formatter.string(from: secondsPerUnit) ?? "--:--") + " /" + unitStr
    }
    
    /// Calculate USMC PFT 3-mile run score based on elapsed seconds, age, and gender
    private func calculateRunScore(seconds: Int) -> Int {
        // Get user age and gender from profile
        // TODO: Add age and gender fields to user profile for accurate USMC PFT scoring
        // For now, using reasonable defaults - these should be configurable in user settings
        let userAge = getUserAge()
        let userGender = getUserGender()
        
        return USMCPFTScoring.scoreRun(seconds: seconds, age: userAge, gender: userGender)
    }
    
    /// Get user age from profile or reasonable default
    private func getUserAge() -> Int {
        // TODO: Implement actual age retrieval from user profile/settings
        // This could be from UserDefaults, Core Data, or a profile service
        return UserDefaults.standard.object(forKey: "userAge") as? Int ?? 25
    }
    
    /// Get user gender from profile or reasonable default
    private func getUserGender() -> String {
        // TODO: Implement actual gender retrieval from user profile/settings
        // This could be from UserDefaults, Core Data, or a profile service
        return UserDefaults.standard.string(forKey: "userGender") ?? "male"
    }

    // MARK: - Deinit
    deinit {
        print("RunWorkoutViewModel deinitialized. Cancelling \(cancellables.count) subscriptions.")
        // Ensure timer and location updates are stopped asynchronously on the main actor
        Task { @MainActor in
            stopTimer()
            unsubscribeFromLocationUpdates()
        }
        cancellables.forEach { $0.cancel() }
    }

    // Add this method to handle requesting location permission explicitly
    func requestLocationPermission() {
        print("RunWorkoutViewModel: Explicitly requesting location permission...")
        locationService.requestLocationPermission()
    }

    // Helper method to collect a comprehensive metric sample
    private func collectMetricSample(at timestamp: Date) {
        guard runState == .running, 
              let startDate = workoutStartDate else { return }
        
        // Don't collect samples too frequently
        if let lastSample = lastSampleTime, 
           timestamp.timeIntervalSince(lastSample) < sampleIntervalSeconds {
            return
        }
        
        lastSampleTime = timestamp
        
        // Calculate elapsed time
        let elapsed = timestamp.timeIntervalSince(startDate) + accumulatedTime
        
        // Get the latest location if available
        let latestLocation = locationUpdates.last
        
        // Extract current pace from formatted pace if not directly available
        var currentPaceValue: Double? = nil
        if let latestLocation = latestLocation, latestLocation.speed > 0 {
            currentPaceValue = latestLocation.speed
        } else if let lastPaceSample = paceSamples.last {
            currentPaceValue = lastPaceSample.metersPerSecond
        }
        
        // Log this comprehensive sample with timestamp alignment
        print("RunWorkoutViewModel: Collecting metric sample at \(elapsed) seconds - HR: \(currentHeartRate ?? 0), Pace: \(currentPaceValue ?? 0), Cadence: \(currentCadence ?? 0)")
    }

    // New method to save detailed metric samples
    private func saveRunMetricSamples(for workout: WorkoutResultSwiftData) {
        guard let context = modelContext else { return }
        
        print("RunWorkoutViewModel: Saving \(heartRateSamples.count) heart rate samples, \(paceSamples.count) pace samples, \(locationUpdates.count) location points")
        
        // Create consolidated samples from all our data
        // This approach creates samples that align with locations when possible
        for location in locationUpdates {
            // Find nearest heart rate and cadence samples to this location update
            let elapsed = location.timestamp.timeIntervalSince(workout.startTime)
            
            // Find the closest heart rate reading
            let nearestHR = findClosestHeartRate(to: location.timestamp)
            
            // Find the closest cadence reading
            let nearestCadence = findClosestCadence(to: location.timestamp)
            
            // Create the sample with all available data
            let sample = RunMetricSample(
                workoutID: workout.id,
                timestamp: location.timestamp,
                elapsedSeconds: elapsed,
                heartRate: nearestHR,
                paceMetersPerSecond: location.speed > 0 ? location.speed : nil,
                cadenceStepsPerMinute: nearestCadence,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy
            )
            
            context.insert(sample)
        }
        
        // Add any standalone heart rate samples that don't align with location updates
        let locationTimestamps = Set(locationUpdates.map { $0.timestamp })
        for hrSample in heartRateSamples {
            // Skip if we already have a sample at this timestamp (within 1 second)
            if locationTimestamps.contains(where: { abs($0.timeIntervalSince(hrSample.timestamp)) < 1.0 }) {
                continue
            }
            
            let sample = RunMetricSample(
                workoutID: workout.id,
                timestamp: hrSample.timestamp,
                elapsedSeconds: hrSample.elapsedSeconds,
                heartRate: hrSample.value
            )
            
            context.insert(sample)
        }
        
        print("RunWorkoutViewModel: Saved run metric samples.")
    }
    
    // Helper to find closest heart rate to a timestamp
    private func findClosestHeartRate(to timestamp: Date) -> Int? {
        guard !heartRateSamples.isEmpty else { return nil }
        
        let closestSample = heartRateSamples.min(by: { 
            abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp))
        })
        
        // Only use if within 10 seconds of the timestamp
        guard let sample = closestSample,
              abs(sample.timestamp.timeIntervalSince(timestamp)) < 10 else {
            return nil
        }
        
        return sample.value
    }
    
    // Helper to find closest cadence to a timestamp
    private func findClosestCadence(to timestamp: Date) -> Int? {
        guard !cadenceSamples.isEmpty else { return nil }
        
        let closestSample = cadenceSamples.min(by: { 
            abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp))
        })
        
        // Only use if within 10 seconds of the timestamp
        guard let sample = closestSample,
              abs(sample.timestamp.timeIntervalSince(timestamp)) < 10 else {
            return nil
        }
        
        return sample.stepsPerMinute
    }

    // Add this helper method to determine data source priority
    private func shouldUseAppleWatchFor(_ dataType: String) -> Bool {
        switch dataType {
        case "heartRate":
            return preferAppleWatchForHeartRate && isUsingAppleWatch
        case "location":
            return useWatchGPS
        default:
            return false
        }
    }
}

// Distance Unit Enum (moved from the commented-out section)
enum DistanceUnit: String, CaseIterable, Identifiable {
    case miles, kilometers
    var id: String { self.rawValue }

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
} 