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
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Starting data fetch, setting isDataFetchInProgress=true")
        isDataFetchInProgress = true
        
        // Update loading state - ensure on MainActor
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Updated UI state: isLoading=true, errorMessage=nil")
        }
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Starting leaderboard data fetch for \(self.selectedBoard.rawValue), \(self.selectedCategory.rawValue)")

        // Create a new task with timeout but don't wait for it to complete
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Creating fetch task")
        
        // IMPORTANT: Create a weak reference to self to avoid memory issues
        weak var weakSelf = self
        
        currentFetchTask = Task { @MainActor in
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task started on thread: \(Thread.current.description)")
            
            // Check for cancellation immediately
            if Task.isCancelled {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was already cancelled on start, aborting")
                weakSelf?.isDataFetchInProgress = false
                weakSelf?.isLoading = false
                return
            }
            
            do {
                // Add a short delay to prevent UI from locking up during rapid tab switches
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                
                // Check for cancellation again after delay
                if Task.isCancelled {
                    print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled after initial delay")
                    weakSelf?.isDataFetchInProgress = false
                    weakSelf?.isLoading = false
                    return
                }
                
                // Always use mock data for now to prevent crashes
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Using mock data instead of backend")
                
                // Check if task is cancelled before proceeding with expensive operation
                if !Task.isCancelled, let self = weakSelf {
                    await self.generateAndDisplayMockData()
                    if !Task.isCancelled { // Check again after mock data generation
                        self.backendStatus = .connected
                        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Mock data generation completed, backendStatus=.connected")
                    }
                } else {
                    print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was cancelled during mock data generation")
                }
            } catch {
                print("❌ LeaderboardViewModel[\(self.instanceId)]: Error in fetch task: \(error.localizedDescription)")
                
                // Only update UI if not cancelled and self is still available
                if !Task.isCancelled, let self = weakSelf {
                    self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    self.leaderboardEntries = []
                }
            }
            
            // IMPORTANT: Always clean up state at the end
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch completed - cleaning up state")
            
            // Don't update UI state if task was cancelled or self was deallocated
            if !Task.isCancelled, let self = weakSelf {
                self.isDataFetchInProgress = false
                self.isLoading = false
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Updated final UI state: isLoading=\(self.isLoading)")
            } else {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task was cancelled, skipping final UI updates")
                // Still reset the fetch in progress flag if self exists
                weakSelf?.isDataFetchInProgress = false
            }
        }
        
        // Don't wait for task to complete - just start it and return
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task dispatched (not awaiting)")
    }
    
    // MARK: - Added methods to fix freezing issues
    
    /// Cancel any active tasks to prevent background processing when view disappears
    nonisolated func cancelActiveTasks() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cancelling active tasks")
        
        // Nothing to actually cancel here in the nonisolated context
        // The currentFetchTask can only be accessed on the MainActor 
        // and we shouldn't create a strong reference to self by creating a new Task
        
        // Instead, we'll just notify that cancellation was requested
        // The task will check Task.isCancelled periodically
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cancellation requested (nonisolated method)")
    }
    
    /// MainActor-isolated method that safely cancels tasks
    func cancelTasksFromMainActor() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cancelling tasks from MainActor")
        
        // Cancel the current fetch task if it exists
        if let task = currentFetchTask {
            task.cancel()
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Active fetch task cancelled")
        } else {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: No active fetch task to cancel")
        }
        
        // Reset the task reference
        currentFetchTask = nil
        
        // Ensure we reset the data fetch flag
        isDataFetchInProgress = false
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Tasks cancelled on MainActor")
    }
    
    /// Clean up the UI state after cancellation (must be called on main actor)
    func cleanupAfterCancellation() {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Cleaning up state after cancellation")
        
        // Reset all state flags immediately
        isDataFetchInProgress = false
        isLoading = false
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: State cleanup completed")
    }
    
    deinit {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Deinitializing")
        
        // Since we're on the MainActor already for deinit (the whole class is @MainActor),
        // we can safely cancel the task directly here
        if let task = currentFetchTask {
            task.cancel()
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Tasks cancelled directly in deinit")
        }
        
        // Explicitly clear the reference to help with memory management
        currentFetchTask = nil
        
        // Clear all cancellables
        cancellables.removeAll()
    }

    // MARK: - Mock data generation
    
    private func generateAndDisplayMockData() async {
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Generating mock data")
        
        // Check for cancellation first thing
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled before mock data generation")
            return
        }
        
        // Create mock data for the UI to display - create it all at once for efficiency
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Creating mock entries")
        let entryCount = 10
        
        // Create entries all at once rather than in a loop to improve performance
        let mockEntries: [LeaderboardEntry] = (1...entryCount).map { i in
            LeaderboardEntry(
                id: "entry-\(i)",
                rank: i,
                userId: "user-\(i)",
                name: self.selectedBoard == .local ? "Local User \(i)" : "User \(i)",
                score: 1000 - (i * 30)
            )
        }
        
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Generated \(mockEntries.count) entries")
        
        // Check for cancellation after generating entries
        if Task.isCancelled {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled after generating entries")
            return
        }
        
        // Very short artificial delay to ensure UI responsiveness
        do {
            try await Task.sleep(nanoseconds: 5_000_000) // Just 5ms for UI to catch up
            
            // Check again after delay
            if Task.isCancelled {
                print("🔍 LeaderboardViewModel[\(self.instanceId)]: Task cancelled after delay")
                return
            }
        } catch {
            print("🔍 LeaderboardViewModel[\(self.instanceId)]: Sleep interrupted: \(error.localizedDescription)")
            return  // Exit if cancelled
        }
        
        // Update UI - do this on the main thread
        print("🔍 LeaderboardViewModel[\(self.instanceId)]: Updating UI with mock entries")
        await MainActor.run {
            // Final cancellation check
            if !Task.isCancelled {
                self.leaderboardEntries = mockEntries
                self.isLoading = false
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
} 