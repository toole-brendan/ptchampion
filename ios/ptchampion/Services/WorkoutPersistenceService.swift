import Foundation
import SwiftData

/// Service to handle local persistence of workouts to SwiftData
class WorkoutPersistenceService {
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext?
    
    /// Initialize with a shared container or create a new one with a complete schema
    @MainActor
    init(container: ModelContainer? = nil) {
        if let container = container {
            self.modelContainer = container
            self.modelContext = container.mainContext
            print("WorkoutPersistenceService: Using provided ModelContainer")
        } else {
            // Set up SwiftData container and context
            do {
                let schema = Schema([
                    WorkoutResultSwiftData.self,
                    WorkoutDataPoint.self,
                    RunMetricSample.self
                ])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
                self.modelContext = ModelContext(modelContainer!)
                print("WorkoutPersistenceService: Created new ModelContainer with complete schema")
            } catch {
                print("Failed to create SwiftData container: \(error)")
                self.modelContainer = nil
                self.modelContext = nil
            }
        }
    }
    
    /// Save workouts to local storage
    /// - Parameter workouts: Array of workout history to save
    func saveWorkouts(_ workouts: [WorkoutHistory]) {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return
        }
        
        do {
            // Convert to SwiftData models and save
            let workoutModels = workouts.map { workout in
                let model = WorkoutResultSwiftData(
                    id: workout.id,
                    exerciseType: workout.exerciseType,
                    startTime: workout.date,
                    endTime: workout.date.addingTimeInterval(workout.duration),
                    durationSeconds: Int(workout.duration),
                    repCount: workout.reps,
                    distanceMeters: workout.distance,
                    isPublic: false, // Default to private
                    syncStatus: .pendingUpload // Mark as needing to be uploaded to server
                )
                return model
            }
            
            // First, delete existing data to avoid duplicates
            // In a real app, you might want a more sophisticated merge strategy
            try deleteAllWorkouts()
            
            // Save the new workout models
            for model in workoutModels {
                context.insert(model)
            }
            
            try context.save()
            print("Saved \(workoutModels.count) workouts to SwiftData")
        } catch {
            print("Failed to save workouts to SwiftData: \(error)")
        }
    }
    
    /// Save a single workout to local storage
    /// - Parameter workout: The workout to save
    /// - Parameter isPublic: Whether the workout should be publicly shared
    /// - Returns: The saved WorkoutResultSwiftData object or nil if save failed
    func saveWorkout(_ workout: WorkoutHistory, isPublic: Bool = false) -> WorkoutResultSwiftData? {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return nil
        }
        
        do {
            let model = WorkoutResultSwiftData(
                id: workout.id,
                exerciseType: workout.exerciseType,
                startTime: workout.date,
                endTime: workout.date.addingTimeInterval(workout.duration),
                durationSeconds: Int(workout.duration),
                repCount: workout.reps,
                distanceMeters: workout.distance,
                isPublic: isPublic,
                syncStatus: .pendingUpload // Mark as needing to be uploaded to server
            )
            
            context.insert(model)
            try context.save()
            print("Saved workout to SwiftData: \(workout.id ?? "new")")
            return model
        } catch {
            print("Failed to save workout to SwiftData: \(error)")
            return nil
        }
    }
    
    /// Retrieve workouts from local storage
    /// - Returns: Array of workout history from local storage
    func retrieveWorkouts() -> [WorkoutHistory] {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return []
        }
        
        do {
            // Define descriptor to sort by date (newest first)
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            let workoutModels = try context.fetch(descriptor)
            
            // Convert SwiftData models back to domain models
            let workouts = workoutModels.map { model in
                WorkoutHistory(
                    id: model.id.uuidString,
                    exerciseType: model.exerciseType,
                    reps: model.repCount,
                    distance: model.distanceMeters,
                    duration: TimeInterval(model.durationSeconds),
                    date: model.startTime
                )
            }
            
            print("Retrieved \(workouts.count) workouts from SwiftData")
            return workouts
        } catch {
            print("Failed to retrieve workouts from SwiftData: \(error)")
            return []
        }
    }
    
    /// Retrieve workouts that need to be synced with the server
    /// - Returns: Array of pending sync workouts
    func retrievePendingSyncWorkouts() -> [WorkoutResultSwiftData] {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return []
        }
        
        do {
            // Create a predicate to find workouts that need syncing
            let pendingStatuses = [SyncStatus.pendingUpload.rawValue, 
                                  SyncStatus.pendingUpdate.rawValue,
                                  SyncStatus.pendingDeletion.rawValue]
            let predicate = #Predicate<WorkoutResultSwiftData> { workout in
                pendingStatuses.contains(workout.syncStatus)
            }
            
            // Define descriptor with predicate and sort by date
            var descriptor = FetchDescriptor<WorkoutResultSwiftData>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\.startTime)]
            
            let pendingWorkouts = try context.fetch(descriptor)
            print("Retrieved \(pendingWorkouts.count) pending sync workouts")
            
            return pendingWorkouts
        } catch {
            print("Failed to retrieve pending sync workouts: \(error)")
            return []
        }
    }
    
    /// Update workout sync status
    /// - Parameters:
    ///   - workoutId: ID of the workout to update
    ///   - status: New sync status
    ///   - serverId: Optional server ID to store
    /// - Returns: Updated workout or nil if not found/updated
    func updateWorkoutSyncStatus(workoutId: UUID, status: SyncStatus, serverId: Int? = nil) -> WorkoutResultSwiftData? {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return nil
        }
        
        do {
            // Find workout with matching ID
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>(
                predicate: #Predicate { $0.id == workoutId }
            )
            
            let results = try context.fetch(descriptor)
            
            guard let workout = results.first else {
                print("Workout with ID \(workoutId) not found")
                return nil
            }
            
            // Update sync status
            workout.syncStatusEnum = status
            workout.lastSyncAttempt = Date()
            
            // Update server ID if provided
            if let serverId = serverId {
                workout.serverId = serverId
            }
            
            try context.save()
            print("Updated sync status for workout \(workoutId) to \(status)")
            return workout
        } catch {
            print("Failed to update workout sync status: \(error)")
            return nil
        }
    }
    
    /// Delete all stored workouts
    /// - Throws: Error if deletion fails
    func deleteAllWorkouts() throws {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return
        }
        
        let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
        let workouts = try context.fetch(descriptor)
        
        for workout in workouts {
            context.delete(workout)
        }
        
        try context.save()
        print("Deleted all workouts from SwiftData")
    }
    
    /// Delete specific workout by id
    /// - Parameter id: ID of workout to delete
    /// - Throws: Error if deletion fails
    func deleteWorkout(id: String) throws {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return
        }
        
        let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
        let workouts = try context.fetch(descriptor)
        
        // Find workout with matching ID
        if let workoutToDelete = workouts.first(where: { $0.id.uuidString == id }) {
            context.delete(workoutToDelete)
            try context.save()
            print("Deleted workout with ID \(id)")
        } else {
            print("Workout with ID \(id) not found")
        }
    }
    
    /// Mark workout for deletion instead of immediately deleting
    /// - Parameter id: ID of workout to mark for deletion
    /// - Returns: Success status
    func markWorkoutForDeletion(id: String) -> Bool {
        guard let context = modelContext else {
            print("SwiftData context not available")
            return false
        }
        
        do {
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
            let workouts = try context.fetch(descriptor)
            
            // Find workout with matching ID
            if let workout = workouts.first(where: { $0.id.uuidString == id }) {
                // If the workout has never been synced (no server ID), delete it immediately
                if workout.serverId == nil {
                    context.delete(workout)
                } else {
                    // Otherwise mark it for deletion
                    workout.syncStatusEnum = .pendingDeletion
                }
                
                try context.save()
                print("Marked workout with ID \(id) for deletion")
                return true
            } else {
                print("Workout with ID \(id) not found")
                return false
            }
        } catch {
            print("Failed to mark workout for deletion: \(error)")
            return false
        }
    }
} 