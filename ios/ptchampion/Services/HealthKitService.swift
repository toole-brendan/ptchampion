import Foundation
import HealthKit
import Combine

// Protocol for HealthKit service interactions
protocol HealthKitServiceProtocol {
    var isHealthDataAvailable: Bool { get }
    var heartRatePublisher: AnyPublisher<Int, Error> { get }
    var stepsPublisher: AnyPublisher<Int, Error> { get }
    var workoutsPublisher: AnyPublisher<[HKWorkout], Error> { get }
    var authorizationStatusPublisher: AnyPublisher<Bool, Never> { get }
    var workoutSessionStatePublisher: AnyPublisher<Int, Never> { get } // Using Int instead of HKWorkoutSessionState for iOS compatibility
    
    func requestAuthorization() async throws -> Bool
    func startHeartRateQuery(withStartDate startDate: Date)
    func stopHeartRateQuery()
    func fetchLatestWorkouts(limit: Int) async throws -> [HKWorkout]
    func saveWorkout(startDate: Date, endDate: Date, workoutType: HKWorkoutActivityType, 
                     distance: Double?, energy: Double?, heartRate: [Int]?) async throws
    
    // Add workout session methods with iOS compatibility
    func startWorkoutSession(workoutType: HKWorkoutActivityType) async throws
    func pauseWorkoutSession() async throws
    func resumeWorkoutSession() async throws
    func endWorkoutSession() async throws
    func discardWorkoutSession() throws
    
    // Debug methods
    func debugAuthorizationStatus()
    func checkCurrentAuthorizationStatus()
}

// MARK: - HealthKit Service Implementation
class HealthKitService: NSObject, HealthKitServiceProtocol, ObservableObject {
    // The HealthKit store instance for interacting with health data
    private let healthStore: HKHealthStore
    
    // Publishers
    private let heartRateSubject = PassthroughSubject<Int, Error>()
    var heartRatePublisher: AnyPublisher<Int, Error> {
        heartRateSubject.eraseToAnyPublisher()
    }
    
    private let stepsSubject = PassthroughSubject<Int, Error>()
    var stepsPublisher: AnyPublisher<Int, Error> {
        stepsSubject.eraseToAnyPublisher()
    }
    
    private let workoutsSubject = PassthroughSubject<[HKWorkout], Error>()
    var workoutsPublisher: AnyPublisher<[HKWorkout], Error> {
        workoutsSubject.eraseToAnyPublisher()
    }
    
    private let authorizationStatusSubject = CurrentValueSubject<Bool, Never>(false)
    var authorizationStatusPublisher: AnyPublisher<Bool, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }
    
    // Workout session state publisher - using Int instead of HKWorkoutSessionState
    // 1 = notStarted, 2 = running, 3 = paused, 4 = ended
    private let workoutSessionStateSubject = CurrentValueSubject<Int, Never>(1) // 1 = notStarted
    var workoutSessionStatePublisher: AnyPublisher<Int, Never> {
        workoutSessionStateSubject.eraseToAnyPublisher()
    }
    
    // Active queries
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var heartRateObserver: HKObserverQuery?
    
    // Workout session properties
    private var workoutStartDate: Date?
    private var workoutEndDate: Date?
    private var workoutActivityType: HKWorkoutActivityType?
    private var workoutEvents: [Date] = [] // Store pause/resume events
    private var isWorkoutSessionActive = false
    private var isWorkoutSessionPaused = false
    
    // Check if HealthKit is available on this device
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Initialization
    
    override init() {
        // Initialize the health store
        healthStore = HKHealthStore()
        
        super.init()
        
        // Check current authorization status
        Task {
            do {
                let status = try await checkAuthorizationStatus()
                authorizationStatusSubject.send(status)
            } catch {
                print("HealthKitService: Error checking authorization status: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        guard isHealthDataAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        // Check if we've already requested (iOS won't show dialog again)
        let hasRequestedBefore = UserDefaults.standard.bool(forKey: "HasRequestedHealthKitAuth")
        
        if hasRequestedBefore {
            // If we've requested before, just check current status
            print("HealthKit: Already requested authorization before, checking current status")
            let authorized = try await checkAuthorizationStatus()
            authorizationStatusSubject.send(authorized)
            
            // If Settings show authorized but we're getting false, force it to true
            if !authorized {
                print("HealthKit: Forcing authorization check via read test")
                // Try to read recent heart rate data as a test
                let authorized = await testHealthKitAccess()
                authorizationStatusSubject.send(authorized)
                return authorized
            }
            
            return authorized
        }
        
        // First time requesting
        #if targetEnvironment(simulator)
        print("HealthKitService: Running in simulator - using mock HealthKit authorization")
        authorizationStatusSubject.send(true)
        return true
        #else
        
        // Define the data types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        // Define the data types we want to write
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        do {
            // This should present the authorization dialog
            print("HealthKit: Requesting authorization from HealthKit...")
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            
            // Mark that we've requested
            UserDefaults.standard.set(true, forKey: "HasRequestedHealthKitAuth")
            
            // Wait a moment for permissions to propagate
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if we got permission
            let authorized = try await checkAuthorizationStatus()
            
            // If still showing as not authorized but we just requested, test with actual read
            if !authorized {
                print("HealthKit: Authorization unclear, testing with actual read")
                let testResult = await testHealthKitAccess()
                authorizationStatusSubject.send(testResult)
                return testResult
            }
            
            authorizationStatusSubject.send(authorized)
            return authorized
        } catch {
            print("HealthKitService: Error requesting authorization: \(error.localizedDescription)")
            throw error
        }
        #endif
    }
    
    private func checkAuthorizationStatus() async throws -> Bool {
        guard isHealthDataAvailable else {
            return false
        }
        
        // Check multiple key types, not just heart rate
        let typesToCheck = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]
        
        // Check if we have permission for all required types
        for type in typesToCheck {
            let status = healthStore.authorizationStatus(for: type)
            print("HealthKit: Authorization status for \(type): \(status.rawValue)")
            
            // For sharing authorization, we need to check if we can save data
            // For reading, the status is less clear in iOS
            if status != .sharingAuthorized {
                // Don't immediately return false - check all types
                print("HealthKit: Type \(type) not fully authorized")
            }
        }
        
        // Special handling: iOS doesn't clearly report read permissions
        // If we've previously requested authorization, assume it's granted
        // unless explicitly denied
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        // Check if we've stored that we've requested before
        let hasRequestedBefore = UserDefaults.standard.bool(forKey: "HasRequestedHealthKitAuth")
        
        if hasRequestedBefore && status != .sharingDenied {
            // If we've asked before and it's not explicitly denied, assume authorized
            print("HealthKit: Previously requested, assuming authorized")
            return true
        }
        
        return status == .sharingAuthorized
    }
    
    // Add a test method to check if we can actually read data:
    private func testHealthKitAccess() async -> Bool {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Try to execute a query - if it works, we have permission
        return await withCheckedContinuation { continuation in
            let testQuery = HKSampleQuery(sampleType: heartRateType,
                                          predicate: nil,
                                          limit: 1,
                                          sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("HealthKit: Cannot read data - \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else {
                    print("HealthKit: Can read data - access confirmed")
                    continuation.resume(returning: true)
                }
            }
            
            healthStore.execute(testQuery)
        }
    }
    
    // MARK: - Debug Methods
    
    func debugAuthorizationStatus() {
        guard isHealthDataAvailable else {
            print("HealthKit: Health data not available on this device")
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        switch status {
        case .notDetermined:
            print("HealthKit: Authorization not determined")
        case .sharingDenied:
            print("HealthKit: Sharing denied")
        case .sharingAuthorized:
            print("HealthKit: Sharing authorized")
        @unknown default:
            print("HealthKit: Unknown status (\(status.rawValue))")
        }
        
        print("HealthKit: Raw status value: \(status.rawValue)")
        // 0 = notDetermined, 1 = sharingDenied, 2 = sharingAuthorized
    }
    
    func checkCurrentAuthorizationStatus() {
        debugAuthorizationStatus()
    }
    
    // MARK: - Heart Rate Monitoring
    
    func startHeartRateQuery(withStartDate startDate: Date) {
        guard isHealthDataAvailable else {
            heartRateSubject.send(completion: .failure(HealthKitError.healthDataNotAvailable))
            return
        }
        
        // Create heart rate type
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            heartRateSubject.send(completion: .failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        // Stop any existing query
        stopHeartRateQuery()
        
        // Create an anchored object query for heart rates
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, anchor, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.heartRateSubject.send(completion: .failure(error))
                    return
                }
                
                self.processHeartRateSamples(samples as? [HKQuantitySample])
            }
        
        // Create an observer query that will trigger when new heart rate data becomes available
        heartRateObserver = HKObserverQuery(sampleType: heartRateType, predicate: predicate) { [weak self] (query, completionHandler, error) in
            guard let self = self else {
                completionHandler()
                return
            }
            
            if let error = error {
                print("HealthKitService: Heart rate observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Execute a new anchored object query to get the latest samples
            let latestQuery = HKAnchoredObjectQuery(
                type: heartRateType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, anchor, error) in
                    if let error = error {
                        print("HealthKitService: Latest heart rate query error: \(error.localizedDescription)")
                    } else {
                        self?.processHeartRateSamples(samples as? [HKQuantitySample])
                    }
                    completionHandler()
                }
            
            self.healthStore.execute(latestQuery)
        }
        
        // Execute the queries
        healthStore.execute(heartRateQuery!)
        healthStore.execute(heartRateObserver!)
        
        // Enable background delivery if needed
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { (success, error) in
            if let error = error {
                print("HealthKitService: Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKQuantitySample]?) {
        guard let samples = samples, !samples.isEmpty else { return }
        
        for sample in samples {
            let heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            heartRateSubject.send(heartRate)
        }
    }
    
    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        if let observer = heartRateObserver {
            healthStore.stop(observer)
            heartRateObserver = nil
        }
    }
    
    // MARK: - Workouts
    
    func fetchLatestWorkouts(limit: Int) async throws -> [HKWorkout] {
        guard isHealthDataAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let workoutType = HKObjectType.workoutType()
        
        // Prepare query
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 0) // Any duration
        
        // Execute query
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let workouts = samples as? [HKWorkout] else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    // Notify observers of new workouts
                    self.workoutsSubject.send(workouts)
                    
                    continuation.resume(returning: workouts)
                }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Save Workout
    
    func saveWorkout(startDate: Date, endDate: Date, workoutType: HKWorkoutActivityType, 
                    distance: Double?, energy: Double?, heartRate: [Int]?) async throws {
        guard isHealthDataAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        // Create workout
        let workout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: energy != nil ? HKQuantity(unit: .kilocalorie(), doubleValue: energy!) : nil,
            totalDistance: distance != nil ? HKQuantity(unit: .meter(), doubleValue: distance!) : nil,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )
        
        // Save the workout
        try await healthStore.save(workout)
        
        // If we have heart rate data, save that too, associated with the workout
        if let heartRateData = heartRate, !heartRateData.isEmpty {
            try await saveHeartRateData(heartRateData, startDate: startDate, endDate: endDate, workout: workout)
        }
    }
    
    private func saveHeartRateData(_ heartRates: [Int], startDate: Date, endDate: Date, workout: HKWorkout) async throws {
        guard !heartRates.isEmpty else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let timeInterval = endDate.timeIntervalSince(startDate) / Double(heartRates.count)
        
        var samples: [HKQuantitySample] = []
        
        for (index, rate) in heartRates.enumerated() {
            let sampleDate = startDate.addingTimeInterval(timeInterval * Double(index))
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: Double(rate))
            
            let sample = HKQuantitySample(
                type: heartRateType,
                quantity: quantity,
                start: sampleDate,
                end: sampleDate,
                metadata: [HKMetadataKeyWasUserEntered: true]
            )
            
            samples.append(sample)
        }
        
        // Save heart rate samples
        try await healthStore.save(samples)
        
        // Associate samples with the workout if needed
        try await healthStore.addSamples(samples, to: workout)
    }
    
    // MARK: - Workout Session (iOS Compatible Implementation)
    
    func startWorkoutSession(workoutType: HKWorkoutActivityType) async throws {
        guard isHealthDataAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        // Ensure any existing session is ended
        try? discardWorkoutSession()
        
        // Store the session information
        workoutStartDate = Date()
        workoutActivityType = workoutType
        workoutEvents = []
        isWorkoutSessionActive = true
        isWorkoutSessionPaused = false
        
        // Update state
        workoutSessionStateSubject.send(2) // 2 = running
        
        // Start monitoring heart rate
        startHeartRateQuery(withStartDate: workoutStartDate!)
        
        print("HealthKitService: Workout session started")
    }
    
    func pauseWorkoutSession() async throws {
        guard isWorkoutSessionActive, !isWorkoutSessionPaused else {
            throw HealthKitError.noActiveWorkoutSession
        }
        
        // Record pause event
        workoutEvents.append(Date())
        isWorkoutSessionPaused = true
        
        // Update state
        workoutSessionStateSubject.send(3) // 3 = paused
        
        print("HealthKitService: Workout session paused")
    }
    
    func resumeWorkoutSession() async throws {
        guard isWorkoutSessionActive, isWorkoutSessionPaused else {
            throw HealthKitError.noActiveWorkoutSession
        }
        
        // Record resume event
        workoutEvents.append(Date())
        isWorkoutSessionPaused = false
        
        // Update state
        workoutSessionStateSubject.send(2) // 2 = running
        
        print("HealthKitService: Workout session resumed")
    }
    
    func endWorkoutSession() async throws {
        guard isWorkoutSessionActive else {
            throw HealthKitError.noActiveWorkoutSession
        }
        
        // Set end date
        workoutEndDate = Date()
        
        // Update state before saving
        isWorkoutSessionActive = false
        workoutSessionStateSubject.send(4) // 4 = ended
        
        // Save the workout to HealthKit
        if let startDate = workoutStartDate, 
           let endDate = workoutEndDate,
           let activityType = workoutActivityType {
            
            // Simply save the workout with the appropriate start/end dates
            await saveWorkoutWithEvents(
                startDate: startDate,
                endDate: endDate,
                workoutType: activityType,
                pauseResumeEvents: workoutEvents
            )
        }
        
        // Stop heart rate monitoring
        stopHeartRateQuery()
        
        // Clean up
        workoutStartDate = nil
        workoutEndDate = nil
        workoutActivityType = nil
        workoutEvents = []
        
        print("HealthKitService: Workout session ended")
    }
    
    func discardWorkoutSession() throws {
        guard isWorkoutSessionActive else {
            return
        }
        
        // Update state
        isWorkoutSessionActive = false
        isWorkoutSessionPaused = false
        workoutSessionStateSubject.send(1) // 1 = notStarted
        
        // Stop heart rate monitoring
        stopHeartRateQuery()
        
        // Clean up
        workoutStartDate = nil
        workoutEndDate = nil
        workoutActivityType = nil
        workoutEvents = []
        
        print("HealthKitService: Workout session discarded")
    }
    
    // Helper to save a workout with pause/resume events properly handled
    private func saveWorkoutWithEvents(startDate: Date, endDate: Date, workoutType: HKWorkoutActivityType, pauseResumeEvents: [Date]) async {
        // Calculate effective duration (excluding paused time)
        var effectiveDuration = endDate.timeIntervalSince(startDate)
        var isPaused = false
        var lastEventDate: Date?
        
        // Process pause/resume events to calculate actual duration
        for eventDate in pauseResumeEvents.sorted() {
            if isPaused, let lastDate = lastEventDate {
                // This is a resume event - subtract the paused time
                effectiveDuration -= eventDate.timeIntervalSince(lastDate)
            }
            
            // Toggle pause state and update last event
            isPaused.toggle()
            lastEventDate = eventDate
        }
        
        // If ended while paused, subtract the final pause duration
        if isPaused, let lastDate = lastEventDate {
            effectiveDuration -= endDate.timeIntervalSince(lastDate)
        }
        
        // Create and save the workout
        do {
            let workout = HKWorkout(
                activityType: workoutType,
                start: startDate,
                end: endDate,
                duration: max(0, effectiveDuration), // Ensure non-negative duration
                totalEnergyBurned: nil, // Will be calculated by HealthKit
                totalDistance: nil,     // Will be calculated by HealthKit
                metadata: nil
            )
            
            try await healthStore.save(workout)
            
            // Notify listeners of the new workout
            workoutsSubject.send([workout])
            
            print("HealthKitService: Workout saved to HealthKit")
        } catch {
            print("HealthKitService: Error saving workout: \(error.localizedDescription)")
        }
    }
}

// MARK: - HealthKit Errors
enum HealthKitError: Error {
    case healthDataNotAvailable
    case dataTypeNotAvailable
    case authorizationDenied
    case saveFailed
    case queryFailed
    case noActiveWorkoutSession
    
    var localizedDescription: String {
        switch self {
        case .healthDataNotAvailable:
            return "HealthKit is not available on this device"
        case .dataTypeNotAvailable:
            return "The requested health data type is not available"
        case .authorizationDenied:
            return "Authorization to access health data was denied"
        case .saveFailed:
            return "Failed to save data to HealthKit"
        case .queryFailed:
            return "Failed to query data from HealthKit"
        case .noActiveWorkoutSession:
            return "No active workout session"
        }
    }
} 