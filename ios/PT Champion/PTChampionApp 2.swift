import SwiftUI
import SwiftData

@main
struct PTChampionApp: App {
    // Instantiate AuthViewModel as a StateObject to keep it alive
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            // Use a Group to switch between views based on auth state
            Group {
                if authViewModel.isAuthenticated {
                    // Show the main app view (e.g., TabView) when authenticated
                    MainTabView() // Placeholder for the main authenticated view
                } else {
                    // Show the LoginView when not authenticated
                    LoginView()
                }
            }
            // Provide the AuthViewModel to the entire view hierarchy
            .environmentObject(authViewModel)
            // Add the SwiftData model container
            .modelContainer(for: WorkoutResultSwiftData.self)
            // Apply preferred color scheme if needed, e.g., .preferredColorScheme(.light)
        }
    }
}

// Placeholder for the main authenticated view (replace with your actual implementation)
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .dashboard // Keep track of selected tab

    // Initialize Tab Bar appearance
    init() {
        configureTabBarAppearance()
    }

    // Define Tabs Enum for clarity and type safety
    enum Tab {
        case dashboard
        case progress
        case workout
        case leaderboards
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            WorkoutHistoryView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(Tab.progress)

            WorkoutSelectionView()
                 .tabItem {
                     Label("Workout", systemImage: "figure.walk") // Consider custom icon later
                 }
                 .tag(Tab.workout)

            LeaderboardView()
                .tabItem {
                    Label("Leaders", systemImage: "list.star")
                }
                .tag(Tab.leaderboards)

             SettingsView()
                 .tabItem {
                     Label("Settings", systemImage: "gearshape.fill")
                 }
                 .tag(Tab.settings)
        }
        // Accent color is handled by UITabBarAppearance below for better control
    }

    // Function to configure Tab Bar Appearance based on Style Guide
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        // Background
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.deepOpsGreen) // Use UIColor for appearance

        // Define text attributes using AppFonts and Colors
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: AppFonts.bodyBold, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(Color.inactiveGray)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
             .font: UIFont(name: AppFonts.bodyBold, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold),
             .foregroundColor: UIColor(Color.brassGold)
        ]

        // Apply stacked layout appearance (icon and text)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.inactiveGray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brassGold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        // Apply the appearance to the standard and scroll edge appearances
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        // Optional: Remove top separator line if desired
        // appearance.shadowColor = .clear
    }
}

#Preview("MainTabView") {
    let mockAuth = AuthViewModel()
    mockAuth.isAuthenticated = true
    mockAuth.currentUser = User(id: "preview-id", email: "preview@user.com", firstName: "Preview", lastName: "User")

    return MainTabView()
        .environmentObject(mockAuth)
} 