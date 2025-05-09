import SwiftUI
import PTDesignSystem // Assuming your custom components are here

struct ContentView: View {
    // ViewModels for each tab - initialize or inject as per your app's architecture
    // Using @StateObject for ViewModels owned by this view
    // Note: For a real app, consider how AuthViewModel is provided if it's truly global.
    // It might be better as an @EnvironmentObject injected from a higher level (e.g., App struct).
    @StateObject private var authViewModel = AuthViewModel() 
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    // You would also need @StateObject for WorkoutHistoryViewModel and potentially ProfileViewModel
    @StateObject private var workoutHistoryViewModel = WorkoutHistoryViewModel() // Assuming this exists
    // For ProfileView, if it's simple, it might not need its own ViewModel, or it might use AuthViewModel.

    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                // Pass environment objects if needed by DashboardView directly or its children
                DashboardView()
                    .environmentObject(authViewModel)
                    // If DashboardViewModel is not passed directly, it should be @StateObject in DashboardView
                    // or passed as viewModel: dashboardViewModel if it's initialized here.
                    // For this example, let's assume DashboardView initializes its own or uses an EnvObject.
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            // History Tab
            NavigationStack {
                // Similar ViewModel considerations for WorkoutHistoryView
                WorkoutHistoryView() // Assuming WorkoutHistoryView initializes its own ViewModel or doesn't need one explicitly passed here for basic structure.
            }
            .tabItem {
                Label("History", systemImage: "list.bullet.rectangle.fill")
            }

            // Leaderboard Tab
            NavigationStack { 
                LeaderboardView(viewModel: leaderboardViewModel, viewId: "mainLeaderboard")
            }
            .tabItem {
                Label("Leaderboard", systemImage: "star.fill")
            }

            // Profile Tab
            NavigationStack {
                ProfileView()
                    .environmentObject(authViewModel) // ProfileView might need AuthViewModel for user details/logout
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        // If AuthViewModel is truly global and used by multiple first-level views in tabs,
        // providing it here once can be cleaner than in each NavigationStack's root.
        // However, some views might re-initialize their own navigation context if not careful.
        // For now, providing to specific stacks where known to be needed.
    }
}

#Preview {
    ContentView()
        // For previews to work correctly, especially if views use @EnvironmentObject,
        // you need to provide mock/real instances here.
        .environmentObject(AuthViewModel()) // Example
        // .modelContext(...) // If using SwiftData and any tab needs it directly or indirectly
} 