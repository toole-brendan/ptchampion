import Foundation
import Combine
import CoreLocation

// Define the LeaderboardType within the ViewModel or globally if used elsewhere
enum LeaderboardType: String, CaseIterable, Identifiable {
    case global = "Global"
    case local = "Local (5mi)" // Example distance, adjust as needed
    var id: String { self.rawValue }
}

@MainActor
class LeaderboardViewModel: ObservableObject {

    private let leaderboardService: LeaderboardServiceProtocol
    private let locationService: LocationServiceProtocol
    private let keychainService: KeychainServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    @Published var selectedBoard: LeaderboardType = .global {
        didSet { fetchLeaderboardData() } // Refetch when type changes
    }
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined

    private let localRadiusMiles = 5 // Configurable radius for local search

    init(leaderboardService: LeaderboardServiceProtocol = LeaderboardService(),
         locationService: LocationServiceProtocol = LocationService(),
         keychainService: KeychainServiceProtocol = KeychainService()) {
        self.leaderboardService = leaderboardService
        self.locationService = locationService
        self.keychainService = keychainService
        subscribeToLocationStatus()
        fetchLeaderboardData() // Initial fetch for the default board (.global)
    }

    private func subscribeToLocationStatus() {
        locationService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationPermissionStatus = status
                // If switching to local and status becomes authorized, refetch
                if self?.selectedBoard == .local && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                    print("LeaderboardViewModel: Location authorized, fetching local board.")
                    self?.fetchLeaderboardData()
                }
            }
            .store(in: &cancellables)

        // Optionally subscribe to location updates if continuous update needed
        // locationService.locationPublisher...sink { ... }

         locationService.errorPublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] error in
                 print("LeaderboardViewModel: Location Service Error: \(error.localizedDescription)")
                 if self?.selectedBoard == .local {
                     self?.errorMessage = "Could not get location for local leaderboard: \(error.localizedDescription)"
                     self?.leaderboardEntries = [] // Clear entries if location fails
                     self?.isLoading = false
                 }
             }
             .store(in: &cancellables)
    }

    func fetchLeaderboardData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let token = try keychainService.loadToken() else {
                    throw APIError.requestFailed(statusCode: 401) // Or a specific AuthError
                }

                print("LeaderboardViewModel: Fetching \(selectedBoard.rawValue) leaderboard...")
                switch selectedBoard {
                case .global:
                    let entries = try await leaderboardService.fetchGlobalLeaderboard(authToken: token)
                    self.leaderboardEntries = entries
                    print("LeaderboardViewModel: Fetched \(entries.count) global entries.")

                case .local:
                    // Check permission first
                    guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
                         print("LeaderboardViewModel: Location permission needed for local board.")
                         handleLocalLocationPermission()
                         return // Don't proceed with fetch yet
                    }
                    // Request a fresh location update
                    locationService.requestLocationUpdate()
                    // Use last known location for now, or wait for update via publisher
                    guard let location = locationService.getLastKnownLocation() else {
                         errorMessage = "Waiting for location..."
                         // TODO: Implement waiting logic or rely on publisher trigger
                         isLoading = false // Stop loading indicator while waiting
                         return
                    }
                    let entries = try await leaderboardService.fetchLocalLeaderboard(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        radiusMiles: localRadiusMiles,
                        authToken: token
                    )
                    self.leaderboardEntries = entries
                    print("LeaderboardViewModel: Fetched \(entries.count) local entries near (\(location.coordinate.latitude), \(location.coordinate.longitude))")
                }
                isLoading = false

            } catch let locError as LocationError {
                 print("LeaderboardViewModel: Location Error during fetch: \(locError.localizedDescription)")
                 errorMessage = locError.localizedDescription
                 leaderboardEntries = []
                 isLoading = false
            } catch let error as APIErrorResponse {
                 print("LeaderboardViewModel: Failed to fetch leaderboard (API Error): \(error.localizedDescription)")
                 errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                 leaderboardEntries = []
                 isLoading = false
            } catch let error as APIError {
                 print("LeaderboardViewModel: Failed to fetch leaderboard (Client Error): \(error.localizedDescription)")
                 errorMessage = "Failed to load leaderboard. Check connection."
                 leaderboardEntries = []
                 isLoading = false
            } catch {
                 print("LeaderboardViewModel: Failed to fetch leaderboard (Unexpected Error): \(error.localizedDescription)")
                 errorMessage = "An unexpected error occurred while loading the leaderboard."
                 leaderboardEntries = []
                 isLoading = false
            }
        }
    }

    // Handle location permission for local board
    private func handleLocalLocationPermission() {
        isLoading = false // Stop loading
        leaderboardEntries = [] // Clear entries
        if locationPermissionStatus == .notDetermined {
            errorMessage = "Location permission is needed for local leaderboards."
            locationService.requestLocationPermission()
        } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
            errorMessage = "Location access denied. Please enable it in Settings to use local leaderboards."
        }
    }

    // Function to trigger refresh manually
    func refreshData() {
         fetchLeaderboardData()
    }
} 