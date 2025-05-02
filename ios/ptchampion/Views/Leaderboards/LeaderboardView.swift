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
    
    @StateObject private var viewModel = LeaderboardViewModel(useMockData: false)
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Track this view's lifecycle for debugging
    private let viewId = UUID().uuidString.prefix(6)

    // Apply appearance changes in init
    init() {
        // Extract the ID to a local constant before using in the log statement
        let viewIdentifier = viewId
        logger.debug("LeaderboardView init \(viewIdentifier)")
        configureSegmentedControlAppearance()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // Use spacing 0 for closer list
                // Replace DashboardHeader with a simple title
                Text("Leaderboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .bottom])
                
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(LeaderboardCategory.allCases, id: \.id) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)

                // Scope toggle for global vs local
                Picker("Type", selection: $viewModel.selectedBoard) {
                    ForEach(LeaderboardType.allCases, id: \.id) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                // Content Area based on loading state
                ZStack {
                    if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("Loading leaderboard data...")
                                .foregroundColor(.secondary)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            // Different icons based on error type
                            Group {
                                if viewModel.backendStatus == .noActiveUsers {
                                    Image(systemName: "person.3")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                } else if viewModel.backendStatus == .timedOut {
                                    Image(systemName: "clock")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Special message for no users case
                            if viewModel.backendStatus == .noActiveUsers {
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
                                Task {
                                    await viewModel.fetchLeaderboardData()
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
                                // Instead of replacing the existing viewModel (which would break SwiftUI's state management),
                                // just configure it to use mock data
                                Task {
                                    logger.debug("Switching to mock data mode")
                                    // Force current viewModel to use mock data and refresh
                                    viewModel.switchToMockData()
                                    await viewModel.fetchLeaderboardData()
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
                    } else if viewModel.leaderboardEntries.isEmpty {
                         Text("No entries found for this leaderboard.")
                             .foregroundColor(.secondary)
                             .padding()
                    } else {
                        List {
                            ForEach(viewModel.leaderboardEntries) { entry in
                                LeaderboardRow(entry: entry)
                                    .listRowInsets(EdgeInsets(top: 8, leading: Constants.globalPadding, bottom: 8, trailing: Constants.globalPadding))
                                    .listRowSeparator(.hidden) // Hide default separators
                                    .listRowBackground(Color(red: 0.957, green: 0.945, blue: 0.902)) // Match list row background
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable { 
                            await viewModel.fetchLeaderboardData()
                        }
                    }
                }
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            logger.debug("LeaderboardView appeared \(viewId)")
            // Ensure we fetch data when view appears
            Task {
                await viewModel.fetchLeaderboardData()
            }
        }
        .onDisappear {
            logger.debug("LeaderboardView disappeared \(viewId)")
        }
    }

    // Function to configure Segmented Control Appearance
    private func configureSegmentedControlAppearance() {
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
    let entry: LeaderboardViewModel.LeaderboardEntry // Fully qualify the type

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
    let mockViewModel = LeaderboardViewModel(useMockData: true)
    LeaderboardView()
} 