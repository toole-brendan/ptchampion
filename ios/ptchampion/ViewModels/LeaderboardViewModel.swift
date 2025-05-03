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
    let name: String
    let score: Int
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
    
    // Default to having mock data available for preview/testing
    private var useMockData = true
    
    // Whether to automatically load data on init
    private var autoLoadData = false
    
    // Set a reasonable timeout for network operations
    private let networkTimeoutSeconds: TimeInterval = 10.0
    
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
                logMessage("Board selection unchanged, skipping fetch")
                return 
            }
            
            logMessage("Board selection changed to \(self.selectedBoard.rawValue)")
            
            // Use a more controlled approach to trigger data fetch
            refreshData()
        }
    }
    
    @Published var selectedCategory: LeaderboardCategory = .weekly {
        didSet { 
            guard oldValue != selectedCategory else { 
                logMessage("Category selection unchanged, skipping fetch")
                return 
            }
            
            logMessage("Category selection changed to \(self.selectedCategory.rawValue)")
            
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
        logMessage("Initializing LeaderboardViewModel instance \(self.instanceId)")
        
        subscribeToLocationStatus()
        
        // Only start initial load if autoLoadData is true
        if autoLoadData {
            // Don't start loading immediately, wait for a delay
            // This prevents loading during initialization which can cause UI freezes
            logMessage("Auto-load enabled, scheduling delayed data fetch")
            
            // FIXED: Use weak self to prevent retain cycle
            Task { [weak self] in 
                guard let self = self else { 
                    print("DEBUG-TASK: Self is nil in initial load task")
                    return 
                }
                
                self.logMessage("DEBUG: Initial data load task started - before sleep")
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                self.logMessage("DEBUG: Initial data load task - after sleep")
                
                // Check if task is cancelled or view model is being deallocated
                if !Task.isCancelled && !self.isBeingDeallocated {
                    self.logMessage("Starting initial data fetch after delay")
                    await self.fetchLeaderboardData() 
                } else {
                    self.logMessage("Initial data fetch task was cancelled, skipping")
                }
            }
        } else {
            logMessage("Auto-load disabled, skipping initial data fetch")
        }
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.logMessage("Location permission status changed to: \(status.rawValue)")
                self.locationPermissionStatus = status
                // If switching to local and status becomes authorized, refetch
                if self.selectedBoard == .local && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    self.logMessage("Location authorized, fetching local board")
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
        logMessage("Resetting state to default values")
        self.isLoading = false
        self.isDataFetchInProgress = false
        self.errorMessage = nil
    }

    func fetchLeaderboardData() async {
        logMessage("⏱️ FETCH START: fetchLeaderboardData called")
        
        // Cancel any existing fetch task first to prevent multiple concurrent fetches
        if let task = currentFetchTask {
            logMessage("⏱️ Cancelling existing task")
            task.cancel()
            currentFetchTask = nil
            logMessage("⏱️ Existing task cancelled")
        }
        
        // Prevent concurrent fetches
        guard !isDataFetchInProgress else {
            logMessage("Fetch already in progress, skipping new request")
            return
        }
        
        // Check if we're in the process of deinitializing
        guard !isBeingDeallocated else {
            logMessage("View model is being deallocated, aborting fetch")
            return
        }
        
        logMessage("⏱️ Starting data fetch, setting isDataFetchInProgress=true")
        isDataFetchInProgress = true
        
        // Update loading state - we're already on MainActor since the class is annotated
        self.isLoading = true
        self.errorMessage = nil
        logMessage("⏱️ Updated UI state: isLoading=true, errorMessage=nil")
        
        logMessage("⏱️ Starting leaderboard data fetch for \(self.selectedBoard.rawValue), \(self.selectedCategory.rawValue)")

        // Create a new task with timeout but don't wait for it to complete
        logMessage("⏱️ Creating fetch task")
        
        // FIXED: Create a separate instance of selectedBoard to capture for the task
        // to avoid capturing self directly
        let selectedBoardType = self.selectedBoard
        let selectedCategoryType = self.selectedCategory
        let instanceIdCopy = self.instanceId
        
        // Create a weak reference to self to avoid retain cycles
        weak var weakSelf = self
        
        // Store reference to task so we can cancel it later if needed
        let taskStartTime = Date()
        currentFetchTask = Task { 
            // Use the nonisolated logging function from a non-actor-isolated context
            let nonIsolatedLog: (String, OSLogType) -> Void = { message, level in
                // Local function to log without capturing self
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss.SSS"
                let timeStr = formatter.string(from: Date())
                
                let elapsed = Date().timeIntervalSince(taskStartTime)
                let elapsedStr = String(format: "%.3fs", elapsed)
                
                let prefix = "🔍 LeaderboardViewModel[\(instanceIdCopy)]:"
                let timePrefix = "[\(timeStr)]"
                print("\(timePrefix) \(prefix) ⏱️ \(elapsedStr) - \(message) [Thread: \(Thread.current.description)]")
                
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
            
            nonIsolatedLog("⚠️ Fetch task started on thread: \(Thread.current.description)", .debug)
            
            // Check for cancellation immediately
            if Task.isCancelled {
                nonIsolatedLog("Task was already cancelled on start, aborting", .debug)
                await MainActor.run {
                    // Safely use weakSelf
                    nonIsolatedLog("Setting flags on MainActor after early cancellation", .debug)
                    weakSelf?.isDataFetchInProgress = false
                    weakSelf?.isLoading = false
                    nonIsolatedLog("Flags updated on MainActor after early cancellation", .debug)
                }
                return
            }
            
            do {
                // Check for cancellation again
                if Task.isCancelled {
                    nonIsolatedLog("Task cancelled while generating entries", .debug)
                    await MainActor.run {
                        nonIsolatedLog("Setting flags on MainActor after cancellation", .debug)
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                        nonIsolatedLog("Flags updated on MainActor after cancellation", .debug)
                    }
                    return
                }
                
                // Always use mock data for now to prevent crashes
                nonIsolatedLog("Using mock data instead of backend", .debug)
                
                // Generate mock entries - this is a non-isolated function
                var entries: [LeaderboardEntry] = []
                
                // FIXED: Generate mock data without capturing self
                // Generate entries locally within the task
                let entryCount = 10
                nonIsolatedLog("⚠️ Starting mock data generation loop for \(entryCount) entries", .debug)
                
                for i in 1...entryCount {
                    // Check for cancellation inside the loop
                    if Task.isCancelled {
                        nonIsolatedLog("⚠️ Task cancelled during entry creation loop at i=\(i)", .debug)
                        await MainActor.run {
                            nonIsolatedLog("Setting flags on MainActor after loop cancellation", .debug)
                            weakSelf?.isDataFetchInProgress = false
                            weakSelf?.isLoading = false
                            nonIsolatedLog("Flags updated after loop cancellation", .debug)
                        }
                        return
                    }
                    
                    nonIsolatedLog("⚠️ Creating mock entry \(i) of \(entryCount)", .debug)
                    
                    // Create entries based on the captured board type (not self)
                    let entry = LeaderboardEntry(
                        id: "entry-\(i)",
                        rank: i,
                        userId: "user-\(i)",
                        name: selectedBoardType == .local ? "Local User \(i)" : "User \(i)",
                        score: 1000 - (i * 30)
                    )
                    entries.append(entry)
                    
                    // Add a tiny delay to simulate work happening
                    // This is not needed in production, just for debugging
                    #if DEBUG
                    do {
                        nonIsolatedLog("⚠️ Before sleep for entry \(i)", .debug)
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        nonIsolatedLog("⚠️ After sleep for entry \(i)", .debug)
                    } catch {
                        nonIsolatedLog("⚠️ Sleep interrupted: \(error.localizedDescription)", .debug)
                        break
                    }
                    #endif
                }
                
                nonIsolatedLog("⚠️ Generated \(entries.count) mock entries", .debug)
                
                // Final cancellation check
                if Task.isCancelled {
                    nonIsolatedLog("⚠️ Task cancelled after entries generation", .debug)
                    await MainActor.run {
                        nonIsolatedLog("Setting flags on MainActor after final cancellation check", .debug)
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                        nonIsolatedLog("Flags updated on MainActor after final cancellation check", .debug)
                    }
                    return
                }
                
                // Update UI state on the main thread
                nonIsolatedLog("⚠️ About to update UI on main thread", .debug)
                await MainActor.run {
                    nonIsolatedLog("⚠️ Now on MainActor for UI update", .debug)
                    
                    // Make sure we still have a valid instance and task isn't cancelled
                    guard let self = weakSelf, !Task.isCancelled, !self.isBeingDeallocated else {
                        nonIsolatedLog("⚠️ Self is nil, task cancelled, or being deallocated - skipping UI update", .debug)
                        // If self is gone or task is cancelled, just clear the in-progress flag
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                        nonIsolatedLog("⚠️ Reset flags even though self is gone", .debug)
                        return
                    }
                    
                    // Update the UI state
                    nonIsolatedLog("⚠️ Updating UI state with \(entries.count) entries", .debug)
                    self.leaderboardEntries = entries
                    nonIsolatedLog("⚠️ Updated entries property", .debug)
                    self.backendStatus = .connected
                    nonIsolatedLog("⚠️ Updated backendStatus property", .debug)
                    self.isLoading = false
                    nonIsolatedLog("⚠️ Updated isLoading property", .debug)
                    self.isDataFetchInProgress = false
                    nonIsolatedLog("⚠️ Updated isDataFetchInProgress property", .debug)
                    self.logMessage("⚠️ Updated UI with \(entries.count) mock entries")
                    nonIsolatedLog("⚠️ UI update completed", .debug)
                }
                
                nonIsolatedLog("⚠️ TASK COMPLETED SUCCESSFULLY", .debug)
            } catch {
                nonIsolatedLog("⚠️ Error in fetch task: \(error.localizedDescription)", .error)
                
                // Only update UI if not cancelled and self is still available
                await MainActor.run {
                    nonIsolatedLog("⚠️ On MainActor for error handling", .debug)
                    if !Task.isCancelled, let self = weakSelf, !self.isBeingDeallocated {
                        nonIsolatedLog("⚠️ Updating UI with error", .debug)
                        self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                        self.leaderboardEntries = []
                        self.isLoading = false
                        self.isDataFetchInProgress = false
                        nonIsolatedLog("⚠️ Error UI update completed", .debug)
                    } else {
                        nonIsolatedLog("⚠️ Self is nil in error handler, just resetting flags", .debug)
                        // Still reset state flags even if task is cancelled
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                        nonIsolatedLog("⚠️ Flags reset in error handler", .debug)
                    }
                }
                
                nonIsolatedLog("⚠️ TASK COMPLETED WITH ERROR", .debug)
            }
            
            nonIsolatedLog("⚠️ Task execution finished - final line of task", .debug)
        }
        
        // Don't wait for task to complete - just start it and return
        logMessage("⏱️ Fetch task dispatched (not awaiting)")
    }
    
    // MARK: - Added methods to fix freezing issues
    
    /// Cancel any active tasks to prevent background processing when view disappears
    nonisolated func cancelActiveTasks() {
        // This can be called from any thread
        // Use the nonisolated logging function instead of the isolated one
        logMessageNonIsolated("⚠️ Cancelling active tasks (nonisolated)", .debug)
        
        // Dispatch to main actor to cancel tasks safely
        Task { @MainActor [weak self] in
            guard let self = self else {
                print("⚠️ Self is nil in cancelActiveTasks Task")
                return
            }
            self.logMessage("⚠️ About to call cancelTasksFromMainActor()")
            await self.cancelTasksFromMainActor()
        }
    }
    
    /// MainActor-isolated method that safely cancels tasks
    func cancelTasksFromMainActor() {
        logMessage("⚠️ Cancelling tasks from MainActor")
        
        // Cancel the current fetch task if it exists
        if let task = currentFetchTask {
            logMessage("⚠️ Active fetch task found, cancelling")
            task.cancel()
            logMessage("⚠️ Active fetch task cancelled")
        } else {
            logMessage("⚠️ No active fetch task to cancel")
        }
        
        // Reset the task reference
        currentFetchTask = nil
        logMessage("⚠️ Task reference cleared")
        
        // Ensure we reset the data fetch flag
        isDataFetchInProgress = false
        logMessage("⚠️ isDataFetchInProgress flag reset")
        
        logMessage("⚠️ Tasks cancelled on MainActor")
    }
    
    /// Clean up the UI state after cancellation (must be called on main actor)
    func cleanupAfterCancellation() {
        logMessage("⚠️ Cleaning up state after cancellation")
        
        // Reset all state flags immediately
        isDataFetchInProgress = false
        logMessage("⚠️ Reset isDataFetchInProgress")
        isLoading = false
        logMessage("⚠️ Reset isLoading")
        
        logMessage("⚠️ State cleanup completed")
    }
    
    /// Update method to make refreshing data more controlled
    func refreshData() {
        logMessage("⚠️ Manual refresh requested")
        
        // FIXED: Use weak self to prevent retain cycle
        Task { [weak self] in 
            guard let self = self else {
                print("⚠️ Self is nil in refreshData Task")
                return
            }
            
            guard !self.isBeingDeallocated else {
                self.logMessage("⚠️ View model is being deallocated, skipping refresh")
                return
            }
            
            self.logMessage("⚠️ About to call fetchLeaderboardData() from refreshData()")
            await self.fetchLeaderboardData() 
            self.logMessage("⚠️ fetchLeaderboardData() completed")
        }
    }
    
    deinit {
        // Set flag to prevent new operations from starting
        isBeingDeallocated = true
        
        // Use the non-isolated version since deinit might not always run on the MainActor
        logMessageNonIsolated("⚠️ Deinitializing", .debug)
        
        // FIXED: We need to ensure task cancellation is synchronous in deinit
        // Cancel any running task immediately
        if let task = currentFetchTask {
            logMessageNonIsolated("⚠️ Found active task in deinit, cancelling", .debug)
            task.cancel()
            currentFetchTask = nil
            logMessageNonIsolated("⚠️ Task cancelled directly in deinit", .debug)
        } else {
            logMessageNonIsolated("⚠️ No active task to cancel in deinit", .debug)
        }
        
        // Explicitly clear all cancellables to break potential reference cycles
        let cancellablesCount = cancellables.count
        cancellables.removeAll()
        logMessageNonIsolated("⚠️ Cleared \(cancellablesCount) cancellables in deinit", .debug)
        
        logMessageNonIsolated("⚠️ Deinit complete", .debug)
    }

    // Handle location permission for local board
    private func handleLocalLocationPermission() {
        logMessage("⚠️ Handling location permissions")
        isLoading = false
        leaderboardEntries = []
        if locationPermissionStatus == .notDetermined {
            logMessage("⚠️ Location permission not determined, requesting")
            errorMessage = "Location permission is needed for local leaderboards."
            locationService.requestLocationPermission()
        } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
            logMessage("⚠️ Location permission denied/restricted")
            errorMessage = "Location access denied. Please enable it in Settings to use local leaderboards."
        }
    }
    
    // Function to switch to mock data mode for debugging
    func switchToMockData() {
        logMessage("⚠️ Switching to mock data mode")
        useMockData = true
        refreshData()
    }
}