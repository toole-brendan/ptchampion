import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication
import os.log
import Combine
import PTDesignSystem
// Import shared views directly since they are not in separate modules
// import LeaderboardRow
// import LeaderboardRowPlaceholder

// Setup logger for this view
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardView")

// Create a simple equatable struct for the task ID
struct LeaderboardFilterState: Equatable {
    let boardType: LeaderboardType
    let category: LeaderboardCategory
    let exerciseType: LeaderboardExerciseType
}

struct LeaderboardView: View {
    // Add properties for viewModel and viewId
    @ObservedObject var viewModel: LeaderboardViewModel // REVERTED to ObservedObject
    var viewId: String // Kept for consistency if used elsewhere, though not directly in this body
    
    @State private var navigatingToUserID: String? // State for navigation trigger
    
    // Initialize with required parameters
    init(viewModel: LeaderboardViewModel, viewId: String) {
        self.viewModel = viewModel
        self.viewId = viewId
        logger.debug("Initialized LeaderboardView with ID: \(viewId)")
    }
    
    var body: some View {
        // IMPORTANT: This view or its parent needs to be in a NavigationStack for .navigationDestination to work
        VStack(spacing: 0) {
            filtersView
            contentView
        }
        .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetch()
            }
        }
        .onChange(of: viewModel.selectedBoard) { _ in Task { await viewModel.fetch() } }
        .onChange(of: viewModel.selectedCategory) { _ in Task { await viewModel.fetch() } }
        .onChange(of: viewModel.selectedExercise) { _ in Task { await viewModel.fetch() } }
        .onChange(of: viewModel.selectedRadius) { _ in Task { await viewModel.fetch() } } // Fetch on radius change
        .navigationDestination(item: $navigatingToUserID) { userID in
            UserProfileView(userID: userID)
        }
    }
    
    // Helper for logging
    private func logViewContent(message: String) {
        logger.info("LeaderboardView [\(viewId)]: \(message)")
    }
    
    // Extracted Filters View
    private var filtersView: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.small) {
            Picker("Board Type", selection: $viewModel.selectedBoard) {
                ForEach(LeaderboardType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Conditional Picker for Radius, only shown if 'Local' board is selected
            if viewModel.selectedBoard == .local {
                Picker("Radius", selection: $viewModel.selectedRadius) {
                    ForEach(LeaderboardRadius.allCases) { radiusValue in // Renamed to avoid conflict
                        Text(radiusValue.displayName).tag(radiusValue)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }

            HStack {
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(LeaderboardCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Exercise", selection: $viewModel.selectedExercise) {
                    ForEach(LeaderboardExerciseType.allCases) { exercise in
                        Text(exercise.displayName).tag(exercise)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.small)
        .background(AppTheme.GeneratedColors.cardBackground.opacity(0.5))
        .animation(.easeInOut, value: viewModel.selectedBoard) // Animate changes when board type changes
    }
    
    // Extracted Content View
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
            List {
                ForEach(0..<10) { _ in
                    LeaderboardRowPlaceholder()
                }
            }
            .listStyle(PlainListStyle())
            .onAppear { logViewContent(message: "Showing placeholders") }
        } else if let errorMessage = viewModel.errorMessage {
            VStack {
                Spacer()
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.GeneratedColors.error)
                PTLabel("Error Loading Leaderboard", style: .subheading)
                PTLabel(errorMessage, style: .caption).foregroundColor(AppTheme.GeneratedColors.textSecondary)
                PTButton("Retry", style: .primary, action: { Task { await viewModel.fetch() } })
                    .padding(.top)
                Spacer()
            }
            .padding()
            .onAppear { logViewContent(message: "Showing error: \(errorMessage)") }
        } else if viewModel.leaderboardEntries.isEmpty && viewModel.backendStatus == .noActiveUsers {
            VStack {
                Spacer()
                Image(systemName: "person.3.fill")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                PTLabel("Leaderboard is Empty", style: .subheading)
                PTLabel("Be the first to set a score!", style: .body).foregroundColor(AppTheme.GeneratedColors.textSecondary)
                Spacer()
            }
            .padding()
            .onAppear { logViewContent(message: "Showing empty state") }
        } else if viewModel.leaderboardEntries.isEmpty {
             VStack {
                Spacer()
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                PTLabel("No Data", style: .subheading)
                PTLabel("No leaderboard data available for the current selection.", style: .body).foregroundColor(AppTheme.GeneratedColors.textSecondary)
                Spacer()
            }
            .padding()
            .onAppear { logViewContent(message: "Showing no data for selection") }
        } else {
            List {
                ForEach(viewModel.leaderboardEntries) { entry in
                    LeaderboardRowView(entry: entry, isCurrentUser: entry.userId == viewModel.currentUserID && entry.userId != nil)
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            if let userID = entry.userId {
                                logger.info("Tapping user: \(entry.name, privacy: .public), ID: \(userID, privacy: .public). Preparing for navigation.")
                                self.navigatingToUserID = userID // Set state to trigger navigation
                            } else {
                                logger.info("Tapped on leaderboard entry for user: \(entry.name, privacy: .public), but user ID is nil.")
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable { 
                await viewModel.fetch()
            }
            .onAppear { logViewContent(message: "Showing \(viewModel.leaderboardEntries.count) entries") }
        }
    }
}

#Preview {
    // For preview to work with .navigationDestination, it might need to be in a NavigationStack here too
    NavigationStack {
        LeaderboardView(
            viewModel: LeaderboardViewModel(),
            viewId: "PREVIEW"
        )
    }
} 