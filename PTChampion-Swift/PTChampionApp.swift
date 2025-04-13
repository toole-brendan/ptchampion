import SwiftUI

@main
struct PTChampionApp: App {
    // Create the single source of truth for authentication state
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            // Conditionally show Login/Register or main content
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager) // Provide AuthManager to authenticated views
            } else {
                // Start with LoginView, allow navigation to RegisterView
                LoginView()
                    .environmentObject(authManager) // Provide AuthManager to auth views
            }
        }
    }
} 