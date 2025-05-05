import SwiftUI
import Combine
import SwiftData
import UIKit

// Annotation similar to what's mentioned in the plan
@Observable class WorkoutHistoryViewModel {
    // Published state
    var workouts: [WorkoutHistory] = []
    var isLoading: Bool = false
    var error: Error? = nil
    
    // Cache mechanism
    private var cache: [String: Any] = [:]
    private var lastFetchTime: [String: Date] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private let workoutService: WorkoutServiceProtocol
    var modelContext: ModelContext?
    
    init(workoutService: WorkoutServiceProtocol = WorkoutService()) {
        self.workoutService = workoutService
        
        // Check if we have cached data on init
        loadFromCache()
    }
    
    private func loadFromCache() {
        if let cached = cache["workouts"] as? [WorkoutHistory] {
            self.workouts = cached
        } else {
            // If no in-memory cache, try loading from SwiftData
            let workouts = loadWorkoutsFromSwiftData()
            if !workouts.isEmpty {
                self.workouts = workouts
                cache["workouts"] = workouts
                lastFetchTime["workouts"] = Date() // Consider it fresh since we just loaded it
            }
        }
    }
    
    // Helper to load workouts from SwiftData
    private func loadWorkoutsFromSwiftData() -> [WorkoutHistory] {
        guard let context = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            let results = try context.fetch(descriptor)
            
            return results.map { result in
                WorkoutHistory(
                    id: String(describing: result.id),
                    exerciseType: result.exerciseType,
                    reps: result.repCount,
                    distance: result.distanceMeters,
                    duration: TimeInterval(result.durationSeconds),
                    date: result.startTime
                )
            }
        } catch {
            print("Failed to load workouts from SwiftData: \(error)")
            return []
        }
    }
    
    // Similar to React Query's useQuery with stale data behavior
    @MainActor
    func fetchWorkouts() async {
        // If we're already loading, don't fetch again
        guard !isLoading else { return }
        
        // Check if data is stale (older than 5 minutes)
        let staleTime: TimeInterval = 5 * 60
        let cacheKey = "workouts"
        let isFresh = lastFetchTime[cacheKey].map { 
            Date().timeIntervalSince($0) < staleTime 
        } ?? false
        
        // If we have fresh data and it's not empty, don't fetch again
        if isFresh && !workouts.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Use KeychainService to get auth token
            guard let authToken = KeychainService.shared.getAccessToken() else {
                throw NSError(domain: "WorkoutHistoryViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token found"])
            }
            
            // Use the workoutService to fetch data
            let freshWorkouts = try await workoutService.fetchWorkoutHistory(authToken: authToken)
            
            // Convert API model to our local model if needed
            let convertedWorkouts = freshWorkouts.map { record in
                WorkoutHistory(
                    id: String(record.id),
                    exerciseType: record.exerciseTypeKey,
                    reps: record.repetitions,
                    distance: nil, // Extract from metadata if available
                    duration: TimeInterval(record.timeInSeconds ?? 0),
                    date: record.createdAt
                )
            }
            
            // Update the cache
            self.workouts = convertedWorkouts
            cache[cacheKey] = convertedWorkouts
            lastFetchTime[cacheKey] = Date()
            
            // Store to SwiftData
            saveWorkoutsToSwiftData(convertedWorkouts)
        } catch {
            self.error = error
            
            // If network fails, try to use persisted data if we don't already have it
            if workouts.isEmpty {
                let persistedWorkouts = loadWorkoutsFromSwiftData()
                if !persistedWorkouts.isEmpty {
                    self.workouts = persistedWorkouts
                    cache[cacheKey] = persistedWorkouts
                }
            }
        }
        
        isLoading = false
    }
    
    // For manual refresh, force a new fetch regardless of cache state
    @MainActor
    func refreshWorkouts() async {
        isLoading = true
        error = nil
        
        do {
            guard let authToken = KeychainService.shared.getAccessToken() else {
                throw NSError(domain: "WorkoutHistoryViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token found"])
            }
            
            let freshWorkouts = try await workoutService.fetchWorkoutHistory(authToken: authToken)
            
            // Convert API model to our local model
            let convertedWorkouts = freshWorkouts.map { record in
                WorkoutHistory(
                    id: String(record.id),
                    exerciseType: record.exerciseTypeKey,
                    reps: record.repetitions,
                    distance: nil, // Extract from metadata if available
                    duration: TimeInterval(record.timeInSeconds ?? 0),
                    date: record.createdAt
                )
            }
            
            // Update and save
            self.workouts = convertedWorkouts
            cache["workouts"] = convertedWorkouts
            lastFetchTime["workouts"] = Date()
            
            saveWorkoutsToSwiftData(convertedWorkouts)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // Helper to save workouts to SwiftData
    private func saveWorkoutsToSwiftData(_ workouts: [WorkoutHistory]) {
        guard let context = modelContext else { return }
        
        for workout in workouts {
            let result = WorkoutResultSwiftData(
                exerciseType: workout.exerciseType,
                startTime: workout.date,
                endTime: workout.date.addingTimeInterval(workout.duration),
                durationSeconds: Int(workout.duration),
                repCount: workout.reps,
                distanceMeters: workout.distance
            )
            context.insert(result)
        }
        
        do {
            try context.save()
            print("Saved \(workouts.count) workouts to SwiftData")
        } catch {
            print("Failed to save workouts to SwiftData: \(error)")
        }
    }
    
    // Method to add a new workout and update both cache and server
    @MainActor
    func addWorkout(_ workout: WorkoutHistory) async {
        do {
            // Optimistic update
            var updatedWorkouts = self.workouts
            updatedWorkouts.insert(workout, at: 0)
            self.workouts = updatedWorkouts
            
            // Convert to API model and save to server
            guard let authToken = KeychainService.shared.getAccessToken() else {
                throw NSError(domain: "WorkoutHistoryViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token found"])
            }
            
            // Create a proper API request
            let request = InsertUserExerciseRequest(
                userId: 0, // Will be determined by server from token
                exerciseId: 0, // Will be determined by server from exerciseType
                repetitions: workout.reps,
                formScore: nil,
                timeInSeconds: Int(workout.duration),
                grade: nil,
                completed: true,
                metadata: "{\"exerciseType\":\"\(workout.exerciseType)\"}", // Simple metadata
                deviceId: UIDevice.current.identifierForVendor?.uuidString,
                syncStatus: "synced"
            )
            
            // Save to server
            try await workoutService.saveWorkout(result: request, authToken: authToken)
            
            // Update cache after confirmed
            cache["workouts"] = self.workouts
            lastFetchTime["workouts"] = Date()
            
            // Persist locally
            saveWorkoutsToSwiftData([workout])
        } catch {
            // Revert optimistic update on error
            await fetchWorkouts()
            self.error = error
        }
    }
    
    // Delete a workout both remotely and locally
    @MainActor
    func deleteWorkout(id: String) async {
        do {
            // Optimistic update - remove from local list
            let updatedWorkouts = self.workouts.filter { $0.id != id }
            self.workouts = updatedWorkouts
            
            // Update cache after confirmed
            cache["workouts"] = self.workouts
            lastFetchTime["workouts"] = Date()
            
            // Update SwiftData
            deleteWorkoutFromSwiftData(id: id)
        } catch {
            // If delete fails, refresh to sync with server
            await fetchWorkouts()
            self.error = error
        }
    }
    
    // Helper to delete workout from SwiftData
    private func deleteWorkoutFromSwiftData(id: String) {
        guard let context = modelContext else { return }
        
        do {
            // Instead of using string interpolation, fetch all and filter manually
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
            let allResults = try context.fetch(descriptor)
            
            // Filter the results manually to find matching ID
            let resultsToDelete = allResults.filter { workout in 
                workout.id.uuidString == id
            }
            
            // Delete the matching results
            for result in resultsToDelete {
                context.delete(result)
            }
            
            try context.save()
            print("Deleted workout with ID \(id) from SwiftData")
        } catch {
            print("Failed to delete workout from SwiftData: \(error)")
        }
    }
}

// Sample model
struct WorkoutHistory: Identifiable, Codable {
    let id: String
    let exerciseType: String
    let reps: Int?
    let distance: Double?
    let duration: TimeInterval
    let date: Date
} 