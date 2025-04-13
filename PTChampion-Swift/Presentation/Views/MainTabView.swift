import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case exercises
        case history
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Dashboard Tab
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(Tab.home)
            
            // Exercises Tab
            NavigationView {
                ExerciseListView()
            }
            .tabItem {
                Label("Exercises", systemImage: "figure.run")
            }
            .tag(Tab.exercises)
            
            // History Tab
            NavigationView {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "chart.bar.fill")
            }
            .tag(Tab.history)
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
        .accentColor(.blue)
    }
}

// Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

// Placeholder views (to be implemented in detail)
struct DashboardView: View {
    var body: some View {
        Text("Dashboard View")
            .navigationTitle("PT Champion")
    }
}

struct ExerciseListView: View {
    var body: some View {
        Text("Exercise List View")
            .navigationTitle("Exercises")
    }
}

struct HistoryView: View {
    var body: some View {
        Text("History View")
            .navigationTitle("Performance History")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View")
            .navigationTitle("Profile")
    }
}