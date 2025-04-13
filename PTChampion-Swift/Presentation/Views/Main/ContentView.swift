import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            // Tab 1: Exercises / Start Workout
            ExerciseListView() // Assuming this view exists or will be created
                .tabItem {
                    Label("Workout", systemImage: "figure.walk")
                }
            
            // Tab 2: Workout History
            WorkoutHistoryView() // Needs to be created
                 .tabItem {
                     Label("History", systemImage: "list.bullet.rectangle.portrait")
                 }
            
            // Tab 3: Leaderboards
             LeaderboardView() // Needs to be created
                 .tabItem {
                     Label("Leaderboards", systemImage: "trophy")
                 }

            // Tab 4: Profile / Settings
            ProfileView() // Needs to be created
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        // Pass AuthManager down if needed by subviews
        // .environmentObject(authManager) 
    }
}

// Placeholder Views for Tabs (Replace with actual implementations later)
struct ExerciseListView: View {
    var body: some View { Text("Exercise List / Start Workout Screen").font(.title) }
}

struct WorkoutHistoryView: View {
     var body: some View { Text("Workout History Screen").font(.title) }
}

struct LeaderboardView: View {
     var body: some View { Text("Leaderboards Screen").font(.title) }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    var body: some View { 
        VStack {
            Text("Profile Screen").font(.title)
            Text("Logged in as: \(authManager.currentUser?.username ?? "Unknown")")
            Button("Logout") {
                authManager.logout()
            }
            .buttonStyle(PTButtonStyle(style: .danger, size: .normal))
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager()) // Provide dummy for preview
    }
} 