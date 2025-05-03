import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication
import os.log
import Combine
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

    // Remove the init() method as the ViewModel is injected
    /*
    // Apply appearance changes in init
    init() {
        // Create a simpler ID for tracking
        let tempId = String(UUID().uuidString.prefix(6))
        self.viewId = tempId
        
        // Log initialization with the ID - use local copy to avoid capturing self
        print("🏆 LeaderboardView: init \(tempId)")
        logger.debug("LeaderboardView init \(tempId)")
        
        // Create the StateObject with fully safe configuration
        // ALWAYS use mock data initially to prevent freezing issues
        // We'll switch to real data later after the UI has rendered
        let model = LeaderboardViewModel(
            useMockData: true,      // Always start with mock data for immediate feedback
            autoLoadData: false     // Always disable auto-load to prevent freezes
        )
        self._viewModel = StateObject(wrappedValue: model)
        
        // Configure UI appearance - moved out of init to reduce complexity
        LeaderboardView.configureSegmentedControlAppearance()
    }
    */

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
                    Text("View ID: \(viewId)")
                        .font(.caption2)
                    Spacer()
                    Text("Time: \(Int(viewLifetimeSeconds))s")
                        .font(.caption2)
                }
                .padding(.horizontal)
                .font(.caption2)
                .foregroundColor(.gray)
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
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
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
            .onChange(of: LeaderboardFilterState(
                boardType: viewModel.selectedBoard,
                category: viewModel.selectedCategory,
                exerciseType: viewModel.selectedExercise
            )) { _ in
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
        Text("Leaderboard")
            .font(.title)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .bottom])
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 20) {
            // Use a simple activity indicator instead of ProgressView
            Text("⏳")
                .font(.system(size: 70))
                .padding(.bottom, 10)
                
            Text("Loading leaderboard data...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            // Use text instead of image to avoid image loading issues
            Text("🏆")
                .font(.system(size: 70))
                .padding(.bottom, 10)

            Text("No rankings found for this leaderboard.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(viewModel.selectedBoard == .local
                 ? "Try changing to Global scope or completing an exercise nearby."
                 : "Complete your first workout to get on the board.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            // Use text instead of system image to avoid issues
            Text(viewModel.backendStatus == .noActiveUsers ? "👥" : "⚠️")
                .font(.system(size: 70))
                .padding(.bottom, 10)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Special message for no users case
            if case .noActiveUsers = viewModel.backendStatus {
                Text("The Azure database doesn't have any active users yet. When users start completing workouts, they'll appear here!")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Show settings button if location permission denied
            if viewModel.selectedBoard == .local && 
               (locationPermissionStatus == .denied || 
                locationPermissionStatus == .restricted) {
                
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button("Retry") {
                // Just use fetch to reload
                if isViewActive { // Only refresh if view is active
                    Task {
                        await viewModel.fetch()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 8)
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
                    ForEach(0..<8) { i in
                        // Create a placeholder row inline
                        HStack {
                            // Rank - simplified to avoid image loading issues
                            Text("\(i+1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(width: 36)
                            
                            // Name
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 16)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            // Score
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 16)
                        }
                        .padding(.horizontal, Constants.globalPadding)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.957, green: 0.945, blue: 0.902))
                        .id("placeholder-\(i)")
                    }
                } else {
                    ForEach(viewModel.leaderboardEntries) { entry in
                        HStack {
                            // Rank - simplified to avoid image loading issues
                            Text(entry.rank <= 3 ? "🥇" : "\(entry.rank)")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 36)
                            
                            Text(entry.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(entry.score) pts")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, Constants.globalPadding)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.957, green: 0.945, blue: 0.902))
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

    // MARK: - Static Configuration Methods
    
    // Function to configure Segmented Control Appearance - static to avoid recreating on each view
    private static func configureSegmentedControlAppearance() {
        // Background color (using opaque colors)
        UISegmentedControl.appearance().backgroundColor = UIColor(red: 0.12, green: 0.14, blue: 0.12, alpha: 0.1)
        UISegmentedControl.appearance().setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

        // Text attributes with system fonts instead of custom fonts
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.darkGray
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        UISegmentedControl.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)

        // Selected segment color (gold-like)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 0.75, green: 0.64, blue: 0.30, alpha: 1.0)
    }
}

// Preview with real data configuration
#Preview {
    // Create a temporary ViewModel just for the preview
    let previewViewModel = LeaderboardViewModel() 
    // Provide a dummy viewId for the preview
    LeaderboardView(viewModel: previewViewModel, viewId: "PREVIEW")
} 