//
//  LeaderboardViewModel.swift
//

import Foundation
import CoreLocation
import SwiftUI     // only for @MainActor

// Need to import the service protocol to access LeaderboardEntryView
import Combine     // Required for some protocol imports

// MARK: – Public supporting enums (reuse existing ones if they live elsewhere)

// Add new enum for selectable radii
enum LeaderboardRadius: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twentyFive = 25
    case fifty = 50

    var id: Int { self.rawValue }
    var displayName: String { "\(self.rawValue) mi" }
}

enum LeaderboardType: String, CaseIterable, Identifiable {
    case global  = "Global"
    case local   = "Local" // Removed "(5 mi)"
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
    @Published var selectedRadius:    LeaderboardRadius      = .five // New property for radius

    // Add safe accessor for selectedExercise
    var safeSelectedExercise: LeaderboardExerciseType {
        if LeaderboardExerciseType.allCases.contains(selectedExercise) {
            return selectedExercise
        } else {
            // If invalid, return a safe default and fix the stored property
            DispatchQueue.main.async {
                self.selectedExercise = .overall
            }
            return .overall
        }
    }

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
        
        // Defensive check to ensure selectedExercise is a valid value
        if !LeaderboardExerciseType.allCases.contains(selectedExercise) {
            // If somehow selectedExercise is invalid, set it to a safe default
            self.selectedExercise = .overall
        }
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
        let apiExerciseType: String
        switch selectedExercise {
        case .overall:
            // Standardized keyword for overall/aggregate. Backend will use this.
            apiExerciseType = "aggregate_overall"
        default:
            apiExerciseType = selectedExercise.rawValue
        }

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
