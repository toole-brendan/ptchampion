import Foundation
import Combine
import CoreLocation
import SwiftData
import SwiftUI

@MainActor
class RunWorkoutViewModel: ObservableObject {

    // Unit Preference
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .miles

    private let locationService: LocationServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private var modelContext: ModelContext?

    private var cancellables = Set<AnyCancellable>()

    // Run State
    enum RunState {
        case idle
        case requestingPermission
        case permissionDenied
        case ready // Permission granted, ready to start
        case running
        case paused
        case finished
        case error(String)
    }

    @Published var runState: RunState = .idle
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String? = nil

    // Metrics
    @Published var elapsedTimeFormatted: String = "00:00:00"
    @Published var distanceFormatted: String = "0.00 mi" // Or km based on locale
    @Published var currentPaceFormatted: String = "--:-- /mi" // Pace
    @Published var averagePaceFormatted: String = "--:-- /mi"

    // Internal Tracking
    private var workoutStartDate: Date?
    private var timerSubscription: AnyCancellable?
    private var accumulatedTime: TimeInterval = 0
    private var totalDistanceMeters: Double = 0.0
    private var locationUpdates: [CLLocation] = []
    private var isTimerRunning: Bool = false

    // Constants
    private let metersToMiles = 0.000621371
    private let metersToKilometers = 0.001

    init(locationService: LocationServiceProtocol = LocationService(),
         workoutService: WorkoutServiceProtocol = WorkoutService(),
         keychainService: KeychainServiceProtocol = KeychainService(),
         modelContext: ModelContext? = nil) {
        self.locationService = locationService
        self.workoutService = workoutService
        self.keychainService = keychainService
        self.modelContext = modelContext
        subscribeToLocationStatus()
        checkInitialLocationPermission()
        // Set initial display based on preference
        updateDistanceDisplay()
        updatePaceDisplay(elapsedSeconds: 0) // Also update pace labels initially
        updateCurrentPaceDisplay(speed: 0)
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationPermissionStatus = status
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)

        // Subscribe to location updates ONLY when running
        // We will manage this subscription manually in start/stop run methods

         locationService.errorPublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] error in
                 print("RunWorkoutViewModel: Location Service Error: \(error.localizedDescription)")
                 self?.errorMessage = "Location Error: \(error.localizedDescription)"
                 // Decide how errors affect state - maybe revert to ready or show error state
                 if self?.runState == .running || self?.runState == .paused {
                     self?.pauseRun() // Pause run if location fails
                     self?.runState = .error("Location failed during run.")
                 }
             }
             .store(in: &cancellables)
    }

    private func checkInitialLocationPermission() {
         let status = CLLocationManager.authorizationStatus()
         handleAuthorizationStatusChange(status)
    }

    private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
        guard runState != .running, runState != .paused else { return } // Don't interrupt run

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            runState = .ready
            errorMessage = nil
        case .notDetermined:
            runState = .requestingPermission
            errorMessage = "Location permission needed to track runs."
            locationService.requestLocationPermission()
        case .denied, .restricted:
            runState = .permissionDenied
            errorMessage = "Location access denied. Please enable it in Settings to track runs."
        @unknown default:
            runState = .error("Unknown location authorization status.")
            errorMessage = "An unknown error occurred with location permissions."
        }
     }

    // MARK: - Timer Logic (Similar to WorkoutViewModel)

    private func startTimer() {
        guard !isTimerRunning else { return }
        if workoutStartDate == nil {
            workoutStartDate = Date()
        }
        let resumeDate = Date()
        isTimerRunning = true

        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] firedDate in
                guard let self = self, self.isTimerRunning else { return }
                let currentTime = firedDate.timeIntervalSince(resumeDate)
                let totalElapsed = self.accumulatedTime + currentTime
                self.updateTimerDisplay(totalElapsed)
                self.updatePaceDisplay(elapsedSeconds: totalElapsed)
            }
    }

    private func pauseTimer() {
        guard isTimerRunning else { return }
        isTimerRunning = false
        // Accumulate time accurately - Calculate interval since timer started / last resumed
        // Simplified: Just stop publisher, time is calculated from start/end dates on stop
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func stopTimer() {
        isTimerRunning = false
        timerSubscription?.cancel()
        timerSubscription = nil
        accumulatedTime = 0
        workoutStartDate = nil
        updateTimerDisplay(0)
    }

    private func updateTimerDisplay(_ timeInterval: TimeInterval) {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        elapsedTimeFormatted = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Run Metrics Logic

    private func subscribeToLocationUpdates() {
        locationService.locationPublisher
             .receive(on: DispatchQueue.main)
             // Filter out inaccurate or old locations if needed
             .filter { $0 != nil && $0!.horizontalAccuracy >= 0 && $0!.horizontalAccuracy < 100 } // Example filter
             .sink { [weak self] location in
                 guard let self = self, let newLocation = location, self.runState == .running else { return }

                 if let lastLocation = self.locationUpdates.last {
                     let distanceIncrement = newLocation.distance(from: lastLocation)
                     // Filter out large jumps likely due to GPS error
                     if distanceIncrement > 0 && distanceIncrement < 500 { // Max reasonable distance in ~1 sec?
                        self.totalDistanceMeters += distanceIncrement
                        self.updateDistanceDisplay()
                        // Update current pace based on this segment
                        let timeIncrement = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
                        if timeIncrement > 0 {
                            let speedMetersPerSecond = distanceIncrement / timeIncrement
                            self.updateCurrentPaceDisplay(speed: speedMetersPerSecond)
                        }
                     }
                 }
                 self.locationUpdates.append(newLocation)
             }
             .store(in: &cancellables) // Store this specific subscription to manage it
    }

    private func unsubscribeFromLocationUpdates() {
         // Cancel only the location subscription - requires managing it separately
         // Simplification: If only one cancellable is used for location, this works.
         // Better: Store location sub in its own var `locationCancellable` and cancel that.
         // cancellables.removeAll() // Temporarily remove all, need refinement
         print("RunWorkoutViewModel: Unsubscribed from location updates (Placeholder - refine cancellation)")
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
        distanceFormatted = String(format: "%.2f ", displayValue) + unitLabel
    }

    private func updatePaceDisplay(elapsedSeconds: TimeInterval) {
        let unitLabel = distanceUnit == .miles ? "/mi" : "/km"
        guard totalDistanceMeters > 0 && elapsedSeconds > 1 else { // Need some time/distance
            averagePaceFormatted = "--:-- " + unitLabel
            return
        }

        let averageSpeedMetersPerSec = totalDistanceMeters / elapsedSeconds
        let distanceFactor = distanceUnit == .miles ? metersToMiles : metersToKilometers

        // Prevent division by zero or near-zero speed
        guard averageSpeedMetersPerSec > 0.01 else {
             averagePaceFormatted = "--:-- " + unitLabel
             return
         }

        // Time per unit distance (minutes per mile or km)
        let minutesPerUnitDistance = (1.0 / (averageSpeedMetersPerSec * distanceFactor * 60.0))

        // Check for realistic pace (e.g., less than 60 min/unit)
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
         // Speed is meters per second
         guard speed > 0.1 else { // Min speed threshold for pace calc
             currentPaceFormatted = "--:-- " + unitLabel
             return
         }

        let distanceFactor = distanceUnit == .miles ? metersToMiles : metersToKilometers

        // Time per unit distance (minutes per mile or km)
         let minutesPerUnitDistance = (1.0 / (speed * distanceFactor * 60.0))

          // Check for realistic pace
          if minutesPerUnitDistance.isFinite && minutesPerUnitDistance > 0 && minutesPerUnitDistance < 60 {
             let paceMinutes = Int(minutesPerUnitDistance)
             let paceSeconds = Int((minutesPerUnitDistance - Double(paceMinutes)) * 60)
             currentPaceFormatted = String(format: "%d:%02d ", paceMinutes, paceSeconds) + unitLabel
         } else {
             currentPaceFormatted = "--:-- " + unitLabel
         }
     }

    // MARK: - Run Control

    func startRun() {
        guard runState == .ready || runState == .paused else { return }
        resetMetrics()
        workoutStartDate = Date()
        runState = .running
        startTimer()
        subscribeToLocationUpdates() // Start listening to location
        // Request continuous updates if using that model
        // locationService.startUpdatingLocation()
        print("RunWorkoutViewModel: Run started.")
    }

    func pauseRun() {
        guard runState == .running else { return }
        runState = .paused
        pauseTimer()
        unsubscribeFromLocationUpdates() // Stop listening to location while paused
        // locationService.stopUpdatingLocation()
        print("RunWorkoutViewModel: Run paused.")
    }

    func resumeRun() {
        guard runState == .paused else { return }
        runState = .running
        startTimer() // Resumes timer display updates
        subscribeToLocationUpdates() // Start listening again
        // locationService.startUpdatingLocation()
        print("RunWorkoutViewModel: Run resumed.")
    }

    func stopRun() {
        let endTime = Date()
        let duration = workoutStartDate.map { endTime.timeIntervalSince($0) } ?? 0

        pauseTimer() // Stop timer updates first
        unsubscribeFromLocationUpdates()
        // locationService.stopUpdatingLocation()

        let finalDistance = self.totalDistanceMeters
        let finalDuration = Int(duration)

        runState = .finished
        updateTimerDisplay(duration) // Show final time
        updatePaceDisplay(elapsedSeconds: duration) // Calculate final average pace
        print("RunWorkoutViewModel: Run finished. Duration: \(finalDuration)s, Distance: \(finalDistance)m")

        // Save results
        saveRunResult(startTime: workoutStartDate ?? endTime,
                      endTime: endTime,
                      duration: finalDuration,
                      distance: finalDistance)

        // Reset internal state after saving attempt
        resetMetrics()
        stopTimer() // Fully reset timer state
    }

    private func resetMetrics() {
        accumulatedTime = 0
        totalDistanceMeters = 0.0
        locationUpdates = []
        updateDistanceDisplay() // Reset based on current unit preference
        updateTimerDisplay(0)
        // Reset pace based on current unit preference
        updatePaceDisplay(elapsedSeconds: 0)
        updateCurrentPaceDisplay(speed: 0)
    }

    // MARK: - Data Saving

    private func saveRunResult(startTime: Date, endTime: Date, duration: Int, distance: Double) {
         guard duration > 0 else {
             print("RunWorkoutViewModel: Skipping save for zero duration run.")
             return
         }

        // Ensure modelContext is available
        guard let context = modelContext else {
            print("RunWorkoutViewModel: ModelContext not available. Cannot save run locally.")
            errorMessage = "Internal error: Could not save run data."
            return
        }

        // Create the SwiftData object
        let runData = WorkoutResultSwiftData(
            exerciseType: ExerciseType.run.rawValue,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: duration,
            repCount: nil,
            score: nil,
            distanceMeters: distance
        )

        // Insert into the context
        context.insert(runData)

        // Attempt to save the context (optional, often auto-saves)
        do {
            try context.save()
            print("RunWorkoutViewModel: Run saved locally successfully!")
        } catch {
            print("RunWorkoutViewModel: Failed to save run locally: \(error.localizedDescription)")
            errorMessage = "Failed to save run data locally."
            // Consider reverting the insert or handling the error more robustly
        }

         // // --- Keep backend saving logic if needed --- (Commented out for now)
         // Task {
         //     do {
         //         guard let token = try keychainService.loadToken() else {
         //             print("RunWorkoutViewModel: Cannot save run to backend, user not authenticated.")
         //             // errorMessage = "Authentication error. Could not save run."
         //             return
         //         }
         //
         //         let resultPayload = WorkoutResultPayload(
         //             exerciseType: ExerciseType.run.rawValue,
         //             startTime: startTime,
         //             endTime: endTime,
         //             durationSeconds: duration,
         //             repCount: nil,
         //             score: nil,
         //             // Add distance if model supports it:
         //             // distanceMeters: distance
         //         )
         //
         //         print("RunWorkoutViewModel: Attempting to save run to backend...")
         //         try await workoutService.saveWorkout(result: resultPayload, authToken: token)
         //         print("RunWorkoutViewModel: Run saved to backend successfully!")
         //
         //     } catch {
         //         print("RunWorkoutViewModel: Failed to save run to backend: \(error.localizedDescription)")
         //         // errorMessage = "Failed to save run data."
         //     }
         // }
     }

    deinit {
        timerSubscription?.cancel()
        unsubscribeFromLocationUpdates()
        // locationService.stopUpdatingLocation()
        print("RunWorkoutViewModel deinitialized.")
    }
} 