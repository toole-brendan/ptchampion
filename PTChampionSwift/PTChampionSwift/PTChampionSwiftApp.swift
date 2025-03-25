import SwiftUI

@main
struct PTChampionSwiftApp: App {
    // The authentication view model will be used throughout the app to manage user state
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Start with the root view, which handles navigation based on authentication state
            RootView()
                .environmentObject(authViewModel)
        }
    }
}