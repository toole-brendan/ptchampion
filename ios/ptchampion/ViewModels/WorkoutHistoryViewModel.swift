import SwiftUI
import Combine

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
    private let persistenceService: WorkoutPersistenceService
    
    init(workoutService: WorkoutServiceProtocol = WorkoutService(), 
         persistenceService: WorkoutPersistenceService = WorkoutPersistenceService()) {
        self.workoutService = workoutService
        self.persistenceService = persistenceService
        
        // Check if we have cached data on init
        loadFromCache()
    }
    
    private func loadFromCache() {
        if let cached = cache["workouts"] as? [WorkoutHistory] {
            self.workouts = cached
        } else {
            // If no in-memory cache, try loading from SwiftData
            let persistedWorkouts = persistenceService.retrieveWorkouts()
            if !persistedWorkouts.isEmpty {
                self.workouts = persistedWorkouts
                cache["workouts"] = persistedWorkouts
                lastFetchTime["workouts"] = Date() // Consider it fresh since we just loaded it
            }
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
            // Use the workoutService to fetch data
            let freshWorkouts = try await workoutService.fetchWorkoutHistory()
            
            // Update the cache
            self.workouts = freshWorkouts
            cache[cacheKey] = freshWorkouts
            lastFetchTime[cacheKey] = Date()
            
            // Store to persistent storage (similar to IndexedDB in web)
            persistenceService.saveWorkouts(freshWorkouts)
        } catch {
            self.error = error
            
            // If network fails, try to use persisted data if we don't already have it
            if workouts.isEmpty {
                let persistedWorkouts = persistenceService.retrieveWorkouts()
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
            let freshWorkouts = try await workoutService.fetchWorkoutHistory()
            
            // Update and save
            self.workouts = freshWorkouts
            cache["workouts"] = freshWorkouts
            lastFetchTime["workouts"] = Date()
            
            persistenceService.saveWorkouts(freshWorkouts)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // Method to add a new workout and update both cache and server
    @MainActor
    func addWorkout(_ workout: WorkoutHistory) async {
        do {
            // Optimistic update
            var updatedWorkouts = self.workouts
            updatedWorkouts.insert(workout, at: 0)
            self.workouts = updatedWorkouts
            
            // Save to server
            try await workoutService.saveWorkout(workout)
            
            // Update cache after confirmed
            cache["workouts"] = self.workouts
            lastFetchTime["workouts"] = Date()
            
            // Persist locally
            persistenceService.saveWorkouts(self.workouts)
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
            
            // Try to delete on server (implementation depends on your API)
            // try await workoutService.deleteWorkout(id: id)
            
            // Update cache after confirmed
            cache["workouts"] = self.workouts
            lastFetchTime["workouts"] = Date()
            
            // Update persistence
            try persistenceService.deleteWorkout(id: id)
        } catch {
            // If delete fails, refresh to sync with server
            await fetchWorkouts()
            self.error = error
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