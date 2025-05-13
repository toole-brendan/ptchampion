import SwiftUI
import Combine
import SwiftData
import UIKit

// Only one class declaration for WorkoutHistoryViewModel
class WorkoutHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Published state for UI
    @Published var workouts: [WorkoutHistory] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var filter: WorkoutFilter = .all
    @Published var currentWorkoutStreak: Int = 0
    @Published var longestWorkoutStreak: Int = 0
    @Published var chartData: [ChartableDataPoint] = []
    @Published var chartYAxisLabel: String = "Value"
    
    // Error display state
    @Published var showError = false
    @Published var errorMessage = "An error occurred"
    
    // MARK: - Internal Properties
    
    // Cache mechanism
    private var cache: [String: Any] = [:]
    private var lastFetchTime: [String: Date] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private let workoutService: WorkoutServiceProtocol
    var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    // Computed property for filtered workouts
    var workoutsFiltered: [WorkoutHistory] {
        if filter == .all {
            return workouts
        } else {
            return workouts.filter { $0.exerciseType == filter.exerciseTypeString }
        }
    }
    
    // MARK: - Initialization
    
    init(workoutService: WorkoutServiceProtocol = WorkoutService()) {
        self.workoutService = workoutService
        
        // Check if we have cached data on init
        loadFromCache()
        
        // Set up observers
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        // Listen for sync completion notifications to refresh UI
        NotificationCenter.default
            .publisher(for: .syncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Check if there was an error
                if let error = notification.userInfo?["error"] as? Error {
                    self?.handleSyncError(error)
                } else {
                    // Refresh workout list on successful sync
                    Task { @MainActor in
                        await self?.refreshWorkouts()
                    }
                }
            }
            .store(in: &cancellables)
            
        // Set up publishers for filter changes
        $filter
            .sink { [weak self] _ in
                self?.updateChartData()
            }
            .store(in: &cancellables)
        
        $workouts
            .sink { [weak self] _ in
                self?.updateChartData()
                self?.updateStreaks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Cache Methods
    
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
                    id: result.id.uuidString,
                    exerciseType: result.exerciseType,
                    reps: result.repCount,
                    distance: result.distanceMeters,
                    duration: TimeInterval(result.durationSeconds),
                    date: result.startTime,
                    score: result.score
                )
            }
        } catch {
            print("Failed to load workouts from SwiftData: \(error)")
            return []
        }
    }
    
    // MARK: - Public API Methods
    
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
                    date: record.createdAt,
                    score: nil
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
    func refreshWorkouts() {
        isLoading = true
        error = nil
        
        // First, try to load from local storage
        loadLocalWorkouts()
        
        // Then, try to fetch from network
        Task {
            do {
                // Make the API call with correct parameters
                guard let authToken = KeychainService.shared.getAccessToken() else {
                    throw NSError(domain: "WorkoutHistoryViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token found"])
                }
                
                let response = try await workoutService.fetchWorkoutHistory(authToken: authToken)
                
                await MainActor.run {
                    workouts = response.map { record in
                        WorkoutHistory(
                            id: String(record.id),
                            exerciseType: record.exerciseTypeKey,
                            reps: record.repetitions,
                            distance: nil, // Extract from metadata if available
                            duration: TimeInterval(record.timeInSeconds ?? 0),
                            date: record.createdAt,
                            score: nil
                        )
                    }
                    isLoading = false
                    
                    // Save fetched workouts to local storage
                    saveWorkoutsToLocalStorage(workouts)
                }
            } catch {
                print("Failed to fetch workout history: \(error)")
                await MainActor.run {
                    isLoading = false
                    // Note: We don't show an error here because we've already 
                    // loaded data from local storage as a fallback
                }
            }
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
                formScore: workout.score != nil ? Int(workout.score!) : nil,
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
        // Optimistic update - remove from local list
        let updatedWorkouts = self.workouts.filter { $0.id != id }
        self.workouts = updatedWorkouts
        
        // Update cache after confirmed
        cache["workouts"] = self.workouts
        lastFetchTime["workouts"] = Date()
        
        // Update SwiftData
        deleteWorkoutFromSwiftData(id: id)
    }
    
    // MARK: - SwiftData Operations
    
    /// Delete a workout by ID
    func deleteWorkout(id: String) {
        guard let modelContext = modelContext else {
            showError(message: "Local storage not available")
            return
        }
        
        // First mark the workout for deletion in SwiftData
        do {
            // Find the workout in SwiftData based on string ID
            // We need to manually find workouts by string ID comparison since
            // function calls like UUID() aren't allowed in Predicates
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
            let results = try modelContext.fetch(descriptor)
            
            // Find the matching workout manually
            let matchingWorkout = results.first { workout in
                workout.id.uuidString == id
            }
            
            if let workout = matchingWorkout {
                // If it has a server ID, mark it for deletion
                if workout.serverId != nil {
                    workout.syncStatusEnum = .pendingDeletion
                    
                    // Update the lastSyncAttempt timestamp
                    workout.lastSyncAttempt = Date()
                    
                    try modelContext.save()
                    
                    // Post notification to trigger sync if online
                    NotificationCenter.default.post(name: .connectivityRestored, object: nil)
                } else {
                    // If it doesn't have a server ID, delete it directly
                    modelContext.delete(workout)
                    try modelContext.save()
                }
            }
            
            // Remove from the displayed list
            workouts.removeAll { $0.id == id }
            
        } catch {
            print("Error marking workout for deletion: \(error)")
            showError(message: "Failed to delete workout: \(error.localizedDescription)")
        }
    }
    
    /// Delete workouts at specified indices (for SwiftUI onDelete)
    func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            deleteWorkout(id: workouts[index].id)
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
    
    /// Load workouts from local SwiftData storage
    private func loadLocalWorkouts() {
        guard let modelContext = modelContext else {
            print("ModelContext not available for local workout loading")
            return
        }
        
        do {
            // Create descriptor to fetch all workouts sorted by date (newest first)
            var descriptor = FetchDescriptor<WorkoutResultSwiftData>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            
            // Exclude workouts marked for deletion
            // Fix for Predicate body syntax
            let syncStatus = SyncStatus.pendingDeletion.rawValue
            let predicate = #Predicate<WorkoutResultSwiftData> { workout in
                workout.syncStatus != syncStatus
            }
            descriptor.predicate = predicate
            
            let results = try modelContext.fetch(descriptor)
            
            // Convert to WorkoutHistory objects
            let localWorkouts = results.map { model in
                WorkoutHistory(
                    id: model.id.uuidString,
                    exerciseType: model.exerciseType,
                    reps: model.repCount,
                    distance: model.distanceMeters,
                    duration: TimeInterval(model.durationSeconds),
                    date: model.startTime
                )
            }
            
            // Update the workouts list
            self.workouts = localWorkouts
            print("Loaded \(localWorkouts.count) workouts from local storage")
            
        } catch {
            print("Failed to load workouts from local storage: \(error)")
        }
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
                score: workout.score,
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
    
    /// Save workouts to local SwiftData storage
    private func saveWorkoutsToLocalStorage(_ workouts: [WorkoutHistory]) {
        guard let modelContext = modelContext else {
            print("ModelContext not available for local workout saving")
            return
        }
        
        do {
            // Create descriptor to fetch all existing workouts
            let descriptor = FetchDescriptor<WorkoutResultSwiftData>()
            let existingWorkouts = try modelContext.fetch(descriptor)
            
            // Create a set of existing IDs for efficient lookup
            let existingIds = Set(existingWorkouts.compactMap { 
                $0.serverId != nil ? String($0.serverId!) : nil
            })
            
            // Process each workout
            for workout in workouts {
                // Check if this workout already exists by server ID
                if existingIds.contains(workout.id) {
                    print("Workout with server ID \(workout.id) already exists in local storage")
                    continue
                }
                
                // Create a new SwiftData workout
                let newWorkout = WorkoutResultSwiftData(
                    exerciseType: workout.exerciseType,
                    startTime: workout.date,
                    endTime: workout.date.addingTimeInterval(workout.duration),
                    durationSeconds: Int(workout.duration),
                    repCount: workout.reps,
                    distanceMeters: workout.distance
                )
                
                // Set server ID and mark as synced since it came from the server
                if let serverId = Int(workout.id) {
                    newWorkout.serverId = serverId
                    newWorkout.syncStatusEnum = .synced
                }
                
                // Save the workout
                modelContext.insert(newWorkout)
            }
            
            // Save the context
            try modelContext.save()
            print("Saved \(workouts.count) workouts to local storage")
            
        } catch {
            print("Failed to save workouts to local storage: \(error)")
        }
    }
    
    // MARK: - Error Handling
    
    /// Show an error message
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    /// Handle sync errors
    private func handleSyncError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .authenticationError:
                showError(message: "Authentication failed. Please log in again.")
                
            case .requestFailed(let statusCode, let message):
                showError(message: "Server error (\(statusCode)): \(message ?? "Unknown error")")
                
            case .invalidResponse, .decodingError:
                showError(message: "Could not understand the server's response. Try again later.")
                
            default:
                showError(message: apiError.localizedDescription)
            }
        } else {
            showError(message: "Sync error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Chart and Streak Methods
    
    // Calculate and update chart data based on filtered workouts
    private func updateChartData() {
        let filteredWorkouts = workoutsFiltered
        let newChartData = filteredWorkouts
            .compactMap { workout -> ChartableDataPoint? in
                let date = workout.date
                var value: Double? = nil
                
                switch filter {
                case .all: return nil
                case .run:
                    if let distance = workout.distance, distance > 0 {
                        value = distance / 1000
                    }
                case .pushup, .situp, .pullup:
                    if let score = workout.score, score > 0 {
                        value = score
                    } else if let reps = workout.reps, reps > 0 {
                        value = Double(reps)
                    }
                }
                
                if let val = value {
                    return ChartableDataPoint(date: date, value: val)
                }
                return nil
            }
            .sorted { $0.date < $1.date }
        chartData = newChartData

        // Calculate label based on new data and current filter
        var newYAxisLabel: String
        switch filter {
            case .all: newYAxisLabel = "N/A"
            case .run: newYAxisLabel = "Distance (km)"
            case .pushup, .situp, .pullup:
                if newChartData.first?.value != nil {
                     if newChartData.contains(where: { $0.value > 50 }) {
                         newYAxisLabel = "Score"
                     } else {
                         newYAxisLabel = "Reps"
                     }
                } else {
                    newYAxisLabel = "Value"
                }
        }
        chartYAxisLabel = newYAxisLabel
    }
    
    // Calculate and update streak data
    private func updateStreaks() {
        // Calculate unique sorted workout days
        let uniqueDays = workouts
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted()
            .reduce(into: [Date]() { (uniqueDays, date) in
                if uniqueDays.last != date {
                    uniqueDays.append(date)
                }
            }
        
        guard !uniqueDays.isEmpty else {
            currentWorkoutStreak = 0
            longestWorkoutStreak = 0
            return
        }
        
        let calendar = Calendar.current
        
        // Calculate Longest Streak
        var maxStreak = 0
        var currentConsStreak = 0
        var previousDay: Date? = nil
        
        for day in uniqueDays {
            if let prev = previousDay {
                if calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prev)!) {
                    currentConsStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentConsStreak)
                    currentConsStreak = 1 // Reset
                }
            } else {
                currentConsStreak = 1 // Start
            }
            previousDay = day
        }
        longestWorkoutStreak = max(maxStreak, currentConsStreak)
        
        // Calculate Current Streak
        let today = calendar.startOfDay(for: Date()
        let uniqueDaysSet = Set(uniqueDays)
        var currentStrk = 0
        var dateToFind = today

        if uniqueDaysSet.contains(dateToFind) {
            currentStrk += 1
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            while uniqueDaysSet.contains(dateToFind) {
                currentStrk += 1
                dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
            }
        } else {
            dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // yesterday
            if uniqueDaysSet.contains(dateToFind) {
                 currentStrk += 1
                 dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)! // day before yesterday
                 while uniqueDaysSet.contains(dateToFind) {
                    currentStrk += 1
                    dateToFind = calendar.date(byAdding: .day, value: -1, to: dateToFind)!
                }
            }
        }
        currentWorkoutStreak = currentStrk
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
    let score: Double?
    
    init(id: String, exerciseType: String, reps: Int? = nil, distance: Double? = nil, duration: TimeInterval, date: Date, score: Double? = nil) {
        self.id = id
        self.exerciseType = exerciseType
        self.reps = reps
        self.distance = distance
        self.duration = duration
        self.date = date
        self.score = score
    }
    
    // Helper to convert to WorkoutResultSwiftData
    func toWorkoutResult() -> WorkoutResultSwiftData {
        let workoutResult = WorkoutResultSwiftData(
            exerciseType: exerciseType,
            startTime: date,
            endTime: date.addingTimeInterval(duration),
            durationSeconds: Int(duration),
            repCount: reps,
            score: score,
            distanceMeters: distance
        )
        return workoutResult
    }
} 