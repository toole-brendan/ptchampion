import SwiftUI
import CoreLocation // For CLAuthorizationStatus

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    // Apply appearance changes in init
    init() {
        configureSegmentedControlAppearance()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // Use spacing 0 for closer list
                Picker("Leaderboard Type", selection: $viewModel.selectedBoard) {
                    ForEach(LeaderboardType.allCases) { boardType in
                        Text(boardType.rawValue).tag(boardType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, AppConstants.globalPadding)
                .padding(.vertical, 10)
                .background(Color.tacticalCream) // Ensure picker background matches

                // Content Area (List or Messages)
                ZStack {
                    // Make list background match overall background
                    Color.tacticalCream.ignoresSafeArea()

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
                                 .foregroundColor(.tacticalGray)
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
                                 .buttonStyle(PrimaryButtonStyle())
                                 .padding(.top)
                             }
                        }
                        .padding()
                    } else if viewModel.leaderboardEntries.isEmpty {
                         Text("No entries found for this leaderboard.")
                             .foregroundColor(.tacticalGray)
                             .padding()
                    } else {
                        List {
                            ForEach(viewModel.leaderboardEntries) { entry in
                                LeaderboardRow(entry: entry)
                                    .listRowInsets(EdgeInsets(top: 8, leading: AppConstants.globalPadding, bottom: 8, trailing: AppConstants.globalPadding))
                                    .listRowSeparator(.hidden) // Hide default separators
                                    .listRowBackground(Color.tacticalCream) // Match list row background
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable { // Pull to refresh
                            viewModel.refreshData()
                        }
                    }
                }
            }
            .background(Color.tacticalCream.ignoresSafeArea())
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Observe location permission changes if needed for immediate UI updates
        // .onChange(of: viewModel.locationPermissionStatus) { ... }
    }

    // Function to configure Segmented Control Appearance
    private func configureSegmentedControlAppearance() {
        // Background and divider colors
        UISegmentedControl.appearance().backgroundColor = UIColor(Color.deepOpsGreen.opacity(0.1))
        UISegmentedControl.appearance().setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

        // Text attributes
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: AppFonts.body, size: 13) ?? UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor(Color.tacticalGray)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: AppFonts.bodyBold, size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(Color.commandBlack) // Text color on gold background
        ]

        UISegmentedControl.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)

        // Selected segment color
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.brassGold)
    }
}

// Example Leaderboard Row (move to Shared Views later)
struct LeaderboardRow: View {
    let entry: LeaderboardEntry // Use the actual model

    var body: some View {
        HStack {
            Text("\(entry.rank)")
                .font(.headline)
                .foregroundColor(.tacticalGray)
                .frame(width: 30, alignment: .center)
            Text(entry.name)
                .font(.body)
                .foregroundColor(.commandBlack)
            Spacer()
            Text("\(entry.score) pts")
                .statsNumberStyle(size: 16)
        }
    }
}

#Preview {
    LeaderboardView()
} 