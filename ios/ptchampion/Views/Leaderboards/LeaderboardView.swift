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
    // Define constants directly
    private struct Constants {
        static let globalPadding: CGFloat = 16
        static let appearDelay: TimeInterval = 0.5 // Increased delay before loading data
        static let debounceInterval: TimeInterval = 0.3 // Debounce interval for selections
    }
    
    // Use ObservedObject as the ViewModel is now injected from the parent (MainTabView)
    @ObservedObject var viewModel: LeaderboardViewModel 
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Make viewId internal so the initializer is accessible
    let viewId: String
    
    // Track if view is active to prevent unnecessary updates
    @State private var isViewActive = false
    
    // Add state to track location permission status
    @State private var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    
    // Track time spent in this view for analytics
    @State private var viewAppearTime: Date? = nil
    @State private var viewLifetimeSeconds: TimeInterval = 0
    @State private var viewAnalyticsTimer: Timer? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                headerView()
                
                // Exercise, Category and type pickers - these are all inputs that change the trigger
                VStack(spacing: 0) {
                    Picker("Exercise", selection: $viewModel.selectedExercise) {
                        ForEach(LeaderboardExerciseType.allCases) { ex in
                            Text(ex.displayName).tag(ex)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    // Disable animations for picker changes
                    .animation(nil, value: viewModel.selectedExercise)

                    Picker("Scope", selection: $viewModel.selectedBoard) {
                        ForEach(LeaderboardType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    // Disable animations for picker changes
                    .animation(nil, value: viewModel.selectedBoard)
                }
                
                // Debug information in DEBUG builds
                #if DEBUG
                HStack {
                    PTLabel("View ID: \(viewId)", style: .caption)
                    Spacer()
                    PTLabel("Time: \(Int(viewLifetimeSeconds))s", style: .caption)
                }
                .padding(.horizontal)
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                #endif

                // Use a simple switch statement with fixed height containers
                let minHeight: CGFloat = 400
                
                if viewModel.isLoading {
                    loadingView()
                        .frame(minHeight: minHeight)
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                        .frame(minHeight: minHeight)
                } else if viewModel.leaderboardEntries.isEmpty {
                    emptyStateView()
                        .frame(minHeight: minHeight)
                } else {
                    leaderboardListView()
                }
            }
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
            // Use onAppear for initial data load instead of task
            .onAppear {
                startViewAppearance()
                // Wait for view to fully appear before loading data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if isViewActive {
                        Task {
                            await viewModel.fetch()
                        }
                    }
                }
            }
            // Use separate task only for filter changes
            .onChange(of: viewModel.selectedBoard) { _, _ in
                if isViewActive {
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                if isViewActive {
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
            .onChange(of: viewModel.selectedExercise) { _, _ in
                if isViewActive {
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
        }
        .animation(nil) // Disable all animations at container level
        .onReceive(viewModel.location.authorizationStatusPublisher) { status in
            locationPermissionStatus = status
        }
        .onDisappear {
            handleViewDisappearance()
        }
    }
    
    // MARK: - Lifecycle Management
    
    private func startViewAppearance() {
        print("🏆 LeaderboardView: appeared \(viewId)")
        logger.debug("LeaderboardView appeared \(viewId)")
        
        // Check location permission status
        let locationService = viewModel.location
        locationPermissionStatus = locationService.getCurrentAuthorizationStatus()
        
        // Record appearance time for analytics
        viewAppearTime = Date()
        
        // Start timer to track view lifetime
        viewAnalyticsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let appearTime = viewAppearTime {
                viewLifetimeSeconds = Date().timeIntervalSince(appearTime)
            }
        }
        
        // Set view as active before triggering any data loads
        isViewActive = true
        
        // Let the UI settle before logging or taking other actions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔍 LeaderboardView[\(viewId)]: onAppear - current Thread: \(Thread.current.description)")
            print("🔍 LeaderboardView[\(viewId)]: onAppear - viewModel.isLoading: \(viewModel.isLoading)")
            print("🔍 LeaderboardView[\(viewId)]: onAppear - entries count: \(viewModel.leaderboardEntries.count)")
        }
    }
    
    private func handleViewDisappearance() {
        // Set inactive first to prevent any new tasks from starting
        isViewActive = false
        
        print("🏆 LeaderboardView: disappeared \(viewId)")
        logger.debug("LeaderboardView disappeared \(viewId)")
        
        // Cancel any running tasks
        Task {
            // Sleep briefly to let any in-progress work settle
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Save analytics data
        if let appearTime = viewAppearTime {
            let totalTime = Date().timeIntervalSince(appearTime)
            print("🔍 LeaderboardView[\(viewId)]: View was visible for \(totalTime) seconds")
        }
        
        // Clean up timer
        viewAnalyticsTimer?.invalidate()
        viewAnalyticsTimer = nil
        viewAppearTime = nil
        
        // Track view disappearance
        print("🔍 LeaderboardView[\(viewId)]: onDisappear - current Thread: \(Thread.current.description)")
        print("🔍 LeaderboardView[\(viewId)]: onDisappear - viewModel.isLoading: \(viewModel.isLoading)")
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func headerView() -> some View {
        PTLabel("Leaderboard", style: .heading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .bottom])
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.large) {
            // Use a simple activity indicator instead of ProgressView
            Text("⏳")
                .font(.system(size: 70))
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
                
            PTLabel("Loading leaderboard data...", style: .body)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
        .padding()
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            // Use text instead of image to avoid image loading issues
            Text("🏆")
                .font(.system(size: 70))
                .padding(.bottom, AppTheme.GeneratedSpacing.small)

            PTLabel("No rankings found for this leaderboard.", style: .subheading)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)

            PTLabel(viewModel.selectedBoard == .local
                 ? "Try changing to Global scope or completing an exercise nearby."
                 : "Complete your first workout to get on the board.", style: .body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        // Prepare variables outside of the view builder context
        let displayEmoji = viewModel.backendStatus == .noActiveUsers ? "👥" : "⚠️"
        let isLocationDenied = locationPermissionStatus == .denied || locationPermissionStatus == .restricted
        let shouldShowSettingsButton = viewModel.selectedBoard == .local && isLocationDenied
        let hasNoActiveUsers = viewModel.backendStatus == .noActiveUsers
        
        VStack(spacing: AppTheme.GeneratedSpacing.medium) {
            Text(displayEmoji)
                .font(.system(size: 70))
                .padding(.bottom, AppTheme.GeneratedSpacing.small)
            
            PTLabel(message, style: .body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                .padding(.horizontal)
            
            // Special message for no users case
            if hasNoActiveUsers {
                PTLabel("The Azure database doesn't have any active users yet. When users start completing workouts, they'll appear here!", style: .caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    .padding(.horizontal)
            }
            
            if shouldShowSettingsButton {
                PTButton("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            PTButton("Retry", style: .secondary) {
                // Just use fetch to reload
                if isViewActive { // Only refresh if view is active
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
            .padding(.top, AppTheme.GeneratedSpacing.small)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func leaderboardListView() -> some View {
        // Use a LazyVStack inside a ScrollView for better performance
        ScrollView {
            LazyVStack(spacing: 0) {
                // Use ListView placeholder during loading state
                if viewModel.isLoading && viewModel.leaderboardEntries.isEmpty {
                    // Use Identifiable Int to avoid binding issues
                    ForEach(0..<8, id: \.self) { i in
                        // Create a placeholder row inline
                        HStack {
                            // Rank - simplified to avoid image loading issues
                            PTLabel("\(i+1)", style: .body)
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary.opacity(0.5))
                                .frame(width: 36)
                            
                            // Name
                            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.small)
                                .fill(AppTheme.GeneratedColors.textSecondary.opacity(0.2))
                                .frame(width: 120, height: 16)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            // Score
                            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.small)
                                .fill(AppTheme.GeneratedColors.textSecondary.opacity(0.2))
                                .frame(width: 50, height: 16)
                        }
                        .padding(.horizontal, Constants.globalPadding)
                        .padding(.vertical, 8)
                        .background(AppTheme.GeneratedColors.background)
                        .id("placeholder-\(i)")
                    }
                } else {
                    // Ensure leaderboardEntries elements have proper identifiable IDs
                    ForEach(Array(viewModel.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                        // Prepare medal display outside the card view
                        let rankDisplay = getRankDisplay(for: entry.rank)
                        
                        PTCard {
                            HStack {
                                PTLabel(rankDisplay, style: .body)
                                    .frame(width: 36)
                                
                                PTLabel(entry.name, style: .body)
                                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                
                                Spacer()
                                
                                PTLabel("\(entry.score) pts", style: .body)
                                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .padding(.horizontal, AppTheme.GeneratedSpacing.small)
                        .padding(.vertical, 4)
                        .id(entry.id)
                    }
                }
            }
        }
        .refreshable { 
            print("🏆 LeaderboardView: Pull-to-refresh triggered")
            if isViewActive { // Only refresh if view is active
                // Add extra protection during refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
        }
    }
    
    // Helper function to get rank display
    private func getRankDisplay(for rank: Int) -> String {
        switch rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "\(rank)"
        }
    }

    // MARK: - Static Configuration Methods
    
    // Function to configure Segmented Control Appearance - static to avoid recreating on each view
    private static func configureSegmentedControlAppearance() {
        // Background color using design system colors
        let backgroundColor = UIColor(AppTheme.GeneratedColors.background)
        UISegmentedControl.appearance().backgroundColor = backgroundColor
        UISegmentedControl.appearance().setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

        // Text attributes with system fonts
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor(AppTheme.GeneratedColors.textSecondary)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(AppTheme.GeneratedColors.textPrimary)
        ]

        UISegmentedControl.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)

        // Selected segment color using design system accent color
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.GeneratedColors.primary)
    }
}

// Preview with real data configuration
#Preview {
    // Create a temporary ViewModel just for the preview
    let previewViewModel = LeaderboardViewModel() 
    // Provide a dummy viewId for the preview
    LeaderboardView(viewModel: previewViewModel, viewId: "PREVIEW")
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light Mode")
}

#Preview {
    // Create a temporary ViewModel just for the preview
    let previewViewModel = LeaderboardViewModel() 
    // Provide a dummy viewId for the preview
    LeaderboardView(viewModel: previewViewModel, viewId: "PREVIEW")
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark Mode")
} 