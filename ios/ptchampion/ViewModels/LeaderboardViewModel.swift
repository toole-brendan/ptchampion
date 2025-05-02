import Foundation
import Combine
import CoreLocation
import SwiftUI
import os.log

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

// Import the LeaderboardCategory enum
// For now, we're referencing the one from the LeaderboardView file
// In a final implementation, this should be moved to a shared models file
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

// Setup logger
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardViewModel")

// Define minimal protocol requirements to make the file compile
protocol LeaderboardServiceProtocol {
    func fetchGlobalLeaderboard(authToken: String) async throws -> [LeaderboardEntry]
    func fetchLocalLeaderboard(latitude: Double, longitude: Double, radiusMiles: Int, authToken: String) async throws -> [LeaderboardEntry]
}

protocol LocationServiceProtocol {
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var errorPublisher: AnyPublisher<Error, Never> { get }
    func requestLocationPermission()
    func getLastKnownLocation() async -> CLLocation?
    func requestLocationUpdate()
}

protocol KeychainServiceProtocol {
    func getAccessToken() -> String?
}

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

    init(leaderboardService: LeaderboardServiceProtocol = LeaderboardService(),
         locationService: LocationServiceProtocol = LocationService(),
         keychainService: KeychainServiceProtocol = KeychainService(),
         useMockData: Bool = false) {
        logger.debug("Initializing LeaderboardViewModel instance \(self.instanceId)")
        self.leaderboardService = leaderboardService
        self.locationService = locationService
        self.keychainService = keychainService
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
        
        isDataFetchInProgress = true
        isLoading = true
        errorMessage = nil
        
        logger.debug("Starting leaderboard data fetch for \(self.selectedBoard.rawValue), \(self.selectedCategory.rawValue)")

        // Create a new task with timeout
        currentFetchTask = Task {
            // Use async/await with proper error handling and timeout
            do {
                defer {
                    isDataFetchInProgress = false
                    isLoading = false
                }
                
                // If we're in mock mode, just return mock data
                if useMockData {
                    logger.debug("Using mock data instead of backend")
                    await generateAndDisplayMockData()
                    return
                }
                
                // First check if we have a token
                guard let token = keychainService.getAccessToken() else {
                    logger.error("Auth token not available")
                    errorMessage = "Authentication required. Please login again."
                    backendStatus = .connectionFailed("Authentication failed")
                    leaderboardEntries = []
                    return
                }

                logger.debug("Fetching \(self.selectedBoard.rawValue) leaderboard from backend...")
                
                // Create a child task with timeout
                let timeoutNanoseconds = UInt64(networkTimeoutSeconds * 1_000_000_000)
                
                do {
                    // Run the actual API fetch with timeout
                    try await withThrowingTaskGroup(of: [LeaderboardEntry].self) { group in
                        // Add the actual fetch task
                        group.addTask {
                            if self.selectedBoard == .global {
                                return try await self.leaderboardService.fetchGlobalLeaderboard(authToken: token)
                            } else {
                                // Need to capture these values safely before the async operation
                                let permissionStatus = self.locationPermissionStatus
                                // Check location permission - must switch to main actor for this check
                                guard permissionStatus == .authorizedWhenInUse || 
                                      permissionStatus == .authorizedAlways else {
                                    await MainActor.run {
                                        self.handleLocalLocationPermission()
                                    }
                                    return []
                                }
                                
                                guard let location = await self.locationService.getLastKnownLocation() else {
                                    await MainActor.run {
                                        self.errorMessage = "Waiting for location..."
                                    }
                                    return []
                                }
                                
                                return try await self.leaderboardService.fetchLocalLeaderboard(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude,
                                    radiusMiles: self.localRadiusMiles,
                                    authToken: token
                                )
                            }
                        }
                        
                        // Add timeout task
                        group.addTask {
                            try await Task.sleep(nanoseconds: timeoutNanoseconds)
                            logger.error("Network request timed out after \(self.networkTimeoutSeconds) seconds")
                            throw NSError(domain: "LeaderboardViewModel", code: -1001, 
                                          userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
                        }
                        
                        // Wait for first completion (either result or timeout)
                        let entries = try await group.next() ?? []
                        
                        // Cancel other tasks in the group
                        group.cancelAll()
                        
                        // Handle empty result specifically - switch to MainActor to update UI properties
                        await MainActor.run {
                            if entries.isEmpty {
                                logger.debug("Backend returned empty leaderboard (no active users)")
                                self.backendStatus = .noActiveUsers
                                self.errorMessage = "No active users found in the leaderboard yet."
                            } else {
                                logger.debug("Successfully fetched \(entries.count) entries from backend")
                                self.backendStatus = .connected
                            }
                            
                            // Update UI
                            self.leaderboardEntries = entries
                        }
                    }
                } catch {
                    logger.error("Error during fetch: \(error.localizedDescription)")
                    
                    // Special handling for timeout
                    if (error as NSError).code == -1001 {
                        self.backendStatus = .timedOut
                        self.errorMessage = "Connection to the leaderboard server timed out. Please try again later."
                    } else {
                        self.backendStatus = .connectionFailed(error.localizedDescription)
                        self.errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                    }
                    
                    // Fallback to mock data
                    logger.debug("Falling back to mock data after network error")
                    await generateAndDisplayMockData()
                }
            } catch {
                logger.error("Unexpected error in fetch task: \(error.localizedDescription)")
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                leaderboardEntries = []
            }
        }
        
        // Wait for task to complete
        await currentFetchTask?.value
    }
    
    private func generateAndDisplayMockData() async {
        logger.debug("Generating mock data")
        // Create mock data for the UI to display
        var mockEntries: [LeaderboardEntry] = []
        
        for i in 1...20 {
            let entry = LeaderboardEntry(
                id: "entry-\(i)",
                rank: i,
                userId: "user-\(i)",
                name: self.selectedBoard == .local ? "Local User \(i)" : "User \(i)",
                score: 1000 - (i * 30)
            )
            mockEntries.append(entry)
        }
        
        // Simulate network delay for better UX testing
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        } catch {
            logger.debug("Sleep interrupted")
        }
        
        // Update UI
        self.leaderboardEntries = mockEntries
        logger.debug("Loaded \(mockEntries.count) mock entries")
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
    }
    
    deinit {
        logger.debug("LeaderboardViewModel \(self.instanceId) deinitializing")
        currentFetchTask?.cancel()
        cancellables.removeAll()
    }
} 