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
    
    // Set a reasonable timeout for network operations
    private let networkTimeoutSeconds: TimeInterval = 10.0

    @Published var selectedBoard: LeaderboardType = .global {
        didSet { 
            logger.debug("Board selection changed to \(self.selectedBoard.rawValue)")
            Task { 
                await self.fetchLeaderboardData() 
            }
        }
    }
    
    @Published var selectedCategory: LeaderboardCategory = .weekly {
        didSet { 
            logger.debug("Category selection changed to \(self.selectedCategory.rawValue)")
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
         useMockData: Bool = false) {
        logger.debug("Initializing LeaderboardViewModel instance \(self.instanceId)")
        
        // Use provided services or create default ones
        self.leaderboardService = leaderboardService ?? LeaderboardService()
        self.locationService = locationService ?? LocationService()
        self.keychainService = keychainService ?? KeychainService()
        self.useMockData = useMockData
        
        subscribeToLocationStatus()
        
        // Delay initial fetch to avoid loading during initialization
        Task { 
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
            logger.debug("Starting initial data fetch after delay")
            await self.fetchLeaderboardData() 
        }
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                logger.debug("Location permission status changed to: \(status.rawValue)")
                self.locationPermissionStatus = status
                // If switching to local and status becomes authorized, refetch
                if self.selectedBoard == .local && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    logger.debug("Location authorized, fetching local board")
                    Task { await self.fetchLeaderboardData() }
                }
            }
            .store(in: &cancellables)

        locationService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                logger.error("Location service error: \(error.localizedDescription)")
                if self.selectedBoard == .local {
                    self.errorMessage = "Could not get location for local leaderboard: \(error.localizedDescription)"
                    self.leaderboardEntries = [] // Clear entries if location fails
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    func fetchLeaderboardData() async {
        // Cancel any existing fetch task
        currentFetchTask?.cancel()
        
        // Prevent concurrent fetches
        guard !isDataFetchInProgress else {
            logger.debug("Fetch already in progress, skipping new request")
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
            
            do {
                // Always use mock data for now to prevent crashes
                logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Using mock data instead of backend")
                await generateAndDisplayMockData()
                backendStatus = .connected
                logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Mock data generation completed, backendStatus=.connected")
            } catch {
                logger.error("❌ LeaderboardViewModel[\(self.instanceId)]: Error in fetch task: \(error.localizedDescription)")
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                leaderboardEntries = []
            }
            
            // IMPORTANT: Always clean up state at the end
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch completed - cleaning up state")
            isDataFetchInProgress = false
            isLoading = false
        }
        
        // Don't wait for task to complete - just start it and return
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Fetch task dispatched (not awaiting)")
    }
    
    private func generateAndDisplayMockData() async {
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Generating mock data")
        
        // In case we're already showing mock entries, avoid regenerating them
        if !leaderboardEntries.isEmpty && useMockData {
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Already displaying mock entries, not regenerating")
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        // Create mock data for the UI to display
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Creating new mock entries")
        var mockEntries: [LeaderboardEntry] = []
        
        // Generate a smaller set of mock entries to avoid performance issues
        let entryCount = 10
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Generating \(entryCount) mock entries")
        for i in 1...entryCount {
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
        
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Mock entries generation complete, adding artificial delay")
        
        // Use a shorter delay for responsive UX
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second - reduced from 0.2s
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Artificial delay complete")
        } catch {
            logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Sleep interrupted: \(error.localizedDescription)")
        }
        
        // Update UI - do this on the main thread
        logger.debug("🔍 LeaderboardViewModel[\(self.instanceId)]: Updating UI with mock entries")
        await MainActor.run {
            self.leaderboardEntries = mockEntries
            self.isLoading = false
            logger.debug("✅ LeaderboardViewModel[\(self.instanceId)]: UI updated with \(mockEntries.count) mock entries")
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
        Task { await fetchLeaderboardData() }
    }
    
    // Function to switch to mock data mode for debugging
    func switchToMockData() {
        logger.debug("Switching to mock data mode")
        useMockData = true
        Task { await fetchLeaderboardData() }
    }
    
    deinit {
        logger.debug("LeaderboardViewModel \(self.instanceId) deinitializing")
        currentFetchTask?.cancel()
        cancellables.removeAll()
    }
} 