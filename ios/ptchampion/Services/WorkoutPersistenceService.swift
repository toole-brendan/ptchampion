import Foundation
import SwiftData

/// Service to handle local persistence of workouts to SwiftData
class WorkoutPersistenceService {
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext?
    
    init() {
        // Set up SwiftData container and context
        do {
            let schema = Schema([WorkoutResultSwiftData.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            self.modelContext = ModelContext(modelContainer!)
        } catch {
            print("Failed to create SwiftData container: \(error)")
            self.modelContainer = nil
            self.modelContext = nil
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
                    distanceMeters: workout.distance
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
} 