import Foundation
import Combine
import BackgroundTasks
import SwiftData
import UIKit

/// Service responsible for synchronizing local workout data with the server
class SynchronizationService: ObservableObject {
    // MARK: - Constants
    
    /// Background task identifier for workout sync
    static let backgroundTaskIdentifier = "com.ptchampion.syncWorkouts"
    
    /// Minimum time interval between background sync attempts (15 minutes)
    private let minBackgroundSyncInterval: TimeInterval = 15 * 60
    
    // MARK: - Dependencies
    
    private let workoutService: WorkoutServiceProtocol
    private let persistenceService: WorkoutPersistenceService
    private let networkMonitor: NetworkMonitorService
    
    // MARK: - State
    
    /// Currently syncing flag to prevent multiple simultaneous syncs
    private var isSyncing = false
    
    /// Count of pending sync workouts
    @Published private(set) var pendingSyncCount: Int = 0
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        workoutService: WorkoutServiceProtocol,
        persistenceService: WorkoutPersistenceService,
        networkMonitor: NetworkMonitorService
    ) {
        self.workoutService = workoutService
        self.persistenceService = persistenceService
        self.networkMonitor = networkMonitor
        
        setupNotificationObservers()
        updatePendingCount()
    }
    
    // MARK: - Setup
    
    /// Set up notification observers for connectivity changes and app lifecycle
    private func setupNotificationObservers() {
        // Observe when network connectivity is restored
        NotificationCenter.default
            .publisher(for: .connectivityRestored)
            .sink { [weak self] _ in
                self?.handleConnectivityRestored()
            }
            .store(in: &cancellables)
        
        // Observe when app enters foreground
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
        
        // Observe when app enters background
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.scheduleBackgroundSync()
            }
            .store(in: &cancellables)
            
        // Observe manual sync requests
        NotificationCenter.default
            .publisher(for: .manualSyncRequested)
            .sink { [weak self] _ in
                self?.handleManualSyncRequest()
            }
            .store(in: &cancellables)
    }
    
    /// Register background tasks with the system
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            // This closure is called when the system launches our app in the background
            self?.handleBackgroundSync(task: task as! BGAppRefreshTask)
        }
        
        print("Registered background task: \(Self.backgroundTaskIdentifier)")
    }
    
    // MARK: - Event Handlers
    
    /// Handle network connectivity being restored
    private func handleConnectivityRestored() {
        print("Connectivity restored, starting sync...")
        Task {
            await syncPendingWorkouts()
        }
    }
    
    /// Handle app coming to foreground
    private func handleAppForeground() {
        // Check if we have pending workouts and network is available
        updatePendingCount()
        
        if networkMonitor.isConnected && pendingSyncCount > 0 {
            print("App in foreground with connectivity, checking for pending workouts...")
            Task {
                await syncPendingWorkouts()
            }
        }
    }
    
    /// Handle manual sync request from UI
    private func handleManualSyncRequest() {
        // Only proceed if we have network and pending items
        guard networkMonitor.isConnected && pendingSyncCount > 0 else {
            return
        }
        
        Task {
            await syncPendingWorkouts()
        }
    }
    
    /// Handle background sync task execution
    private func handleBackgroundSync(task: BGAppRefreshTask) {
        print("Background sync task started")
        
        // Notify about sync starting (for UI updates)
        notifySyncStarted()
        
        // Create an expiration handler that will be called if we run out of time
        task.expirationHandler = { [weak self] in
            print("Background sync task expiring")
            // If we're syncing, we need to cancel it
            self?.isSyncing = false
            
            // Notify about sync completion (for UI updates)
            self?.notifySyncCompleted()
        }
        
        // Start a task to do the actual sync
        Task {
            let syncResult = await syncPendingWorkouts()
            
            // Schedule the next background task before completing
            self.scheduleBackgroundSync()
            
            // Mark the task complete
            task.setTaskCompleted(success: syncResult)
        }
    }
    
    // MARK: - Sync Logic
    
    /// Synchronize pending workouts with the server
    /// - Returns: True if sync was successful or there was nothing to sync
    @discardableResult
    func syncPendingWorkouts() async -> Bool {
        // Check if already syncing
        guard !isSyncing else {
            print("Sync already in progress, skipping")
            return false
        }
        
        // Check for connectivity
        guard networkMonitor.isConnected else {
            print("No network connectivity, skipping sync")
            return false
        }
        
        // Notify about sync starting (for UI updates)
        notifySyncStarted()
        
        // Set syncing flag
        isSyncing = true
        
        do {
            // Get all pending workouts
            let pendingWorkouts = persistenceService.retrievePendingSyncWorkouts()
            
            if pendingWorkouts.isEmpty {
                print("No pending workouts to sync")
                isSyncing = false
                
                // Notify about sync completion (for UI updates)
                notifySyncCompleted()
                
                return true
            }
            
            print("Starting sync of \(pendingWorkouts.count) pending workouts")
            
            // Process each workout based on its sync status
            for workout in pendingWorkouts {
                switch workout.syncStatusEnum {
                case .pendingUpload:
                    try await handlePendingUpload(workout)
                    
                case .pendingUpdate:
                    try await handlePendingUpdate(workout)
                    
                case .pendingDeletion:
                    try await handlePendingDeletion(workout)
                    
                case .conflicted:
                    try await handleConflicted(workout)
                    
                default:
                    print("Workout \(workout.id) has unexpected sync status: \(workout.syncStatus)")
                }
                
                // Update pending count after each operation
                updatePendingCount()
                
                // Small delay between requests to avoid overwhelming the server
                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
            }
            
            print("Sync completed successfully")
            isSyncing = false
            
            // Notify about sync completion (for UI updates)
            notifySyncCompleted()
            
            return true
            
        } catch {
            print("Error during sync: \(error.localizedDescription)")
            isSyncing = false
            
            // Notify about sync completion with error (for UI updates)
            notifySyncCompleted(error: error)
            
            return false
        }
    }
    
    /// Handle workout pending upload
    private func handlePendingUpload(_ workout: WorkoutResultSwiftData) async throws {
        print("Uploading workout \(workout.id)")
        
        // Convert to API model
        let workoutData = convertToAPIModel(workout)
        
        do {
            // Add idempotency key to avoid duplicates (using workout's UUID)
            let idempotencyKey = workout.id.uuidString
            
            // Upload to server with idempotency key
            let response = try await workoutService.logExercise(
                workoutData,
                isPublic: workout.isPublic,
                idempotencyKey: idempotencyKey
            )
            
            // Update local workout with server ID and sync status
            if let serverId = response.id {
                _ = persistenceService.updateWorkoutSyncStatus(
                    workoutId: workout.id,
                    status: .synced,
                    serverId: serverId
                )
                print("Workout \(workout.id) uploaded successfully with server ID: \(serverId)")
            } else {
                print("Warning: Server did not return an ID for uploaded workout")
                _ = persistenceService.updateWorkoutSyncStatus(
                    workoutId: workout.id,
                    status: .synced
                )
            }
        } catch let error as APIError {
            // Check for conflict (409) - workout might already exist on server
            if case .requestFailed(let statusCode, _) = error, statusCode == 409 {
                print("Conflict detected: Workout may already exist on server. Marking as synced.")
                _ = persistenceService.updateWorkoutSyncStatus(
                    workoutId: workout.id,
                    status: .synced
                )
            } else {
                print("Failed to upload workout \(workout.id): \(error.localizedDescription)")
                
                // Update last sync attempt but keep pending status
                _ = persistenceService.updateWorkoutSyncStatus(
                    workoutId: workout.id,
                    status: .pendingUpload
                )
                
                // Re-throw the error to stop sync if it's a connectivity issue
                throw error
            }
        } catch {
            print("Failed to upload workout \(workout.id): \(error.localizedDescription)")
            
            // Update last sync attempt but keep pending status
            _ = persistenceService.updateWorkoutSyncStatus(
                workoutId: workout.id,
                status: .pendingUpload
            )
            
            // Re-throw the error to stop sync if it's a connectivity issue
            throw error
        }
    }
    
    /// Handle workout pending update
    private func handlePendingUpdate(_ workout: WorkoutResultSwiftData) async throws {
        print("Updating workout \(workout.id) on server")
        
        // Ensure we have a server ID
        guard let serverId = workout.serverId else {
            print("Cannot update workout without server ID, marking for upload instead")
            _ = persistenceService.updateWorkoutSyncStatus(
                workoutId: workout.id,
                status: .pendingUpload
            )
            return
        }
        
        // Try to fetch current server version for timestamp comparison
        do {
            let serverWorkout = try await workoutService.getWorkoutById(serverId: serverId)
            
            // Check if server version is newer than local version
            if let serverModifiedDate = serverWorkout.updatedAt,
               let localModifiedDate = workout.serverModifiedDate,
               serverModifiedDate > localModifiedDate {
                
                // Server version is newer - handle conflict
                print("Conflict detected: Server workout version is newer")
                
                // For this implementation, we'll use "local wins" strategy
                // But you might want different conflict resolution in a real app
                workout.syncStatusEnum = .conflicted
                
                // Store the server modified date
                workout.serverModifiedDate = serverModifiedDate
                
                return
            }
        } catch {
            // If we can't fetch the server version, continue with update
            // assuming local version is authoritative
            print("Could not fetch server workout for conflict check: \(error.localizedDescription)")
        }
        
        // Convert to API model
        let workoutData = convertToAPIModel(workout)
        
        do {
            // Update on server
            let response = try await workoutService.updateExercise(
                id: serverId,
                data: workoutData,
                isPublic: workout.isPublic
            )
            
            // Update sync status
            _ = persistenceService.updateWorkoutSyncStatus(
                workoutId: workout.id,
                status: .synced
            )
            
            print("Workout \(workout.id) updated successfully")
        } catch {
            print("Failed to update workout \(workout.id): \(error.localizedDescription)")
            
            // Update last sync attempt but keep pending status
            _ = persistenceService.updateWorkoutSyncStatus(
                workoutId: workout.id,
                status: .pendingUpdate
            )
            
            // Re-throw the error to stop sync if it's a connectivity issue
            throw error
        }
    }
    
    /// Handle workout pending deletion
    private func handlePendingDeletion(_ workout: WorkoutResultSwiftData) async throws {
        print("Deleting workout \(workout.id) from server")
        
        // Ensure we have a server ID
        guard let serverId = workout.serverId else {
            print("Cannot delete workout without server ID, removing local entry")
            try persistenceService.deleteWorkout(id: workout.id.uuidString)
            return
        }
        
        do {
            // Delete from server
            try await workoutService.deleteExercise(id: serverId)
            
            // Delete from local storage
            try persistenceService.deleteWorkout(id: workout.id.uuidString)
            
            print("Workout \(workout.id) deleted successfully")
        } catch let error as APIError {
            // Check for not found (404) - workout might already be deleted on server
            if case .requestFailed(let statusCode, _) = error, statusCode == 404 {
                print("Workout not found on server, already deleted. Removing local entry.")
                try persistenceService.deleteWorkout(id: workout.id.uuidString)
            } else {
                print("Failed to delete workout \(workout.id): \(error.localizedDescription)")
                
                // Update last sync attempt but keep pending status
                _ = persistenceService.updateWorkoutSyncStatus(
                    workoutId: workout.id,
                    status: .pendingDeletion
                )
                
                // Re-throw the error to stop sync if it's a connectivity issue
                throw error
            }
        } catch {
            print("Failed to delete workout \(workout.id): \(error.localizedDescription)")
            
            // Update last sync attempt but keep pending status
            _ = persistenceService.updateWorkoutSyncStatus(
                workoutId: workout.id,
                status: .pendingDeletion
            )
            
            // Re-throw the error to stop sync if it's a connectivity issue
            throw error
        }
    }
    
    /// Handle workout with conflicts
    private func handleConflicted(_ workout: WorkoutResultSwiftData) async throws {
        print("Resolving conflict for workout \(workout.id)")
        
        // In this implementation, we'll use "local wins" conflict resolution
        // In a real app, you might want more sophisticated conflict resolution
        // like showing a UI for the user to choose which version to keep

        if let serverId = workout.serverId {
            // If we have a server ID, treat as an update
            try await handlePendingUpdate(workout)
        } else {
            // Otherwise treat as a new upload
            try await handlePendingUpload(workout)
        }
    }
    
    // MARK: - Background Task Scheduling
    
    /// Schedule background sync task
    func scheduleBackgroundSync() {
        // Create a background task request
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        
        // Set earliest begin date to minimum interval from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: minBackgroundSyncInterval)
        
        // Only request background task if we have pending items
        if pendingSyncCount > 0 {
            do {
                try BGTaskScheduler.shared.submit(request)
                print("Background sync scheduled successfully")
            } catch {
                print("Failed to schedule background sync: \(error.localizedDescription)")
            }
        } else {
            print("No pending items, skipping background sync scheduling")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert WorkoutResultSwiftData to API model for syncing
    private func convertToAPIModel(_ workout: WorkoutResultSwiftData) -> LogExerciseRequest {
        // Construct API model from local data
        return LogExerciseRequest(
            exerciseType: workout.exerciseType,
            timestamp: workout.startTime,
            duration: Double(workout.durationSeconds),
            repCount: workout.repCount,
            score: workout.score,
            formQuality: workout.formQuality,
            distanceMeters: workout.distanceMeters,
            isPublic: workout.isPublic,
            idempotencyKey: workout.id.uuidString  // Use UUID as idempotency key to prevent duplicates
        )
    }
    
    /// Get the count of pending sync workouts
    private func updatePendingCount() {
        let pendingWorkouts = persistenceService.retrievePendingSyncWorkouts()
        pendingSyncCount = pendingWorkouts.count
        
        // Share this count with the UI via UserDefaults for cross-object access
        UserDefaults.standard.set(pendingSyncCount, forKey: "pendingSyncCount")
    }
    
    // MARK: - Notification Helpers
    
    /// Notify about sync starting (for UI updates)
    private func notifySyncStarted() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .syncStarted, object: nil)
        }
    }
    
    /// Notify about sync completion (for UI updates)
    private func notifySyncCompleted(error: Error? = nil) {
        DispatchQueue.main.async {
            if let error = error {
                // Post with error
                NotificationCenter.default.post(
                    name: .syncCompleted,
                    object: nil,
                    userInfo: ["error": error]
                )
            } else {
                // Post without error
                NotificationCenter.default.post(name: .syncCompleted, object: nil)
            }
            
            // Update pending count after sync
            self.updatePendingCount()
        }
    }
}

// MARK: - API Models

/// Request model for logging an exercise to the API
struct LogExerciseRequest: Codable {
    let exerciseType: String
    let timestamp: Date
    let duration: Double
    let repCount: Int?
    let score: Double?
    let formQuality: Double?
    let distanceMeters: Double?
    let isPublic: Bool
    let idempotencyKey: String?
    
    init(
        exerciseType: String,
        timestamp: Date,
        duration: Double,
        repCount: Int? = nil,
        score: Double? = nil,
        formQuality: Double? = nil,
        distanceMeters: Double? = nil,
        isPublic: Bool = false,
        idempotencyKey: String? = nil
    ) {
        self.exerciseType = exerciseType
        self.timestamp = timestamp
        self.duration = duration
        self.repCount = repCount
        self.score = score
        self.formQuality = formQuality
        self.distanceMeters = distanceMeters
        self.isPublic = isPublic
        self.idempotencyKey = idempotencyKey
    }
}

/// Response model from logging an exercise
struct LogExerciseResponse: Codable {
    let id: Int?
    let success: Bool
    let message: String?
}

/// Server workout model for conflict detection
struct ServerWorkoutModel: Codable {
    let id: Int
    let exerciseType: String
    let createdAt: Date
    let updatedAt: Date?
}

// MARK: - WorkoutService Extension for Exercise Operations

extension WorkoutServiceProtocol {
    /// Log an exercise to the server
    func logExercise(_ exercise: LogExerciseRequest, isPublic: Bool, idempotencyKey: String? = nil) async throws -> LogExerciseResponse {
        // This is a placeholder implementation - would be properly implemented in WorkoutService
        fatalError("This method should be implemented by the concrete WorkoutService class")
    }
    
    /// Update an existing exercise on the server
    func updateExercise(id: Int, data: LogExerciseRequest, isPublic: Bool) async throws -> LogExerciseResponse {
        // This is a placeholder implementation - would be properly implemented in WorkoutService
        fatalError("This method should be implemented by the concrete WorkoutService class")
    }
    
    /// Delete an exercise from the server
    func deleteExercise(id: Int) async throws {
        // This is a placeholder implementation - would be properly implemented in WorkoutService
        fatalError("This method should be implemented by the concrete WorkoutService class")
    }
    
    /// Get workout by server ID for conflict checking
    func getWorkoutById(serverId: Int) async throws -> ServerWorkoutModel {
        // This is a placeholder implementation - would be properly implemented in WorkoutService
        fatalError("This method should be implemented by the concrete WorkoutService class")
    }
} 