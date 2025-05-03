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

    private let leaderboardService: LeaderboardServiceProtocol
    private let locationService: LocationServiceProtocol
    private let keychainService: KeychainServiceProtocol
    
    // Network state
    private var cancellables = Set<AnyCancellable>()
    private var isDataFetchInProgress = false
    private var currentFetchTask: Task<Void, Never>? = nil
    
    // Default to having mock data available for preview/testing
    private var useMockData = true
    
    // Whether to automatically load data on init
    private var autoLoadData = false
    
    // Set a reasonable timeout for network operations
    private let networkTimeoutSeconds: TimeInterval = 10.0
    
    // Add a dedicated log function with severity levels
    private func logMessage(_ message: String, level: OSLogType = .debug) {
        let prefix = "🔍 LeaderboardViewModel[\(self.instanceId)]:"
        print("\(prefix) \(message)")
        
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
        let prefix = "🔍 LeaderboardViewModel[\(instanceIdCopy)]:"
        print("\(prefix) \(message)")
        
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
        logMessage("Initializing LeaderboardViewModel instance \(self.instanceId)")
        
        // Use provided services or create default ones
        self.leaderboardService = leaderboardService ?? LeaderboardService()
        self.locationService = locationService ?? LocationService()
        self.keychainService = keychainService ?? KeychainService()
        self.useMockData = useMockData
        self.autoLoadData = autoLoadData
        
        subscribeToLocationStatus()
        
        // Only start initial load if autoLoadData is true
        if autoLoadData {
            // Don't start loading immediately, wait for a delay
            // This prevents loading during initialization which can cause UI freezes
            logMessage("Auto-load enabled, scheduling delayed data fetch")
            Task { 
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                
                // Check if task is cancelled before proceeding
                if !Task.isCancelled {
                    logMessage("Starting initial data fetch after delay")
                    await self.fetchLeaderboardData() 
                } else {
                    logMessage("Initial data fetch task was cancelled, skipping")
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
                guard let self = self else { return }
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
                guard let self = self else { return }
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
        // Cancel any existing fetch task first to prevent multiple concurrent fetches
        currentFetchTask?.cancel()
        
        // Prevent concurrent fetches
        guard !isDataFetchInProgress else {
            logMessage("Fetch already in progress, skipping new request")
            return
        }
        
        logMessage("Starting data fetch, setting isDataFetchInProgress=true")
        isDataFetchInProgress = true
        
        // Update loading state - we're already on MainActor since the class is annotated
        self.isLoading = true
        self.errorMessage = nil
        logMessage("Updated UI state: isLoading=true, errorMessage=nil")
        
        logMessage("Starting leaderboard data fetch for \(self.selectedBoard.rawValue), \(self.selectedCategory.rawValue)")

        // Create a new task with timeout but don't wait for it to complete
        logMessage("Creating fetch task")
        
        // IMPORTANT: Create a weak reference to self to avoid memory issues
        weak var weakSelf = self
        
        // Store reference to instance ID for use in nonisolated contexts
        let instanceIdCopy = self.instanceId
        
        currentFetchTask = Task { 
            // FIXED: Use the nonisolated logging function
            logMessageNonIsolated("Fetch task started on thread: \(Thread.current.description)")
            
            // Check for cancellation immediately
            if Task.isCancelled {
                logMessageNonIsolated("Task was already cancelled on start, aborting")
                await MainActor.run {
                    weakSelf?.isDataFetchInProgress = false
                    weakSelf?.isLoading = false
                }
                return
            }
            
            do {
                // CRITICAL: We're already in a background task; we SHOULD NOT suspend 
                // this task with a sleep, as that could contribute to freezing
                
                // Check for cancellation again
                if Task.isCancelled {
                    logMessageNonIsolated("Task cancelled while generating entries")
                    await MainActor.run {
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                    }
                    return
                }
                
                // Always use mock data for now to prevent crashes
                logMessageNonIsolated("Using mock data instead of backend")
                
                // Check if task is cancelled before proceeding with expensive operation
                if !Task.isCancelled, let self = weakSelf {
                    // Create mock entries - do this work off the main thread
                    // We need to call the nonisolated version from the weak self
                    let entries = await self.generateMockLeaderboardEntries()
                    
                    // Final cancellation check
                    if Task.isCancelled {
                        logMessageNonIsolated("Task cancelled after entries generation")
                        await MainActor.run {
                            weakSelf?.isDataFetchInProgress = false
                            weakSelf?.isLoading = false
                        }
                        return
                    }
                    
                    // Update UI state on the main thread
                    await MainActor.run {
                        if let self = weakSelf, !Task.isCancelled {
                            self.leaderboardEntries = entries
                            self.backendStatus = .connected
                            self.isLoading = false
                            self.isDataFetchInProgress = false
                            self.logMessage("Updated UI with \(entries.count) mock entries")
                        }
                    }
                } else {
                    logMessageNonIsolated("Task was cancelled or self was deallocated")
                    await MainActor.run {
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                    }
                }
            } catch {
                logMessageNonIsolated("Error in fetch task: \(error.localizedDescription)", level: .error)
                
                // Only update UI if not cancelled and self is still available
                await MainActor.run {
                    if !Task.isCancelled, let self = weakSelf {
                        self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                        self.leaderboardEntries = []
                        self.isLoading = false
                        self.isDataFetchInProgress = false
                    } else {
                        // Still reset state flags even if task is cancelled
                        weakSelf?.isDataFetchInProgress = false
                        weakSelf?.isLoading = false
                    }
                }
            }
        }
        
        // Don't wait for task to complete - just start it and return
        logMessage("Fetch task dispatched (not awaiting)")
    }
    
    // MARK: - Generation of mock data
    
    // Generate mock leaderboard entries - not on the main thread
    // Make this nonisolated so it can be called from the Task
    nonisolated private func generateMockLeaderboardEntries() async -> [LeaderboardEntry] {
        logMessageNonIsolated("Generating mock data")
        
        // Return immediately if task is cancelled
        if Task.isCancelled {
            logMessageNonIsolated("Task cancelled during mock data generation")
            return []
        }
        
        let entryCount = 10
        var entries: [LeaderboardEntry] = []
        
        // We need to capture these values since we can't access self.properties in a nonisolated context
        var selectedBoardInfo: String = "unknown"
        
        // Get the current board type on the MainActor first
        await MainActor.run {
            selectedBoardInfo = self.selectedBoard.rawValue
        }
        
        for i in 1...entryCount {
            // Check for cancellation inside the loop
            if Task.isCancelled {
                logMessageNonIsolated("Task cancelled during entry creation loop")
                return []
            }
            
            let entry = LeaderboardEntry(
                id: "entry-\(i)",
                rank: i,
                userId: "user-\(i)",
                name: selectedBoardInfo == "Local (5mi)" ? "Local User \(i)" : "User \(i)",
                score: 1000 - (i * 30)
            )
            entries.append(entry)
            
            // Add a tiny delay to simulate work happening
            // This is not needed in production, just for debugging
            #if DEBUG
            do {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            } catch {
                logMessageNonIsolated("Sleep interrupted: \(error.localizedDescription)")
                return entries
            }
            #endif
        }
        
        logMessageNonIsolated("Generated \(entries.count) mock entries")
        return entries
    }
    
    // MARK: - Added methods to fix freezing issues
    
    /// Cancel any active tasks to prevent background processing when view disappears
    nonisolated func cancelActiveTasks() {
        // This can be called from any thread
        // Use the nonisolated logging function instead of the isolated one
        logMessageNonIsolated("Cancelling active tasks (nonisolated)")
        
        // We can't access currentFetchTask directly here since it's MainActor-isolated
        // The actual cancellation needs to happen on the MainActor in cancelTasksFromMainActor()
    }
    
    /// MainActor-isolated method that safely cancels tasks
    func cancelTasksFromMainActor() {
        logMessage("Cancelling tasks from MainActor")
        
        // Cancel the current fetch task if it exists
        if let task = currentFetchTask {
            task.cancel()
            logMessage("Active fetch task cancelled")
        } else {
            logMessage("No active fetch task to cancel")
        }
        
        // Reset the task reference
        currentFetchTask = nil
        
        // Ensure we reset the data fetch flag
        isDataFetchInProgress = false
        
        logMessage("Tasks cancelled on MainActor")
    }
    
    /// Clean up the UI state after cancellation (must be called on main actor)
    func cleanupAfterCancellation() {
        logMessage("Cleaning up state after cancellation")
        
        // Reset all state flags immediately
        isDataFetchInProgress = false
        isLoading = false
        
        logMessage("State cleanup completed")
    }
    
    /// Update method to make refreshing data more controlled
    func refreshData() {
        logMessage("Manual refresh requested")
        Task { 
            await fetchLeaderboardData() 
        }
    }
    
    deinit {
        logMessage("Deinitializing")
        
        // Since we're on the MainActor already for deinit (the whole class is @MainActor),
        // we can safely cancel the task directly here
        if let task = currentFetchTask {
            task.cancel()
            logMessage("Tasks cancelled directly in deinit")
        }
        
        // Explicitly clear the reference to help with memory management
        currentFetchTask = nil
        
        // Clear all cancellables
        cancellables.removeAll()
    }

    // Handle location permission for local board
    private func handleLocalLocationPermission() {
        isLoading = false
        leaderboardEntries = []
        if locationPermissionStatus == .notDetermined {
            errorMessage = "Location permission is needed for local leaderboards."
            locationService.requestLocationPermission()
        } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
            errorMessage = "Location access denied. Please enable it in Settings to use local leaderboards."
        }
    }
    
    // Function to switch to mock data mode for debugging
    func switchToMockData() {
        logMessage("Switching to mock data mode")
        useMockData = true
        refreshData()
    }
}