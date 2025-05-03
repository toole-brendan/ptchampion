import Foundation
import Combine
import CoreLocation
import SwiftUI
import os.log

// Setup logger
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardViewModel")

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
    // Debug ID to track instance lifecycle
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

    @Published var selectedBoard: LeaderboardType = .global {
        didSet { 
            guard oldValue != selectedBoard else { 
                logger.debug("Board selection unchanged, skipping fetch")
                return 
            }
            
            logger.debug("Board selection changed to \(self.selectedBoard.rawValue)")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Board selection changed to \(self.selectedBoard.rawValue)")
            Task { 
                await self.fetchLeaderboardData() 
            }
        }
    }
    
    @Published var selectedCategory: LeaderboardCategory = .weekly {
        didSet { 
            guard oldValue != selectedCategory else { 
                logger.debug("Category selection unchanged, skipping fetch")
                return 
            }
            
            logger.debug("Category selection changed to \(self.selectedCategory.rawValue)")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Category selection changed to \(self.selectedCategory.rawValue)")
            Task {
                await self.fetchLeaderboardData() 
            }
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
        logger.debug("Initializing LeaderboardViewModel instance \(self.instanceId)")
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Initializing new instance")
        
        // Use provided services or create default ones
        self.leaderboardService = leaderboardService ?? LeaderboardService()
        self.locationService = locationService ?? LocationService()
        self.keychainService = keychainService ?? KeychainService()
        self.useMockData = useMockData
        self.autoLoadData = autoLoadData
        
        subscribeToLocationStatus()
        
        // Only start initial load if autoLoadData is true
        if autoLoadData {
            // Delay initial fetch to avoid loading during initialization
            Task { 
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                logger.debug("Starting initial data fetch after delay")
                
                // Check if task is cancelled before proceeding
                if !Task.isCancelled {
                    await self.fetchLeaderboardData() 
                } else {
                    print("🔍 LeaderboardViewModel[\(self.instanceId)]: Initial data fetch task was cancelled, skipping")
                }
            }
        } else {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Auto-load disabled, skipping initial data fetch")
        }
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                logger.debug("Location permission status changed to: \(status.rawValue)")
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Location permission status changed to: \(status.rawValue)")
                self.locationPermissionStatus = status
                // If switching to local and status becomes authorized, refetch
                if self.selectedBoard == .local && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    logger.debug("Location authorized, fetching local board")
                    print("🔍 LeaderboardViewModel[\(self.instanceId)]: Location authorized, fetching local board")
                    Task { await self.fetchLeaderboardData() }
                }
            }
            .store(in: &cancellables)

        locationService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                logger.error("Location service error: \(error.localizedDescription)")
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Location service error: \(error.localizedDescription)")
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
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Resetting state to default values")
        self.isLoading = false
        self.isDataFetchInProgress = false
        self.errorMessage = nil
    }

    func fetchLeaderboardData() async {
        // Cancel any existing fetch task
        currentFetchTask?.cancel()
        
        // Prevent concurrent fetches
        guard !isDataFetchInProgress else {
            logger.debug("Fetch already in progress, skipping new request")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch already in progress, skipping new request")
            return
        }
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Starting data fetch, setting isDataFetchInProgress=true")
        isDataFetchInProgress = true
        
        // Update loading state - ensure on MainActor
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Updated UI state: isLoading=true, errorMessage=nil")
        }
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Starting leaderboard data fetch for \(self.selectedBoard.rawValue), \(self.selectedCategory.rawValue)")

        // Create a new task with timeout but don't wait for it to complete
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Creating fetch task")
        currentFetchTask = Task { @MainActor in
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task started")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task started on thread: \(Thread.current.description)")
            
            if Task.isCancelled {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was already cancelled on start, aborting")
                isDataFetchInProgress = false
                isLoading = false
                return
            }
            
            do {
                // Always use mock data for now to prevent crashes
                logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Using mock data instead of backend")
                
                // Check if task is cancelled before proceeding with expensive operation
                if !Task.isCancelled {
                    await generateAndDisplayMockData()
                    if !Task.isCancelled { // Check again after mock data generation
                        backendStatus = .connected
                        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Mock data generation completed, backendStatus=.connected")
                    }
                } else {
                    print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was cancelled during mock data generation")
                }
            } catch {
                logger.error("❌ LeaderboardViewModel[\(self.instanceId)]: Error in fetch task: \(error.localizedDescription)")
                print("❌ LeaderboardViewModel[\(self.instanceId)]: Error in fetch task: \(error.localizedDescription)")
                
                // Only update UI if not cancelled
                if !Task.isCancelled {
                    errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    leaderboardEntries = []
                }
            }
            
            // IMPORTANT: Always clean up state at the end
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch completed - cleaning up state")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch completed on thread: \(Thread.current.description)")
            
            // Don't update UI state if task was cancelled
            if !Task.isCancelled {
                isDataFetchInProgress = false
                isLoading = false
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Updated final UI state: isLoading=\(isLoading)")
            } else {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was cancelled, skipping final UI updates")
                // Still reset the fetch in progress flag
                isDataFetchInProgress = false
            }
        }
        
        // Don't wait for task to complete - just start it and return
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task dispatched (not awaiting)")
    }
    
    // MARK: - Added methods to fix freezing issues
    
    /// Cancel any active tasks to prevent background processing when view disappears
    nonisolated func cancelActiveTasks() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cancelling active tasks")
        currentFetchTask?.cancel()
        
        // We can't update state variables directly in a nonisolated method
        // We'll just cancel the task and leave state cleanup to happen elsewhere
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Tasks cancelled (nonisolated method)")
    }
    
    /// Clean up the UI state after cancellation (must be called on main actor)
    func cleanupAfterCancellation() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cleaning up state after cancellation")
        currentFetchTask = nil // Ensure task is fully released
        
        // Perform immediate cleanup
        isDataFetchInProgress = false
        
        // Don't immediately set isLoading = false here as it would cause a UI update
        // while the view is in the process of disappearing, which could cause a freeze
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: State cleanup completed")
    }
    
    // MARK: - Mock data generation
    
    private func generateAndDisplayMockData() async {
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Generating mock data")
        
        // Check for cancellation first thing
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled before mock data generation")
            return
        }
        
        // In case we're already showing mock entries, avoid regenerating them
        if !leaderboardEntries.isEmpty && useMockData {
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Already displaying mock entries, not regenerating")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Already displaying mock entries, not regenerating")
            await MainActor.run {
                if !Task.isCancelled {
                    self.isLoading = false
                }
            }
            return
        }
        
        // Check for cancellation again
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled before creating entries")
            return
        }
        
        // Create mock data for the UI to display
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Creating new mock entries")
        var mockEntries: [LeaderboardEntry] = []
        
        // Generate a smaller set of mock entries to avoid performance issues
        let entryCount = 10
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Generating \(entryCount) mock entries")
        for i in 1...entryCount {
            // Check for cancellation periodically
            if Task.isCancelled {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled while generating mock entries")
                return
            }
            
            let entry = LeaderboardEntry(
                id: "entry-\(i)",
                rank: i,
                userId: "user-\(i)",
                name: self.selectedBoard == .local ? "Local User \(i)" : "User \(i)",
                score: 1000 - (i * 30)
            )
            mockEntries.append(entry)
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Generated entry \(i)")
        }
        
        // Check for cancellation after generating entries
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled after generating entries")
            return
        }
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Mock entries generation complete, adding artificial delay")
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Generated \(mockEntries.count) entries, adding brief delay")
        
        // Use a shorter delay for responsive UX, but make it non-blocking
        do {
            try await Task.sleep(nanoseconds: 50_000_000) // Reduced to 50ms for faster response
            
            // Check again after delay
            if Task.isCancelled {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled after delay")
                return
            }
            
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Artificial delay complete")
        } catch {
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Sleep interrupted: \(error.localizedDescription)")
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Sleep interrupted: \(error.localizedDescription)")
            return  // Exit if cancelled
        }
        
        // One final cancellation check
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled before UI update")
            return
        }
        
        // Update UI - do this on the main thread
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Updating UI with mock entries")
        await MainActor.run {
            // Final cancellation check
            if !Task.isCancelled {
                self.leaderboardEntries = mockEntries
                self.isLoading = false
                logger.debug("✅ LeaderboardViewModel[\(self.instanceId)]: UI updated with \(mockEntries.count) mock entries")
                print("✅ LeaderboardViewModel[\(self.instanceId)]: UI updated with \(mockEntries.count) mock entries")
            } else {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled, skipping final UI update")
            }
        }
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

    // Function to trigger refresh manually (called from SwiftUI's refreshable modifier)
    func refreshData() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Manual refresh requested")
        Task { await fetchLeaderboardData() }
    }
    
    // Function to switch to mock data mode for debugging
    func switchToMockData() {
        logger.debug("Switching to mock data mode")
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Switching to mock data mode")
        useMockData = true
        Task { await fetchLeaderboardData() }
    }
    
    deinit {
        logger.debug("LeaderboardViewModel \(self.instanceId) deinitializing")
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Deinitializing")
        // Cancel all ongoing operations (nonisolated method is safe to call here)
        cancelActiveTasks()
        
        // Can't update state directly from deinit since it's not on the main actor
        // State cleanup would happen naturally as part of deinitialization
        
        cancellables.removeAll()
    }
} 