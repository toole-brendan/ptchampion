import Foundation
import Combine
import CoreLocation
import SwiftData
import SwiftUI
import CoreBluetooth

@MainActor
class RunWorkoutViewModel: ObservableObject {

    // Unit Preference
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .miles

    private let locationService: LocationServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let bluetoothService: BluetoothServiceProtocol
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

    // Internal Tracking
    private var workoutStartDate: Date?
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var totalDistanceMeters: Double = 0.0
    private var locationUpdates: [CLLocation] = []
    private var isTimerRunning: Bool = false
    private var locationSubscription: AnyCancellable?

    // Constants
    private let metersToMiles = 0.000621371
    private let metersToKilometers = 0.001

    private var useWatchGPS: Bool { // Computed property to check if watch should be preferred
        // Prefer watch if connected AND location service is available on it
        if case .connected = deviceConnectionState, isWatchLocationAvailable { return true }
        return false
    }

    init(locationService: LocationServiceProtocol = LocationService(),
         workoutService: WorkoutServiceProtocol = WorkoutService(),
         keychainService: KeychainServiceProtocol = KeychainService(),
         bluetoothService: BluetoothServiceProtocol = BluetoothService(),
         modelContext: ModelContext? = nil) {
        self.locationService = locationService
        self.workoutService = workoutService
        self.keychainService = keychainService
        self.bluetoothService = bluetoothService
        self.modelContext = modelContext
        
        print("RunWorkoutViewModel: Initializing...")
        subscribeToLocationStatus()
        subscribeToBluetoothStatus()
        checkInitialLocationPermission()
        updateDistanceDisplay()
        updatePaceDisplay(elapsedSeconds: 0)
        updateCurrentPaceDisplay(speed: 0)
    }

    private func subscribeToBluetoothStatus() {
        print("RunWorkoutViewModel: Subscribing to Bluetooth status...")
        bluetoothService.centralManagerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bluetoothState, on: self)
            .store(in: &cancellables)

        bluetoothService.connectionStatePublisher
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.currentHeartRate = heartRate
            }
            .store(in: &cancellables)

        // Subscribe to watch location service availability
        bluetoothService.locationServiceAvailablePublisher
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
           }
           .store(in: &cancellables)
    }

    private func subscribeToLocationStatus() {
        print("RunWorkoutViewModel: Subscribing to Location status...")
        locationService.authorizationStatusPublisher
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

    private func checkInitialLocationPermission() {
         let status = CLLocationManager.authorizationStatus()
         print("RunWorkoutViewModel: Initial location status: \(status)")
         handleAuthorizationStatusChange(status)
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
            displayValue = totalDistanceMeters * metersToMiles
            unitLabel = "mi"
        case .kilometers:
            displayValue = totalDistanceMeters * metersToKilometers
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
        let distanceFactor = distanceUnit == .miles ? metersToMiles : metersToKilometers

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

         let distanceFactor = distanceUnit == .miles ? metersToMiles : metersToKilometers
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
        totalDistanceMeters = 0.0
        accumulatedTime = 0
        errorMessage = nil
        updateDistanceDisplay()
        updatePaceDisplay(elapsedSeconds: 0)
        updateCurrentPaceDisplay(speed: 0)
        
        runState = .running
        startTimer()
        updateLocationSubscription() // Decide source and subscribe
    }

    func pauseRun() {
        guard runState == .running else { return }
        print("RunWorkoutViewModel: Pausing run...")
        runState = .paused
        pauseTimer()
        unsubscribeFromLocationUpdates() // Stop location updates from current source
    }

    func resumeRun() {
        guard runState == .paused else { return }
        print("RunWorkoutViewModel: Resuming run...")
        runState = .running
        startTimer()
        updateLocationSubscription() // Re-subscribe to appropriate source
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

        Task { await saveWorkoutToServerAndLocal(elapsedTime: finalElapsedTime) }
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

         let metadataDict: [String: Any] = [
             "source": connectedDeviceName ?? "Phone GPS",
             "distance_unit": distanceUnit.rawValue,
         ]
         let metadataString = try? JSONSerialization.data(withJSONObject: metadataDict)
                                     .base64EncodedString()

         let workoutData = InsertUserExerciseRequest(
             userId: Int(userId) ?? 0,
             exerciseId: runExerciseId,
             repetitions: nil,
             formScore: nil,
             timeInSeconds: Int(max(0, elapsedTime)),
             grade: nil,
             completed: true,
             metadata: metadataString,
             deviceId: UIDevice.current.identifierForVendor?.uuidString,
             syncStatus: nil
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
        
        do {
            try context.save()
            print("RunWorkoutViewModel: Workout saved locally successfully.")
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
            value = meters * metersToKilometers
            unitString = "km"
        case .miles:
            value = meters * metersToMiles
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
}

/*
// MARK: - SwiftData Model for Workout Result

// IMPORTANT: This should likely live in its own file within the Models group,
// not inside the ViewModel file.
@Model
final class WorkoutResultSwiftData {
    @Attribute(.unique) var id: UUID
    var userId: Int? // Optional: Link to the user who performed the workout
    var workoutType: String // e.g., "Run", "Push-ups", "Sit-ups"
    var date: Date
    var durationSeconds: Double
    var distanceMeters: Double? // Optional for non-distance workouts
    var averagePaceSecondsPerMeter: Double? // Optional
    var caloriesBurned: Int? // Optional, calculation needed
    var averageHeartRate: Int? // Optional
    var maxHeartRate: Int? // Optional
    var locationDataPoints: [LocationDataPoint]? // Store simplified location data

    // Relationships (Example - Adapt as needed)
    // If you have a User model:
    // var user: User?

    init(id: UUID = UUID(),
         userId: Int? = nil,
         workoutType: String,
         date: Date,
         durationSeconds: Double,
         distanceMeters: Double? = nil,
         averagePaceSecondsPerMeter: Double? = nil,
         caloriesBurned: Int? = nil,
         averageHeartRate: Int? = nil,
         maxHeartRate: Int? = nil,
         locationDataPoints: [LocationDataPoint]? = nil
         // user: User? = nil // Add user relationship if applicable
    ) {
        self.id = id
        self.userId = userId
        self.workoutType = workoutType
        self.date = date
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.averagePaceSecondsPerMeter = averagePaceSecondsPerMeter
        self.caloriesBurned = caloriesBurned
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.locationDataPoints = locationDataPoints
       // self.user = user
    }
}

// Codable struct for location data points to be stored within WorkoutResultSwiftData
struct LocationDataPoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var speed: Double? // meters per second
    var altitude: Double?
}


// Distance Unit Enum (Can also be in a separate file)
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
*/ 