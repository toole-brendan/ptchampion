import SwiftUI
import CoreLocation // For CLAuthorizationStatus
import UIKit // For UIApplication

struct LeaderboardView: View {
    // Define constants directly
    private struct Constants {
        static let globalPadding: CGFloat = 16
    }
    
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    // Apply appearance changes in init
    init() {
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
                
                Picker("", selection: $viewModel.selectedCategory) {
                    ForEach(LeaderboardCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)

                // Content Area (List or Messages)
                ZStack {
                    // Make list background match overall background
                    Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea()

                    if viewModel.isLoading {
                        ProgressView()
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 10) {
                             Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.orange)
                             Text(errorMessage)
                                 .foregroundColor(.secondary)
                                 .multilineTextAlignment(.center)
                                 .padding(.horizontal)

                             // Show settings button if permission denied
                             if viewModel.selectedBoard == .local &&
                                (viewModel.locationPermissionStatus == .denied || viewModel.locationPermissionStatus == .restricted) {
                                 Button("Open Settings") {
                                     if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                         UIApplication.shared.open(url)
                                     }
                                 }
                                 .padding(.horizontal, 16)
                                 .padding(.vertical, 10)
                                 .background(Color.blue)
                                 .foregroundColor(.white)
                                 .font(.headline)
                                 .cornerRadius(8)
                                 .padding(.top)
                             }
                        }
                        .padding()
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
                        .refreshable { // Pull to refresh
                            viewModel.refreshData()
                        }
                    }
                }
            }
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Observe location permission changes if needed for immediate UI updates
        // .onChange(of: viewModel.locationPermissionStatus) { ... }
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

// Example Leaderboard Row (move to Shared Views later)
struct LeaderboardRow: View {
    let entry: LeaderboardEntry // Use the actual model

    var body: some View {
        HStack {
            Text("\(entry.rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)
            Text(entry.name)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text("\(entry.score) pts")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    let mockViewModel = LeaderboardViewModel()
    // Add sample data if needed
    
    return LeaderboardView()
} 