//
//  LeaderboardViewModel.swift
//

import Foundation
import CoreLocation
import SwiftUI     // only for @MainActor

// Need to import the service protocol to access LeaderboardEntryView
import Combine     // Required for some protocol imports

// MARK: – Public supporting enums (reuse existing ones if they live elsewhere)

enum LeaderboardType: String, CaseIterable, Identifiable {
    case global  = "Global"
    case local   = "Local (5 mi)"
    var id: String { rawValue }
}

enum LeaderboardExerciseType: String, CaseIterable, Identifiable {
    case overall, pushup, situp, pullup, running
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case daily = "Daily", weekly = "Weekly", monthly = "Monthly", allTime = "All Time"
    var id: String { rawValue }
    var apiParameter: String {
        switch self { case .daily: "daily"
                      case .weekly: "weekly"
                      case .monthly: "monthly"
                      case .allTime: "all_time" }
    }
}

enum BackendStatus: Equatable {
    case unknown, connected, noActiveUsers, connectionFailed(String)
}

// MARK: – View-model

@MainActor
final class LeaderboardViewModel: ObservableObject {

    // ──  UI-state  ────────────────────────────────────────────────────────────
    @Published var selectedBoard:     LeaderboardType        = .global
    @Published var selectedCategory:  LeaderboardCategory    = .weekly
    @Published var selectedExercise:  LeaderboardExerciseType = .overall

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

        if selectedBoard == .global {
            let backendEntries = try await service.fetchGlobalLeaderboard(
                authToken: token,
                timeFrame: selectedCategory.apiParameter
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
                radiusMiles:  5,
                authToken:    token
            )
            // Return the entries from the service directly
            return backendEntries
        }
    }
}
