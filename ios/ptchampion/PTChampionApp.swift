import SwiftUI
import SwiftData
import UIKit

// Add import for AppAppearance
import Foundation

@main
struct PTChampionApp: App {
    // Instantiate AuthViewModel as a StateObject to keep it alive
    @StateObject private var authViewModel = AuthViewModel()
    
    // Initialize app appearance
    init() {
        // Configure appearance manually without relying on external class
        configureUIAppearance()
    }
    
    // Configure UI appearance manually
    private func configureUIAppearance() {
        // Configure TabBar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure NavigationBar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        }
    }

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
    
    // Expose ComponentGallery in debug builds for design review
    @State private var showingComponentGallery = false

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

            #if DEBUG
            // Temporarily comment out ComponentGalleryView reference
            // Replace with SettingsView to match production
            SettingsView()
                .tabItem {
                    Label("Design System", systemImage: "square.grid.2x2.fill")
                }
            #else
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
            #endif
        }
        // Accent color is handled by UITabBarAppearance
        .onShake {
            #if DEBUG
            // Don't show component gallery since it's not available
            // showingComponentGallery.toggle()
            #endif
        }
        .sheet(isPresented: $showingComponentGallery) {
            // Temporarily comment out ComponentGalleryView and replace with a placeholder
            Text("Component Gallery View")
        }
    }
}

// Add device shake detection for easier component gallery access in development
#if DEBUG
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}
#endif

#Preview("MainTabView") {
    let view = {
        let mockAuth = AuthViewModel()
        mockAuth.isAuthenticated = true
        mockAuth.currentUser = User(id: "preview-id", email: "preview@user.com", firstName: "Preview", lastName: "User", profilePictureUrl: nil)
        
        return MainTabView()
            .environmentObject(mockAuth)
    }()
    
    return view
} 