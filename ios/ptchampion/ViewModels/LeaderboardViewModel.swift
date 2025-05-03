import Foundation
import Combine
import CoreLocation
import SwiftUI
import os.log

// Setup logger with better subsystem name
private let logger = Logger(subsystem: "com.ptchampion.leaderboard", category: "LeaderboardViewModel")

// Define necessary types directly in this file to avoid import issues

// Represents a single entry in a leaderboard
struct LeaderboardEntry: Identifiable {
    let id: String 
    let rank: Int
    let userId: String?
    let name: String  // Will use either username or displayName from backend
    let score: Int    // Will map from bestGrade or score from backend
    
    // Factory method to create from backend GlobalLeaderboardEntry
    static func fromGlobalEntry(_ entry: GlobalLeaderboardEntry, rank: Int) -> LeaderboardEntry {
        return LeaderboardEntry(
            id: "global-\(entry.id)",
            rank: rank,
            userId: "\(entry.id)",
            name: entry.displayName ?? entry.username,
            score: entry.score
        )
    }
    
    // Factory method to create from backend LocalLeaderboardEntry
    static func fromLocalEntry(_ entry: LocalLeaderboardEntry, rank: Int) -> LeaderboardEntry {
        return LeaderboardEntry(
            id: "local-\(entry.id)",
            rank: rank,
            userId: "\(entry.id)",
            name: entry.displayName ?? entry.username,
            score: entry.score
        )
    }
}

// Define the LeaderboardType within the ViewModel or globally if used elsewhere
enum LeaderboardType: String, CaseIterable, Identifiable {
    case global = "Global"
    case local = "Local (5mi)" // Example distance, adjust as needed
    var id: String { self.rawValue }
}

// Define LeaderboardCategory enum
enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case allTime = "All Time"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        return self.rawValue
    }
    
    // Add conversion to backend parameter
    var apiParameter: String {
        switch self {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .allTime: return "all_time"
        }
    }
}

// Protocol definitions moved to their respective files

@MainActor
class LeaderboardViewModel: ObservableObject {
    // Debug ID to track instance lifecycle - using a shorter ID
    private let instanceId = UUID().uuidString.prefix(6)
    
    // Debug timestamp function
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    private let leaderboardService: LeaderboardServiceProtocol
    private let locationService: LocationServiceProtocol
    private let keychainService: KeychainServiceProtocol
    
    // Network state
    private var cancellables = Set<AnyCancellable>()
    private var isDataFetchInProgress = false
    private var currentFetchTask: Task<Void, Never>? = nil
    
    // Flag to track if we're in the process of deinitializing
    private var isBeingDeallocated = false
    
    // Always default to mock data initially to prevent freezing
    private var useMockData = true
    
    // Whether to automatically load data on init - disabled by default for performance
    private var autoLoadData = false
    
    // Add a flag to track if we've switched to real data mode
    private var hasAttemptedRealDataLoad = false
    
    // Set a shorter timeout for network operations to prevent long freezes
    private let networkTimeoutSeconds: TimeInterval = 5.0
    
    // Add a dedicated log function with severity levels
    private func logMessage(_ message: String, level: OSLogType = .debug) {
        let prefix = "🔍 LeaderboardViewModel[\(self.instanceId)]:"
        let timePrefix = "[\(timestamp())]"
        print("\(timePrefix) \(prefix) \(message)")
        
        switch level {
        case .debug:
            logger.debug("[\(self.instanceId)] \(message)")
        case .error:
            logger.error("[\(self.instanceId)] \(message)")
        case .fault:
            logger.fault("[\(self.instanceId)] \(message)")
        case .info:
            logger.info("[\(self.instanceId)] \(message)")
        default:
            logger.debug("[\(self.instanceId)] \(message)")
        }
    }
    
    // Add a non-isolated version of logging for use in nonisolated contexts
    nonisolated private func logMessageNonIsolated(_ message: String, level: OSLogType = .debug) {
        // Can be called from any thread/context
        let instanceIdCopy = self.instanceId
        
        // Create timestamp in non-isolated context
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeStr = formatter.string(from: Date())
        
        let prefix = "🔍 LeaderboardViewModel[\(instanceIdCopy)]:"
        let timePrefix = "[\(timeStr)]"
        print("\(timePrefix) \(prefix) \(message) [Thread: \(Thread.current.description)]")
        
        switch level {
        case .debug:
            logger.debug("[\(instanceIdCopy)] \(message)")
        case .error:
            logger.error("[\(instanceIdCopy)] \(message)")
        case .fault:
            logger.fault("[\(instanceIdCopy)] \(message)")
        case .info:
            logger.info("[\(instanceIdCopy)] \(message)")
        default:
            logger.debug("[\(instanceIdCopy)] \(message)")
        }
    }

    @Published var selectedBoard: LeaderboardType = .global {
        didSet { 
            guard oldValue != selectedBoard else { 
                logMessage("Board selection unchanged, skipping fetch", level: .debug)
                return 
            }
            
            logMessage("Board selection changed to \(self.selectedBoard.rawValue)", level: .debug)
            
            // Use a more controlled approach to trigger data fetch
            refreshData()
        }
    }
    
    @Published var selectedCategory: LeaderboardCategory = .weekly {
        didSet { 
            guard oldValue != selectedCategory else { 
                logMessage("Category selection unchanged, skipping fetch", level: .debug)
                return 
            }
            
            logMessage("Category selection changed to \(self.selectedCategory.rawValue)", level: .debug)
            
            // Use a more controlled approach to trigger data fetch
            refreshData()
        }
    }
    
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var backendStatus: BackendStatus = .unknown

    // Backend connection status
    enum BackendStatus {
        case unknown
        case connected
        case noActiveUsers
        case connectionFailed(String)
        case timedOut
    }

    private let localRadiusMiles = 5 // Configurable radius for local search

    init(leaderboardService: LeaderboardServiceProtocol? = nil,
         locationService: LocationServiceProtocol? = nil,
         keychainService: KeychainServiceProtocol? = nil,
         useMockData: Bool = false,
         autoLoadData: Bool = true) {
        // Initialize all stored properties first
        self.leaderboardService = leaderboardService ?? LeaderboardService()
        self.locationService = locationService ?? LocationService()
        self.keychainService = keychainService ?? KeychainService()
        self.useMockData = useMockData
        self.autoLoadData = autoLoadData
        
        // Now that all stored properties are initialized, we can use 'self'
        logMessage("Initializing LeaderboardViewModel instance \(self.instanceId)", level: .debug)
        
        // Still subscribe to location updates but don't request permission until needed
        subscribeToLocationStatus()
        
        // Only start initial load if autoLoadData is true
        if autoLoadData {
            // Don't start loading immediately, wait for a delay
            // This prevents loading during initialization which can cause UI freezes
            logMessage("Auto-load enabled, scheduling delayed data fetch", level: .debug)
            
            // FIXED: Use weak self to prevent retain cycle
            Task { [weak self] in 
                guard let self = self else { 
                    print("DEBUG-TASK: Self is nil in initial load task")
                    return 
                }
                
                self.logMessage("DEBUG: Initial data load task started - before sleep", level: .debug)
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                self.logMessage("DEBUG: Initial data load task - after sleep", level: .debug)
                
                // Check if task is cancelled or view model is being deallocated
                if !Task.isCancelled && !self.isBeingDeallocated {
                    self.logMessage("Starting initial data fetch after delay", level: .debug)
                    await self.fetchLeaderboardData() 
                } else {
                    self.logMessage("Initial data fetch task was cancelled, skipping", level: .debug)
                }
            }
        } else {
            logMessage("Auto-load disabled, skipping initial data fetch", level: .debug)
        }
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.logMessage("Location permission status changed to: \(status.rawValue)", level: .debug)
                self.locationPermissionStatus = status
                // If switching to local and status becomes authorized, refetch
                if self.selectedBoard == .local && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    self.logMessage("Location authorized, fetching local board", level: .debug)
                    self.refreshData()
                }
            }
            .store(in: &cancellables)

        locationService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.logMessage("Location service error: \(error.localizedDescription)", level: .error)
                if self.selectedBoard == .local {
                    self.errorMessage = "Could not get location for local leaderboard: \(error.localizedDescription)"
                    self.leaderboardEntries = [] // Clear entries if location fails
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    // Reset the ViewModel's state back to default values
    func resetState() {
        logMessage("Resetting state to default values", level: .debug)
        self.isLoading = false
        self.isDataFetchInProgress = false
        self.errorMessage = nil
    }

    func fetchLeaderboardData() async {
        logMessage("⏱️ FETCH START: fetchLeaderboardData called")
        
        // Cancel any existing fetch task first to prevent multiple concurrent fetches
        if let task = currentFetchTask {
            logMessage("⏱️ Cancelling existing task", level: .debug)
            task.cancel()
            currentFetchTask = nil
            logMessage("⏱️ Existing task cancelled", level: .debug)
        }
        
        // Prevent concurrent fetches
        guard !isDataFetchInProgress else {
            logMessage("⚠️ BLOCKED: Fetch already in progress, skipping new request", level: .debug)
            return
        }
        
        // Check if we're in the process of deinitializing
        guard !isBeingDeallocated else {
            logMessage("⚠️ BLOCKED: View model is being deallocated, aborting fetch", level: .debug)
            return
        }
        
        logMessage("✅ PRE-CHECKS PASSED: Beginning fetch operation", level: .debug)
        
        // Check if location permission is needed for Local scope
        if selectedBoard == .local {
            logMessage("🔍 LOCATION CHECK: Selected board is local, checking permissions", level: .debug)
            if locationPermissionStatus == .notDetermined {
                logMessage("⚠️ LOCATION NEEDED: Requesting location permission", level: .debug)
                locationService.requestLocationPermission()
                // bail out for now – user will retry after allowing permission
                self.isLoading = false
                logMessage("⚠️ EXITING: Location permission not determined", level: .debug)
                return
            }
            logMessage("✅ LOCATION CHECK PASSED: Continuing with local board fetch", level: .debug)
        } else {
            logMessage("✅ LOCATION SKIPPED: Selected board is global", level: .debug)
        }
        
        // Update state flags
        logMessage("🔄 UPDATING STATE: Setting loading flags", level: .debug)
        isDataFetchInProgress = true
        isLoading = true
        errorMessage = nil
        logMessage("✅ STATE UPDATED: Ready to begin network operations", level: .debug)
        
        // Store a local copy of current selections to prevent race conditions
        let boardType = selectedBoard
        let categoryType = selectedCategory
        logMessage("📊 REQUEST PARAMS: Board=\(boardType.rawValue), Category=\(categoryType.rawValue)", level: .debug)
        
        // Create a timeout task that will complete after networkTimeoutSeconds
        logMessage("⏱️ CREATING TIMEOUT: Setting \(networkTimeoutSeconds)s timeout", level: .debug)
        let timeoutTask = Task { 
            do {
                logMessage("⏱️ TIMEOUT TASK: Starting sleep", level: .debug)
                try await Task.sleep(nanoseconds: UInt64(networkTimeoutSeconds * 1_000_000_000))
                logMessage("⚠️ TIMEOUT TASK: Timeout occurred!", level: .debug)
                return true // Timeout occurred
            } catch {
                logMessage("🛑 TIMEOUT TASK: Sleep interrupted", level: .debug)
                return false // Sleep was interrupted (task cancelled)
            }
        }
        
        // Create the actual data fetch task with a task priority of .userInitiated
        // Using explicit priority to ensure task receives appropriate system resources
        logMessage("🚀 CREATING FETCH TASK: About to start network task", level: .debug)
        currentFetchTask = Task(priority: .userInitiated) { 
            do {
                logMessage("🚀 FETCH TASK: Task started", level: .debug)
                // Use a different approach based on whether we're using mock data or real data
                var entries: [LeaderboardEntry] = []
                
                // Only try real data if view isn't being deallocated
                if isBeingDeallocated {
                    logMessage("⚠️ FETCH TASK: View is closing during fetch", level: .debug)
                    throw NSError(domain: "LeaderboardViewModel", code: 500,
                                 userInfo: [NSLocalizedDescriptionKey: "View is closing, aborting API call"])
                }
                
                // Mark that we've attempted to use real data
                hasAttemptedRealDataLoad = true
                
                // Get auth token from keychain service
                logMessage("🔑 FETCH TASK: Getting auth token from keychain", level: .debug)
                guard let token = keychainService.getAccessToken() else {
                    logMessage("❌ FETCH TASK: No auth token found", level: .error)
                    throw NSError(domain: "LeaderboardViewModel", code: 401, 
                                 userInfo: [NSLocalizedDescriptionKey: "Authentication token not found"])
                }
                logMessage("✅ FETCH TASK: Got auth token", level: .debug)
                
                // Choose which API call to make based on the board type
                if boardType == .global {
                    logMessage("🌎 FETCH TASK: Fetching GLOBAL leaderboard for timeFrame: \(categoryType.apiParameter)...", level: .debug)
                    print("Fetching global leaderboard for timeFrame: \(categoryType.apiParameter)...")
                    
                    do {
                        logMessage("🌎 FETCH TASK: About to call leaderboardService.fetchGlobalLeaderboard", level: .debug)
                        let globalEntries = try await leaderboardService.fetchGlobalLeaderboard(
                            authToken: token,
                            timeFrame: categoryType.apiParameter
                        )
                        logMessage("✅ FETCH TASK: Successfully fetched \(globalEntries.count) global entries", level: .debug)
                        entries = globalEntries
                    } catch {
                        logMessage("❌ FETCH TASK: Global leaderboard fetch failed: \(error.localizedDescription)", level: .error)
                        print("Network error fetching global leaderboard: \(error)")
                        if let networkClient = self.leaderboardService as? LeaderboardService {
                            logMessage("⚠️ FETCH TASK: Network client state: \(String(describing: networkClient))", level: .debug)
                            print("NetworkClient not available, falling back to mock data")
                            
                            // Generate 10 mock global entries for testing
                            for i in 1...10 {
                                entries.append(LeaderboardEntry(
                                    id: "mock-global-\(i)",
                                    rank: i,
                                    userId: "user-\(i)",
                                    name: "Mock User \(i)",
                                    score: 1000 - (i * 50)
                                ))
                            }
                            logMessage("✅ FETCH TASK: Generated \(entries.count) mock global entries", level: .debug)
                            print("Generated \(entries.count) mock global entries")
                        } else {
                            throw error
                        }
                    }
                } else {
                    logMessage("📍 FETCH TASK: Fetching LOCAL leaderboard", level: .debug)
                    // Check location permission first to avoid API calls when permissions are denied
                    let locationStatus = locationService.getCurrentAuthorizationStatus()
                    logMessage("📍 FETCH TASK: Current location status: \(locationStatus.rawValue)", level: .debug)
                    
                    if locationStatus == .denied || locationStatus == .restricted {
                        // No point in trying to get location - will fail
                        logMessage("❌ FETCH TASK: Location permission denied/restricted", level: .error)
                        handleLocalLocationPermission()
                        throw NSError(domain: "LeaderboardViewModel", code: 403,
                                    userInfo: [NSLocalizedDescriptionKey: "Location permission denied"])
                    }
                    
                    // Fetch local leaderboard - need location first
                    logMessage("📍 FETCH TASK: Requesting current location", level: .debug)
                    let locationResult: CLLocation?
                    do {
                        // Use a timeout to prevent waiting indefinitely for location
                        let locationTask = Task<CLLocation?, Error> { 
                            do {
                                logMessage("📍 LOCATION TASK: Getting location", level: .debug)
                                return try await self.locationService.getCurrentLocation()
                            } catch {
                                logMessage("❌ LOCATION TASK: Failed to get location: \(error)", level: .error)
                                throw error
                            }
                        }
                        
                        // Create a timeout task
                        logMessage("⏱️ LOCATION TIMEOUT: Creating 2 second timeout for location", level: .debug)
                        let timeoutTask = Task {
                            try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000)) // 2 second timeout
                            logMessage("⚠️ LOCATION TIMEOUT: Location request timed out", level: .debug)
                            return true
                        }
                        
                        // Race the tasks
                        do {
                            logMessage("🏁 LOCATION RACE: Waiting for either location or timeout", level: .debug)
                            let timeoutResult = try await timeoutTask.value
                            if timeoutResult {
                                // Timeout occurred
                                logMessage("⚠️ LOCATION RACE: Location request timed out", level: .debug)
                                locationResult = nil
                            } else {
                                logMessage("✅ LOCATION RACE: Got location before timeout", level: .debug)
                                locationResult = try await locationTask.value
                            }
                        } catch {
                            // Handle error from locationTask or timeoutTask
                            logMessage("❌ LOCATION RACE: Error in location race: \(error)", level: .error)
                            locationResult = nil
                            self.logMessage("Error getting location: \(error.localizedDescription)", level: .error)
                        }
                    } catch {
                        logMessage("❌ FETCH TASK: Location catch-all error: \(error)", level: .error)
                        locationResult = nil
                    }
                    
                    guard let location = locationResult else {
                        logMessage("❌ FETCH TASK: No location available", level: .error)
                        throw NSError(domain: "LeaderboardViewModel", code: 400, 
                                     userInfo: [NSLocalizedDescriptionKey: "Location not available or timeout"])
                    }
                    
                    logMessage("📍 FETCH TASK: Got location, fetching local leaderboard", level: .debug)
                    do {
                        logMessage("📍 FETCH TASK: About to call leaderboardService.fetchLocalLeaderboard", level: .debug)
                        let localEntries = try await leaderboardService.fetchLocalLeaderboard(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            radiusMiles: localRadiusMiles,
                            authToken: token
                        )
                        logMessage("✅ FETCH TASK: Successfully fetched \(localEntries.count) local entries", level: .debug)
                        entries = localEntries
                    } catch {
                        logMessage("❌ FETCH TASK: Local leaderboard fetch failed: \(error.localizedDescription)", level: .error)
                        print("Network error fetching local leaderboard: \(error)")
                        
                        if let networkClient = self.leaderboardService as? LeaderboardService {
                            logMessage("⚠️ FETCH TASK: Network client state: \(String(describing: networkClient))", level: .debug)
                            print("NetworkClient not available, falling back to mock data")
                            
                            // Generate 10 mock local entries for testing
                            for i in 1...10 {
                                entries.append(LeaderboardEntry(
                                    id: "mock-local-\(i)",
                                    rank: i,
                                    userId: "user-\(i)",
                                    name: "Local User \(i)",
                                    score: 800 - (i * 50)
                                ))
                            }
                            logMessage("✅ FETCH TASK: Generated \(entries.count) mock local entries", level: .debug)
                            print("Generated \(entries.count) mock local entries")
                        } else {
                            throw error
                        }
                    }
                }
                
                // Check if the task was cancelled or if timeout occurred
                logMessage("⏱️ FETCH TASK: Checking for timeout", level: .debug)
                let timeoutOccurred = await timeoutTask.value
                if Task.isCancelled || timeoutOccurred {
                    logMessage("⚠️ FETCH TASK: Task was cancelled or timed out", level: .debug)
                    if timeoutOccurred {
                        logMessage("⚠️ FETCH TASK: Request timed out", level: .debug)
                        await MainActor.run {
                            self.errorMessage = "Request timed out. Please try again."
                            self.backendStatus = .timedOut
                            self.isLoading = false
                            self.isDataFetchInProgress = false
                            logMessage("✅ FETCH TASK: Updated UI with timeout state", level: .debug)
                        }
                    }
                    return
                }
                
                // Update the UI on the main thread with the results
                logMessage("✅ FETCH TASK: Fetch completed successfully, updating UI", level: .debug)
                await MainActor.run {
                    if !self.isBeingDeallocated {
                        logMessage("✅ FETCH TASK: Updating UI on MainActor", level: .debug)
                        self.leaderboardEntries = entries
                        self.errorMessage = nil               // do NOT set an error
                        self.backendStatus = entries.isEmpty
                            ? .noActiveUsers   // used by the empty-state UI
                            : .connected
                        self.isLoading = false
                        self.isDataFetchInProgress = false
                        self.logMessage("Updated UI with \(entries.count) entries", level: .debug)
                        logMessage("✅ FETCH TASK: UI update complete", level: .debug)
                    } else {
                        logMessage("⚠️ FETCH TASK: View model deallocated during UI update", level: .debug)
                    }
                }
            } catch {
                // Only update UI if not cancelled and not being deallocated
                logMessage("❌ FETCH TASK: Error: \(error.localizedDescription)", level: .error)
                if !Task.isCancelled && !self.isBeingDeallocated {
                    logMessage("❌ FETCH TASK: Updating UI with error", level: .debug)
                    await MainActor.run {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                        self.backendStatus = .connectionFailed(error.localizedDescription)
                        self.leaderboardEntries = []
                        self.isLoading = false
                        self.isDataFetchInProgress = false
                        logMessage("✅ FETCH TASK: Updated UI with error state", level: .debug)
                    }
                    self.logMessage("Error loading leaderboard: \(error.localizedDescription)", level: .error)
                } else {
                    logMessage("⚠️ FETCH TASK: Task cancelled or view deallocated during error handling", level: .debug)
                }
            }
            
            // Always cancel the timeout task when we finish
            logMessage("🧹 FETCH TASK: Cleaning up timeout task", level: .debug)
            timeoutTask.cancel()
            logMessage("✅ FETCH TASK: Fetch operation complete", level: .debug)
        }
        
        logMessage("✅ FETCH SETUP COMPLETE: Task created and started", level: .debug)
    }
    
    // MARK: - Added methods to fix freezing issues
    
    /// Cancel any active tasks to prevent background processing when view disappears
    nonisolated func cancelActiveTasks() {
        // This can be called from any thread
        // Use the nonisolated logging function instead of the isolated one
        logMessageNonIsolated("⚠️ Cancelling active tasks (nonisolated)", level: .debug)
        
        // Dispatch to main actor to cancel tasks safely
        Task { @MainActor [weak self] in
            guard let self = self else {
                print("⚠️ Self is nil in cancelActiveTasks Task")
                return
            }
            self.logMessage("⚠️ About to call cancelTasksFromMainActor()", level: .debug)
            await self.cancelTasksFromMainActor()
        }
    }
    
    /// MainActor-isolated method that safely cancels tasks
    func cancelTasksFromMainActor() {
        logMessage("⚠️ Cancelling tasks from MainActor", level: .debug)
        
        // Cancel the current fetch task if it exists
        if let task = currentFetchTask {
            logMessage("⚠️ Active fetch task found, cancelling", level: .debug)
            task.cancel()
            logMessage("⚠️ Active fetch task cancelled", level: .debug)
        } else {
            logMessage("⚠️ No active fetch task to cancel", level: .debug)
        }
        
        // Reset the task reference
        currentFetchTask = nil
        logMessage("⚠️ Task reference cleared", level: .debug)
        
        // Ensure we reset the data fetch flag
        isDataFetchInProgress = false
        logMessage("⚠️ isDataFetchInProgress flag reset", level: .debug)
        
        logMessage("⚠️ Tasks cancelled on MainActor", level: .debug)
    }
    
    /// Clean up the UI state after cancellation (must be called on main actor)
    func cleanupAfterCancellation() {
        logMessage("⚠️ Cleaning up state after cancellation", level: .debug)
        
        // Reset all state flags immediately
        isDataFetchInProgress = false
        logMessage("⚠️ Reset isDataFetchInProgress", level: .debug)
        isLoading = false
        logMessage("⚠️ Reset isLoading", level: .debug)
        
        logMessage("⚠️ State cleanup completed", level: .debug)
    }
    
    /// Update method to make refreshing data more controlled with better
    /// handling of task cancellation and deallocation
    func refreshData() {
        logMessage("⚠️ Manual refresh requested", level: .debug)
        
        // Cancel any existing tasks first
        if let task = currentFetchTask {
            logMessage("⚠️ Cancelling existing task before refresh", level: .debug)
            task.cancel()
            currentFetchTask = nil
        }
        
        // Check deallocation state immediately before starting a new task
        guard !isBeingDeallocated else {
            logMessage("⚠️ View model is being deallocated, skipping refresh", level: .debug)
            return
        }
        
        // FIXED: Use weak self to prevent retain cycle
        Task(priority: .userInitiated) { [weak self] in 
            guard let self = self else {
                print("⚠️ Self is nil in refreshData Task")
                return
            }
            
            // Double-check deallocation again after task starts
            guard !self.isBeingDeallocated else {
                self.logMessage("⚠️ View model is being deallocated (in task), skipping refresh", level: .debug)
                return
            }
            
            self.logMessage("⚠️ About to call fetchLeaderboardData() from refreshData()", level: .debug)
            await self.fetchLeaderboardData() 
            self.logMessage("⚠️ fetchLeaderboardData() completed", level: .debug)
        }
    }
    
    // More comprehensive cleanup method that can be called explicitly
    func performCompleteCleanup() {
        if isBeingDeallocated {
            logMessage("⚠️ Already in deallocation process, skipping cleanup", level: .debug)
            return
        }
        
        // Set flag to prevent new operations from starting
        isBeingDeallocated = true
        logMessage("⚠️ Beginning complete cleanup process", level: .debug)
        
        // Cancel any running task immediately
        if let task = currentFetchTask {
            logMessage("⚠️ Found active task, cancelling", level: .debug)
            task.cancel()
            currentFetchTask = nil
            logMessage("⚠️ Task cancelled", level: .debug)
        } else {
            logMessage("⚠️ No active task to cancel", level: .debug)
        }
        
        // Reset state flags
        isDataFetchInProgress = false
        isLoading = false
        
        // Explicitly clear all cancellables to break potential reference cycles
        let cancellablesCount = cancellables.count
        cancellables.removeAll()
        logMessage("⚠️ Cleared \(cancellablesCount) cancellables", level: .debug)
        
        logMessage("⚠️ Complete cleanup finished", level: .debug)
    }
    
    deinit {
        // Set flag to prevent new operations from starting (redundant if performCompleteCleanup was called)
        isBeingDeallocated = true
        
        // Use the non-isolated version since deinit might not always run on the MainActor
        logMessageNonIsolated("⚠️ Deinitializing", level: .debug)
        
        // FIXED: We need to ensure task cancellation is synchronous in deinit
        // Cancel any running task immediately
        if let task = currentFetchTask {
            logMessageNonIsolated("⚠️ Found active task in deinit, cancelling", level: .debug)
            task.cancel()
            currentFetchTask = nil
            logMessageNonIsolated("⚠️ Task cancelled directly in deinit", level: .debug)
        } else {
            logMessageNonIsolated("⚠️ No active task to cancel in deinit", level: .debug)
        }
        
        // Explicitly clear all cancellables to break potential reference cycles
        let cancellablesCount = cancellables.count
        cancellables.removeAll()
        logMessageNonIsolated("⚠️ Cleared \(cancellablesCount) cancellables in deinit", level: .debug)
        
        logMessageNonIsolated("⚠️ Deinit complete", level: .debug)
    }

    // Handle location permission for local board
    private func handleLocalLocationPermission() {
        logMessage("⚠️ Handling location permissions", level: .debug)
        isLoading = false
        leaderboardEntries = []
        if locationPermissionStatus == .notDetermined {
            logMessage("⚠️ Location permission not determined, requesting", level: .debug)
            errorMessage = "Location permission is needed for local leaderboards."
            locationService.requestLocationPermission()
        } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
            logMessage("⚠️ Location permission denied/restricted", level: .debug)
            errorMessage = "Location access denied. Please enable it in Settings to use local leaderboards."
        }
    }
}