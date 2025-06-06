//
//  LeaderboardViewModel.swift
//

import Foundation
import CoreLocation
import SwiftUI     // only for @MainActor
import Combine     // Required for some protocol imports

// MARK: – View-model

@MainActor
final class LeaderboardViewModel: ObservableObject {

    // ──  UI-state  ────────────────────────────────────────────────────────────
    @Published var selectedBoard:     LeaderboardType        = .global
    @Published var selectedCategory:  LeaderboardCategory    = .weekly
    @Published var selectedExercise:  LeaderboardExerciseType = .overall
    @Published var selectedRadius:    LeaderboardRadius      = .five

    @Published var leaderboardEntries: [LeaderboardEntryView] = []
    @Published var backendStatus:      BackendStatus        = .unknown
    @Published var isLoading:          Bool                 = false
    @Published var errorMessage:       String?              = nil      // for alert

    // ──  Services  ────────────────────────────────────────────────────────────
    private let service:    LeaderboardServiceProtocol
    let location:           LocationServiceProtocol
    private let keychain:   KeychainServiceProtocol
    var currentUserID: String?

    // You can still inject mocks in unit-tests
    init(service:   LeaderboardServiceProtocol = LeaderboardService(),
         location:  LocationServiceProtocol    = LocationService(),
         keychain:  KeychainServiceProtocol    = KeychainService()) {
        self.service   = service
        self.location  = location
        self.keychain  = keychain
        self.currentUserID = keychain.getUserID()
    }

    // ──  Public API (call from View)  ─────────────────────────────────────────
    /// Safe to call repeatedly; bails out if a fetch is already in flight.
    func fetch() async {
        guard !Task.isCancelled else { return }
        guard !isLoading else { return }
        
        // Quick check to prevent excessive calls when view is redrawing rapidly
        // This will debounce rapid fetch attempts
        let isLoadingNow = isLoading
        if isLoadingNow { return }
        
        isLoading = true
        defer { isLoading = false }                // ← guarantees UI never hangs

        // Small delay to let UI stabilize
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay

        do {
            leaderboardEntries = try await loadRows()
            backendStatus = leaderboardEntries.isEmpty ? .noActiveUsers : .connected
            errorMessage  = nil
        } catch {
            backendStatus = .connectionFailed(error.localizedDescription)
            errorMessage  = error.localizedDescription
            leaderboardEntries = []
        }
    }

    // ──  Private helpers  ─────────────────────────────────────────────────────
    private func loadRows() async throws -> [LeaderboardEntryView] {
        let token = keychain.getAccessToken() ?? ""

        // Determine the exerciseType string for the API call
        let apiExerciseType: String = selectedExercise.rawValue

        if selectedBoard == .global {
            let backendEntries = try await service.fetchGlobalLeaderboard(
                authToken: token,
                timeFrame: selectedCategory.apiParameter,
                exerciseType: apiExerciseType // Use determined exercise type
            )
            // Return the entries from the service directly
            return backendEntries
        } else {
            // local board → need location
            guard let loc = try await location.getCurrentLocation() else {
                throw NSError(domain: "Leaderboard",
                              code: 1,
                              userInfo: [NSLocalizedDescriptionKey:
                                "Location unavailable – enable it in Settings"])
            }
            let backendEntries = try await service.fetchLocalLeaderboard(
                latitude:     loc.coordinate.latitude,
                longitude:    loc.coordinate.longitude,
                radiusMiles:  selectedRadius.rawValue, // Use the new selectedRadius
                authToken:    token,
                exerciseType: apiExerciseType,      // Use determined exercise type
                timeFrame: selectedCategory.apiParameter // Pass selected time frame
            )
            // Return the entries from the service directly
            return backendEntries
        }
    }
}
