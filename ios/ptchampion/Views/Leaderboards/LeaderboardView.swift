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

// NEW sub-view for radius selection
private struct RadiusSelectorView: View {
    @Binding var selectedRadius: LeaderboardRadius
    var body: some View {
        Menu {
            ForEach(LeaderboardRadius.allCases, id: \.self) { radius in
                Button {
                    selectedRadius = radius
                } label: {
                    Label(radius.displayName,
                          systemImage: selectedRadius == radius ? "checkmark" : "")
                }
            }
        } label: {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(AppTheme.GeneratedColors.primary)
                Text("Radius: \(selectedRadius.displayName)")
                    .font(AppTheme.GeneratedTypography.body())
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                    .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
            )
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
        .padding(.horizontal)
    }
}

struct LeaderboardView: View {
    // Add properties for viewModel and viewId
    @ObservedObject var viewModel: LeaderboardViewModel
    var viewId: String
    
    @State private var navigatingToUserID: String?
    @Namespace private var animation
    
    // Track visibility state for animation
    @State private var contentOpacity: Double = 1.0
    
    // Initialize with required parameters
    init(viewModel: LeaderboardViewModel, viewId: String) {
        self.viewModel = viewModel
        self.viewId = viewId
        logger.debug("Initialized LeaderboardView with ID: \(viewId)")
    }
    
    // Function to get formatted title - breaking up complex expression
    private var formattedFilterTitle: String {
        // Access properties individually to help compiler
        let exerciseName = viewModel.selectedExercise.displayName
        let timeframeName = viewModel.selectedCategory.rawValue
        // Now combine them
        return "\(exerciseName) • \(timeframeName)"
    }
    
    // Helper computed properties to simplify main view body
    private var headerView: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
            // Break down into separate Text views to help compiler
            let titleText = Text(viewModel.selectedBoard.rawValue + " Leaderboard")
                .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            let subtitleText = Text(formattedFilterTitle)
                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .italic()
            
            // Combine in VStack
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                titleText
                subtitleText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // Further break down segment control to reduce complexity
    private func segmentButton(for type: LeaderboardType) -> some View {
        let isSelected = viewModel.selectedBoard == type
        let foregroundColor = isSelected ? 
            AppTheme.GeneratedColors.textOnPrimary : 
            AppTheme.GeneratedColors.textPrimary
        
        return Button(action: {
            // Simple state change without animation
            viewModel.selectedBoard = type
        }) {
            VStack {
                Text(type.rawValue)
                    .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.body))
                    .foregroundColor(foregroundColor)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
            }
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.full)
                            .fill(AppTheme.GeneratedColors.primary)
                            .matchedGeometryEffect(id: "segmentBackground", in: animation)
                    }
                }
            )
        }
    }
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardType.allCases) { type in
                segmentButton(for: type)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.full)
                .stroke(AppTheme.GeneratedColors.primary.opacity(0.3), lineWidth: 1)
                .background(
                    AppTheme.GeneratedColors.cardBackground
                        .cornerRadius(AppTheme.GeneratedRadius.full)
                )
        )
        .padding(.horizontal)
    }
    
    var body: some View {
        bodyContent
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // No need to check if selectedRadius is nil since it's not optional
                Task {
                    await viewModel.fetch()
                }
            }
            .onChange(of: viewModel.selectedBoard) { newBoard in 
                // No need to check if selectedRadius is nil since it's not optional
                
                // Animate content change with opacity
                performContentTransition {
                    Task { await viewModel.fetch() }
                }
            }
            .onChange(of: viewModel.selectedCategory) { _ in 
                performContentTransition {
                    Task { await viewModel.fetch() }
                }
            }
            .onChange(of: viewModel.selectedExercise) { _ in 
                performContentTransition {
                    Task { await viewModel.fetch() }
                }
            }
            .onChange(of: viewModel.selectedRadius) { _ in 
                performContentTransition {
                    Task { await viewModel.fetch() }
                }
            }
            .navigationDestination(item: $navigatingToUserID) { userID in
                UserProfileView(userID: userID)
            }
    }
    
    // Break down the body into a separate computed property
    private var bodyContent: some View {
        VStack(spacing: 0) {
            // Header with context information
            headerView
            
            // All the filter controls in a separate view
            filterControlsSection
            
            // Divider
            Rectangle()
                .fill(AppTheme.GeneratedColors.tacticalGray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal)
            
            // Content area with simple opacity animation
            mainContentArea
        }
    }
    
    // Break down the filter controls into a separate view
    private var filterControlsSection: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Use extracted segmented control
            segmentedControl

            // Filters section
            filtersSection
            
            // Conditional Radius selector for Local leaderboards
            if viewModel.selectedBoard == .local {
                RadiusSelectorView(selectedRadius: $viewModel.selectedRadius)
            } else {
                EmptyView() // Explicit EmptyView for type safety
            }
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.medium)
    }
    
    // Break down the main content area into a separate view
    private var mainContentArea: some View {
        ZStack {
            if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
                loadingPlaceholders
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.leaderboardEntries.isEmpty && viewModel.backendStatus == .noActiveUsers {
                emptyLeaderboardView
            } else if viewModel.leaderboardEntries.isEmpty {
                noResultsView
            } else {
                leaderboardListView
            }
        }
        .opacity(contentOpacity)
    }
    
    // Helper function to perform fade transition without using .transition
    private func performContentTransition(action: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.2)) {
            contentOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
            withAnimation(.easeIn(duration: 0.2)) {
                contentOpacity = 1.0
            }
        }
    }
    
    // Extract filters section to simplify body
    private var filtersSection: some View {
        HStack(spacing: AppTheme.GeneratedSpacing.medium) {
            categoryFilterMenu
            exerciseFilterMenu
        }
        .padding(.horizontal)
    }
    
    // Break down filters into separate views
    private var categoryFilterMenu: some View {
        // Category filter (Daily, Weekly, etc.)
        Menu {
            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                Button(action: {
                    // No animation
                    viewModel.selectedCategory = category
                }) {
                    HStack {
                        Text(category.rawValue)
                        if viewModel.selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            categoryFilterLabel
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
    }
    
    private var categoryFilterLabel: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppTheme.GeneratedColors.primary)
            Text(viewModel.selectedCategory.rawValue)
                .font(AppTheme.GeneratedTypography.body())
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
        )
    }
    
    private var exerciseFilterMenu: some View {
        // Exercise type filter
        Menu {
            ForEach(LeaderboardExerciseType.allCases, id: \.self) { exercise in
                Button(action: {
                    // No animation
                    viewModel.selectedExercise = exercise
                }) {
                    HStack {
                        Text(exercise.displayName)
                        if viewModel.selectedExercise == exercise {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            exerciseFilterLabel
        }
        .tint(AppTheme.GeneratedColors.textPrimary)
    }
    
    private var exerciseFilterLabel: some View {
        HStack {
            Image(systemName: "figure.run")
                .foregroundColor(AppTheme.GeneratedColors.primary)
            Text(viewModel.selectedExercise.displayName)
                .font(AppTheme.GeneratedTypography.body())
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                .fill(AppTheme.GeneratedColors.primary.opacity(0.1))
        )
    }
    
    // Helper for logging
    private func logViewContent(message: String) {
        logger.info("LeaderboardView [\(viewId)]: \(message)")
    }
    
    // Extracted Content View
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
            loadingPlaceholders
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if viewModel.leaderboardEntries.isEmpty && viewModel.backendStatus == .noActiveUsers {
            emptyLeaderboardView
        } else if viewModel.leaderboardEntries.isEmpty {
            noResultsView
        } else {
            leaderboardListView
        }
    }
    
    // Further break down complex views
    private var loadingPlaceholders: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.small) {
            ForEach(0..<5, id: \.self) { _ in
                LeaderboardRowPlaceholder()
            }
        }
        .padding(.horizontal)
        .padding(.top, AppTheme.GeneratedSpacing.medium)
        .onAppear { logViewContent(message: "Showing placeholders") }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.GeneratedColors.error)
                .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            
            Text("Error Loading Leaderboard")
                .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.heading4))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            
            Text(message)
                .font(AppTheme.GeneratedTypography.body())
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.GeneratedSpacing.large)
                .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            
            // Fix ambiguous reference to .primary by using an explicit ButtonStyle
            // Using a fully qualified type to resolve ambiguity
            PTButton("Retry", style: PTButton.ButtonStyle.primary, action: { 
                // No animation
                Task { await viewModel.fetch() } 
            })
            .padding(.horizontal, AppTheme.GeneratedSpacing.large)
            
            Spacer()
        }
        .padding()
        .onAppear { logViewContent(message: "Showing error: \(message)") }
    }
    
    private var emptyLeaderboardView: some View {
        VStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.GeneratedColors.brassGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
            }
            .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            
            Text("Leaderboard is Empty")
                .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.heading4))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            
            Text("Be the first to set a score!")
                .font(AppTheme.GeneratedTypography.body())
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            
            Text("Complete a workout to post your score on the leaderboard.")
                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small))
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.GeneratedSpacing.large)
            
            Spacer()
        }
        .padding()
        .onAppear { logViewContent(message: "Showing empty state") }
    }
    
    private var noResultsView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.GeneratedColors.textSecondary.opacity(0.7))
                .padding(.bottom, AppTheme.GeneratedSpacing.medium)
            
            Text("No Results Found")
                .font(AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.heading4))
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            
            Text("No data available for the current selection.")
                .font(AppTheme.GeneratedTypography.body())
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.GeneratedSpacing.large)
            
            Spacer()
        }
        .padding()
        .onAppear { logViewContent(message: "Showing no data for selection") }
    }
    
    private var leaderboardListView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.GeneratedSpacing.small) {
                ForEach(viewModel.leaderboardEntries) { entry in
                    let isCurrentUser = entry.userId == viewModel.currentUserID && entry.userId != nil
                    LeaderboardRowView(entry: entry, isCurrentUser: isCurrentUser)
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            handleRowTap(entry: entry)
                        }
                        // No animations
                }
            }
            .padding(.horizontal)
            .padding(.vertical, AppTheme.GeneratedSpacing.medium)
        }
        // Replace .refreshable with a plain ScrollView
        // This could be the source of the ambiguity at line 401
        .onAppear { logViewContent(message: "Showing \(viewModel.leaderboardEntries.count) entries") }
    }
    
    // Extract tap handler to simplify
    private func handleRowTap(entry: LeaderboardEntryView) {
        if let userID = entry.userId {
            logger.info("Tapping user: \(entry.name, privacy: .public), ID: \(userID, privacy: .public). Preparing for navigation.")
            self.navigatingToUserID = userID // Set state to trigger navigation
        } else {
            logger.info("Tapped on leaderboard entry for user: \(entry.name, privacy: .public), but user ID is nil.")
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

#Preview("Local Mode") {
    // Create the model, set the board to .local
    let vm = LeaderboardViewModel()
    vm.selectedBoard = .local

    // Pass the prepared model into the view
    return NavigationStack {
        LeaderboardView(
            viewModel: vm,
            viewId: "LOCAL-PREVIEW"
        )
    }
} 