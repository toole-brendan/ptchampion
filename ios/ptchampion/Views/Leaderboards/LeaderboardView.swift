import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication
import os.log

// Setup logger for this view
private let logger = Logger(subsystem: "com.ptchampion", category: "LeaderboardView")

struct LeaderboardView: View {
    // Define constants directly
    private struct Constants {
        static let globalPadding: CGFloat = 16
    }
    
    // Use a StateObject with conditional initialization - IMPORTANT: This was causing freezes!
    // Instead of creating a new StateObject directly in the property, create it in init()
    @StateObject private var viewModel: LeaderboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Track this view's lifecycle for debugging
    private let viewId: String
    
    // Track if view is active to prevent unnecessary updates
    @State private var isViewActive = false

    // Apply appearance changes in init
    init() {
        // Create a simpler ID for tracking
        let tempId = String(UUID().uuidString.prefix(6))
        self.viewId = tempId
        
        // Log initialization with the ID - use local copy to avoid capturing self
        print("🏆 LeaderboardView: init \(tempId)")
        logger.debug("LeaderboardView init \(tempId)")
        
        // Create the StateObject with explicit non-blocking configuration
        let model = LeaderboardViewModel(useMockData: true, autoLoadData: false)
        self._viewModel = StateObject(wrappedValue: model)
        
        // Configure UI appearance - move out of init to reduce complexity
        LeaderboardView.configureSegmentedControlAppearance()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                headerView()
                
                // Category and type pickers
                categoryPickerView()
                typePickerView()

                // Content Area based on loading state
                contentView()
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("🏆 LeaderboardView: appeared \(viewId)")
            logger.debug("LeaderboardView appeared \(viewId)")
            
            // Only load data if view wasn't already active
            if !isViewActive {
                isViewActive = true
                
                // ADDED: More detailed diagnostics
                print("🔍 LeaderboardView[\(viewId)]: onAppear - current Thread: \(Thread.current.description)")
                print("🔍 LeaderboardView[\(viewId)]: onAppear - viewModel.isLoading: \(viewModel.isLoading)")
                print("🔍 LeaderboardView[\(viewId)]: onAppear - entries count: \(viewModel.leaderboardEntries.count)")
                
                // Use a small delay to ensure UI is ready before starting data load
                // This helps prevent freezes when rapidly switching tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if isViewActive { // Check if still active after delay
                        print("🔍 LeaderboardView[\(viewId)]: Starting data load after short delay")
                        viewModel.refreshData()
                    }
                }
            } else {
                print("🔍 LeaderboardView[\(viewId)]: onAppear - view was already active, not reloading data")
            }
        }
        .onDisappear {
            print("🏆 LeaderboardView: disappeared \(viewId)")
            logger.debug("LeaderboardView disappeared \(viewId)")
            
            // ADDED: Track when view disappears
            print("🔍 LeaderboardView[\(viewId)]: onDisappear - current Thread: \(Thread.current.description)")
            print("🔍 LeaderboardView[\(viewId)]: onDisappear - viewModel.isLoading: \(viewModel.isLoading)")
            
            // Mark view as inactive first to prevent new operations from starting
            isViewActive = false
            
            // ADDED: Cancel any active tasks with the MainActor method
            viewModel.cancelTasksFromMainActor()
            
            // Then clean up state with the isolated method
            viewModel.cleanupAfterCancellation()
            
            // ADDED: Also reset UI state to default to avoid state inconsistency
            viewModel.resetState()
        }
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
        Text("No entries found for this leaderboard.")
            .foregroundColor(.secondary)
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
        // Use a ScrollView instead of List for better performance in this case
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.leaderboardEntries) { entry in
                    LeaderboardRow(entry: entry)
                        .padding(.horizontal, Constants.globalPadding)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.957, green: 0.945, blue: 0.902))
                }
            }
        }
        .refreshable { 
            print("🏆 LeaderboardView: Pull-to-refresh triggered")
            if isViewActive { // Only refresh if view is active
                viewModel.refreshData()
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

#Preview {
    let mockViewModel = LeaderboardViewModel(useMockData: true, autoLoadData: false) 
    return LeaderboardView()
} 