// LeaderboardView+Fix.swift
// This fix prevents the infinite initialization loop

import SwiftUI

// First, create a wrapper to prevent re-initialization
struct LeaderboardViewWrapper: View {
    let viewId: String
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var hasInitialized = false
    
    var body: some View {
        LeaderboardView(viewModel: viewModel, viewId: viewId)
            .onAppear {
                if !hasInitialized {
                    logInfo("LeaderboardView initialized once with ID: \(viewId)")
                    hasInitialized = true
                }
            }
    }
}

// Extension to add debouncing to existing LeaderboardViewModel
extension LeaderboardViewModel {
    private static var lastFetchTime: Date?
    private static let fetchDebounceInterval: TimeInterval = 2.0 // Don't re-fetch within 2 seconds
    
    func fetchWithDebouncing() async {
        // Prevent re-fetching if recently fetched
        if let lastFetch = Self.lastFetchTime,
           Date().timeIntervalSince(lastFetch) < Self.fetchDebounceInterval {
            logDebug("Skipping leaderboard fetch - recently fetched")
            return
        }
        
        // Prevent multiple simultaneous fetches
        guard !isLoading else {
            logDebug("Skipping leaderboard fetch - already loading")
            return
        }
        
        Self.lastFetchTime = Date()
        logInfo("Fetching leaderboard - board: \(selectedBoard), category: \(selectedCategory), exercise: \(selectedExercise)")
        
        await fetch()
    }
}

// Note: The original LeaderboardView already has proper initialization
// The logging is now handled by the existing initializer using logDebug()
// which will be filtered by ConsoleLogger to prevent spam 