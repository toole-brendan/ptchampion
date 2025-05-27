// AppInitializationFix.swift
// Fixes for preventing app freeze during initialization

import SwiftUI

// Update your main App file (remove @main from existing PTChampionApp.swift and use this instead)
// @main
struct PTChampionAppFixed: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isInitialized = false
    
    init() {
        // Configure logging first
        configureLogging()
        
        // Register fonts early but don't block
        DispatchQueue.global(qos: .userInitiated).async {
            FontManager.shared.registerFonts()
        }
        
        // Setup appearance
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            if isInitialized {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(OrientationManager.shared)
                    .onAppear {
                        // Setup authentication observer
                        authViewModel.setupAuthenticationObserver()
                    }
            } else {
                // Show a simple loading view while initializing
                InitializationView()
                    .onAppear {
                        performAsyncInitialization()
                    }
            }
        }
    }
    
    private func configureLogging() {
        #if DEBUG
        ConsoleLogger.shared.enableDebugLogs = true
        ConsoleLogger.shared.enableViewInitLogs = false // Disable to reduce noise
        #else
        ConsoleLogger.shared.enableDebugLogs = false
        ConsoleLogger.shared.enableViewInitLogs = false
        #endif
    }
    
    private func setupAppearance() {
        // Your appearance setup code
    }
    
    private func performAsyncInitialization() {
        Task {
            logInfo("Starting app initialization")
            
            // Initialize services in parallel where possible
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.initializeNetworkServices()
                }
                
                group.addTask {
                    await self.initializeHealthKit()
                }
                
                group.addTask {
                    await self.initializeLocationServices()
                }
            }
            
            // Check authentication state
            await checkAuthenticationState()
            
            // Complete initialization
            await MainActor.run {
                self.isInitialized = true
                logInfo("App initialization complete")
            }
        }
    }
    
    private func initializeNetworkServices() async {
        // Initialize network monitoring
        NetworkMonitor.shared.startMonitoring()
    }
    
    private func initializeHealthKit() async {
        // Initialize HealthKit if needed
    }
    
    private func initializeLocationServices() async {
        // Initialize location services if needed
    }
    
    private func checkAuthenticationState() async {
        // Check if we have a valid token
        if let token = try? KeychainService.shared.getToken() {
            logInfo("Found existing auth token")
            // Validate token with a lightweight endpoint
            do {
                let isValid = try await validateToken(token)
                if !isValid {
                    logWarning("Auth token is invalid")
                    try? KeychainService.shared.deleteToken()
                    await MainActor.run {
                        // Use the logout method to clear auth state
                        authViewModel.logout()
                    }
                }
            } catch {
                logError("Failed to validate token: \(error)")
            }
        } else {
            logInfo("No auth token found")
            await MainActor.run {
                authViewModel.logout()
            }
        }
    }
    
    private func validateToken(_ token: String) async throws -> Bool {
        // Make a lightweight API call to validate the token
        var request = URLRequest(url: URL(string: "\(NetworkClient.shared.apiBaseURL)/auth/validate")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        
        return false
    }
}

// Simple initialization view
struct InitializationView: View {
    @State private var dotCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image("pt_champion_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("PT Champion")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 4) {
                Text("Loading")
                ForEach(0..<3) { index in
                    Text(".")
                        .opacity(index < dotCount ? 1 : 0.3)
                }
            }
            .font(.headline)
            .foregroundColor(.secondary)
            .onAppear {
                startLoadingAnimation()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// Note: WorkoutSessionView calibration logic is already handled in the view itself
// No additional extension needed here

// Network Monitor for handling connectivity
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }
    
    private init() {}
    
    func startMonitoring() {
        // Implementation for network monitoring
        logInfo("Network monitoring started")
    }
} 