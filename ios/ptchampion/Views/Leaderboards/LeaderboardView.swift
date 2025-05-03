import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication
import os.log
import Combine

// Setup logger for this view
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardView")

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
    
    // Track time spent in this view for analytics
    @State private var viewAppearTime: Date? = nil
    @State private var viewLifetimeSeconds: TimeInterval = 0
    @State private var viewAnalyticsTimer: Timer? = nil
    
    // Track pending data load to prevent multiple loads
    @State private var pendingDataLoad: DispatchWorkItem? = nil

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
                
                // Category and type pickers
                categoryPickerView()
                typePickerView()
                
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

                // Content Area based on loading state
                contentView()
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            startViewAppearance()
        }
        .onDisappear {
            handleViewDisappearance()
        }
        .onChange(of: viewModel.selectedBoard) { newValue in
            // Cancel any pending data load
            pendingDataLoad?.cancel()
            
            // Schedule a new debounced data load
            scheduleDataLoad(after: Constants.debounceInterval)
        }
        .onChange(of: viewModel.selectedCategory) { newValue in
            // Cancel any pending data load
            pendingDataLoad?.cancel()
            
            // Schedule a new debounced data load
            scheduleDataLoad(after: Constants.debounceInterval)
        }
    }
    
    // MARK: - Lifecycle Management
    
    private func startViewAppearance() {
        print("🏆 LeaderboardView: appeared \(viewId)")
        logger.debug("LeaderboardView appeared \(viewId)")
        
        // Record appearance time for analytics
        viewAppearTime = Date()
        
        // Start timer to track view lifetime
        viewAnalyticsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let appearTime = viewAppearTime {
                viewLifetimeSeconds = Date().timeIntervalSince(appearTime)
            }
        }
        
        // Only update active state if needed
        if !isViewActive {
            isViewActive = true
            // Add analytics logging
            print("🔍 LeaderboardView[\(viewId)]: onAppear - current Thread: \(Thread.current.description)")
            print("🔍 LeaderboardView[\(viewId)]: onAppear - viewModel.isLoading: \(viewModel.isLoading)")
            print("🔍 LeaderboardView[\(viewId)]: onAppear - entries count: \(viewModel.leaderboardEntries.count)")
            
            // REMOVED: Data load is now handled by the persistent ViewModel
            // scheduleDataLoad(after: Constants.appearDelay)
        } else {
            print("🔍 LeaderboardView[\(viewId)]: onAppear - view was already active, state should be current")
        }
    }
    
    private func handleViewDisappearance() {
        print("🏆 LeaderboardView: disappeared \(viewId)")
        logger.debug("LeaderboardView disappeared \(viewId)")
        
        // Save analytics data
        if let appearTime = viewAppearTime {
            let totalTime = Date().timeIntervalSince(appearTime)
            print("🔍 LeaderboardView[\(viewId)]: View was visible for \(totalTime) seconds")
        }
        
        // Clean up timer
        viewAnalyticsTimer?.invalidate()
        viewAnalyticsTimer = nil
        viewAppearTime = nil
        
        // Cancel any pending data load
        pendingDataLoad?.cancel()
        pendingDataLoad = nil
        
        // Track view disappearance
        print("🔍 LeaderboardView[\(viewId)]: onDisappear - current Thread: \(Thread.current.description)")
        print("🔍 LeaderboardView[\(viewId)]: onDisappear - viewModel.isLoading: \(viewModel.isLoading)")
        
        // Mark view as inactive first to prevent new operations from starting
        isViewActive = false
        
        // Using the new comprehensive cleanup method instead of multiple steps
        // This is more reliable and prevents UI freezes during cleanup
        DispatchQueue.main.async { [weak viewModel] in
            viewModel?.performCompleteCleanup()
        }
    }
    
    // Schedule data loading with a delay
    private func scheduleDataLoad(after delay: TimeInterval) {
        // This function is no longer called by onAppear, 
        // but kept for potential use by filter pickers
        pendingDataLoad?.cancel()
        
        let workItem = DispatchWorkItem { [weak viewModel] in
            guard let viewModel = viewModel, isViewActive else { return }
            
            print("🔍 LeaderboardView[\(viewId)]: Starting data load after \(delay)s delay")
            viewModel.refreshData()
        }
        
        pendingDataLoad = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
    private func categoryPickerView() -> some View {
        Picker("Category", selection: $viewModel.selectedCategory) {
            ForEach(LeaderboardCategory.allCases, id: \.id) { category in
                Text(category.displayName).tag(category)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
        // Disable picker interactions when loading to prevent state issues
        .disabled(viewModel.isLoading)
    }
    
    @ViewBuilder
    private func typePickerView() -> some View {
        Picker("Type", selection: $viewModel.selectedBoard) {
            ForEach(LeaderboardType.allCases, id: \.id) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        // Disable picker interactions when loading to prevent state issues
        .disabled(viewModel.isLoading)
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        // Wrap the entire content view in a GeometryReader to ensure proper sizing
        GeometryReader { geometry in
            ZStack {
                if viewModel.isLoading {
                    loadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.leaderboardEntries.isEmpty {
                    emptyStateView()
                } else {
                    leaderboardListView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading leaderboard data...")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No rankings found for this leaderboard.")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try selecting a different category or complete your first workout to get on the board.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            // Different icons based on error type
            Group {
                switch viewModel.backendStatus {
                case .noActiveUsers:
                    Image(systemName: "person.3")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                case .timedOut:
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                default:
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                }
            }
            
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
               (viewModel.locationPermissionStatus == .denied || 
                viewModel.locationPermissionStatus == .restricted) {
                
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
                // Just use refreshData to reload
                if isViewActive { // Only refresh if view is active
                    viewModel.refreshData()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 8)
            
            // Debug button to show mock data
            #if DEBUG
            Button("Use Mock Data") {
                print("🏆 LeaderboardView: Switching to mock data")
                logger.debug("LeaderboardView: Switching to mock data mode")
                if isViewActive { // Only switch if view is active
                    viewModel.switchToMockData()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.caption)
            .padding(.top, 4)
            #endif
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
                        // Create a placeholder row inline to avoid importing external files
                        HStack {
                            // Rank
                            Text("#")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.clear)
                                .frame(width: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                )
                            
                            // Avatar
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .padding(.leading, 4)
                            
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
                        .padding([.horizontal], Constants.globalPadding)
                        .padding([.vertical], 8)
                        .background(Color(red: 0.957, green: 0.945, blue: 0.902))
                        .id("placeholder-\(i)")
                    }
                } else {
                    ForEach(viewModel.leaderboardEntries) { entry in
                        LeaderboardRow(entry: entry)
                            .padding(.horizontal, Constants.globalPadding)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.957, green: 0.945, blue: 0.902))
                            // Add an ID to help SwiftUI with diffing
                            .id(entry.id)
                    }
                }
            }
        }
        .refreshable { 
            print("🏆 LeaderboardView: Pull-to-refresh triggered")
            if isViewActive { // Only refresh if view is active
                viewModel.refreshData()
            }
        }
        // Single onAppear handler with a proper sequence:
        // 1. Show mock data immediately
        // 2. After a very short delay, try real data if available
        .onAppear {
            if isViewActive {
                // First, make sure we have mock data displaying
                if viewModel.leaderboardEntries.isEmpty && !viewModel.isLoading {
                    viewModel.switchToMockData() // Force mock data if empty
                }
                
                // Then after a short delay, attempt to load real data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak viewModel] in
                    guard isViewActive, let viewModel = viewModel else { return }
                    print("🏆 LeaderboardView: Attempting to load real data after mock data render")
                    viewModel.tryRealDataIfNeeded()
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

// Placeholder row for the loading state
struct LeaderboardRowPlaceholder: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            // Rank placeholder
            Text("#")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.clear)
                .frame(width: 32, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                        .frame(width: 28, height: 28)
                )
            
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                .frame(width: 40, height: 40)
                .padding(.leading, 4)
            
            // Username placeholder
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                    .frame(width: 120, height: 16)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Score placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.2))
                .frame(width: 50, height: 16)
        }
        .frame(height: 60)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

// Leaderboard Row
struct LeaderboardRow: View {
    let entry: LeaderboardEntry // Use the actual model

    var body: some View {
        HStack {
            // Rank with medal for top 3
            if entry.rank <= 3 {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.75, green: 0.64, blue: 0.30).opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color(red: 0.75, green: 0.64, blue: 0.30))
                        .font(.system(size: 16))
                }
            } else {
                Text("\(entry.rank)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 36)
            }
            
            Text(entry.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(entry.score) pts")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
    }
}

// Always use mock data in previews
#Preview {
    // Create a temporary ViewModel just for the preview
    let mockViewModel = LeaderboardViewModel(useMockData: true, autoLoadData: false) 
    // Provide a dummy viewId for the preview
    LeaderboardView(viewModel: mockViewModel, viewId: "PREVIEW")
} 