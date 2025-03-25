import SwiftUI

@main
struct PTChampionSwiftApp: App {
    // Create a shared instance of AuthViewModel that will be available throughout the app
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}