import SwiftUI
import SwiftData
import UIKit
import Foundation
import PTDesignSystem
import ObjectiveC
import Combine

// Import local files/modules
@_exported import class UIKit.UIView  // Ensure UIView is available for swizzling

// AssistantKiller Implementation
/// Hides every `SystemInputAssistantView` the moment it is added to any window.
/// Runs exactly once per launch.
enum AssistantKiller {
    private static var done = false

    static func activate() {
        guard !done else { return }
        done = true

        // Install a one-time observer on every UIWindow that intercepts subview insertions.
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeVisibleNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let window = note.object as? UIWindow else { return }
            swizzleAddSubview(in: window)
        }
    }

    /// Replace `addSubview(_:)` with a version that hides the assistant view.
    private static func swizzleAddSubview(in window: UIWindow) {
        let cls = UIView.self
        let original = class_getInstanceMethod(cls, #selector(UIView.addSubview(_:)))!
        let replacement = class_getInstanceMethod(cls, #selector(UIView._ptc_addSubview(_:)))!
        method_exchangeImplementations(original, replacement)

        // Kick the swizzled method once on existing subviews (rarely needed but harmless)
        window.subviews.forEach { window._ptc_addSubview($0) }
    }
}

extension UIView {
    /// Safe replacement for `addSubview(_:)` that hides SystemInputAssistantView.
    @objc fileprivate func _ptc_addSubview(_ view: UIView?) {   //  parameter is now *optional*
        guard let view = view else { return }                   //  ignore nil sentinels

        // Call the original implementation (now swapped)
        _ptc_addSubview(view)

        // Delete the keyboard shortcut bar at the moment it appears
        if NSStringFromClass(type(of: view)).contains("SystemInputAssistantView") {
            view.removeFromSuperview()
            return
        }
    }
}

// --- Define NavigationState and AppScreen outside the App struct ---

// Navigation State Class
class NavigationState: ObservableObject {
    @Published var currentScreen: AppScreen = .loading
    
    func navigateTo(_ screen: AppScreen) {
        withAnimation(nil) {
            self.currentScreen = screen
        }
    }
}

// App Screen Enum
enum AppScreen {
    case loading, login, register, main
}

// FontManager class to handle font registration
class FontManager {
    static let shared = FontManager()
    
    // Font registration status
    private var fontsRegistered = false
    // Control verbose logging
    private let verboseLogging = false
    
    // Helper function for conditional logging
    private func log(_ message: String) {
        if verboseLogging {
            print(message)
        }
    }
    
    // Register all required fonts
    func registerFonts() {
        guard !fontsRegistered else { return }
        
        self.log("FONT REGISTRATION: Starting font registration process")
        
        // Define all the fonts we need to register
        let fontNames = [
            "Montserrat-Regular",
            "Montserrat-Bold",
            "Montserrat-SemiBold",
            "RobotoMono-Bold",
            "RobotoMono-Medium"
        ]
        
        // Try alternate paths where fonts might be
        let possibleFontPaths = [
            Bundle.main.bundlePath + "/Fonts/", // Custom Fonts folder
            Bundle.main.bundlePath + "/", // Root bundle
            Bundle.main.resourcePath! + "/Fonts/", // Resources/Fonts directory
            Bundle.main.resourcePath! + "/", // Resources directory
            // Add additional paths for simulator environment
            NSHomeDirectory() + "/Library/Developer/CoreSimulator/Devices/*/data/Containers/Bundle/Application/*/ptchampion.app/Fonts/"
        ]
        
        self.log("FONT REGISTRATION: Checking paths:")
        for path in possibleFontPaths {
            self.log("FONT REGISTRATION: - \(path)")
        }
        
        // Print the contents of the bundle to help debug font locations
        self.log("FONT REGISTRATION: Bundle contents:")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let fileManager = FileManager.default
                let files = try fileManager.contentsOfDirectory(atPath: resourcePath)
                for file in files {
                    self.log("FONT REGISTRATION: - \(file)")
                }
                
                // Check specifically for Fonts directory
                let fontsPath = resourcePath + "/Fonts"
                if fileManager.fileExists(atPath: fontsPath) {
                    self.log("FONT REGISTRATION: Fonts directory exists, contents:")
                    let fontFiles = try fileManager.contentsOfDirectory(atPath: fontsPath)
                    for fontFile in fontFiles {
                        self.log("FONT REGISTRATION: - \(fontFile)")
                    }
                } else {
                    self.log("FONT REGISTRATION: Fonts directory doesn't exist")
                    
                    // Create Fonts directory if it doesn't exist
                    do {
                        try fileManager.createDirectory(atPath: fontsPath, withIntermediateDirectories: true, attributes: nil)
                        self.log("FONT REGISTRATION: Created Fonts directory at \(fontsPath)")
                    } catch {
                        self.log("FONT REGISTRATION: Failed to create Fonts directory: \(error)")
                    }
                }
            } catch {
                self.log("FONT REGISTRATION: Error reading bundle contents: \(error)")
            }
        }
        
        var registeredCount = 0
        
        for fontName in fontNames {
            var fontRegistered = false
            
            // Try with both bundle resource and direct file path methods
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                self.log("FONT REGISTRATION: Found \(fontName).ttf via bundle resource")
                fontRegistered = registerFontWith(url: fontURL, fontName: fontName)
                if fontRegistered { registeredCount += 1 }
            } else if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") {
                self.log("FONT REGISTRATION: Found \(fontName).otf via bundle resource")
                fontRegistered = registerFontWith(url: fontURL, fontName: fontName)
                if fontRegistered { registeredCount += 1 }
            } else {
                self.log("FONT REGISTRATION: Trying to find \(fontName) in possible paths...")
                // Try each path with each extension (original approach)
                for path in possibleFontPaths {
                    for ext in ["ttf", "otf"] {
                        let fullPath = path + fontName + "." + ext
                        
                        if let fontURL = URL(string: "file://" + fullPath),
                           FileManager.default.fileExists(atPath: fontURL.path) {
                            self.log("FONT REGISTRATION: Found \(fontName).\(ext) at \(fullPath)")
                            fontRegistered = registerFontWith(url: fontURL, fontName: fontName)
                            if fontRegistered { 
                                registeredCount += 1
                                break
                            }
                        }
                    }
                    
                    if fontRegistered {
                        break
                    }
                }
            }
            
            if !fontRegistered {
                print("⚠️ Could not register font: \(fontName) - using system font instead")
            }
        }
        
        print("✅ Font registration complete. Registered \(registeredCount)/\(fontNames.count) fonts.")
        fontsRegistered = true
    }
    
    // Helper to register a font from a URL
    private func registerFontWith(url: URL, fontName: String) -> Bool {
        do {
            // Try loading the font data directly first
            let fontData = try Data(contentsOf: url)
            if let provider = CGDataProvider(data: fontData as CFData),
               let font = CGFont(provider) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(font, &error) {
                    // Only log success in non-verbose mode
                    if !verboseLogging {
                        print("✅ Registered: \(fontName)")
                    }
                    return true
                } else if let err = error?.takeRetainedValue() {
                    print("❌ Failed to register font: \(fontName) with error: \(err)")
                }
            } else {
                print("❌ Failed to create font from data: \(fontName)")
            }
        } catch {
            print("❌ Error loading font data for \(fontName): \(error)")
        }
        return false
    }
    
    // Helper to list all available fonts - useful for debugging
    func printAvailableFonts() {
        if verboseLogging {
            print("FONT REGISTRATION: Available system fonts:")
            for family in UIFont.familyNames.sorted() {
                print("Font Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("   Font: \(name)")
                }
            }
        } else {
            // Just print custom fonts for confirmation
            print("✅ Custom fonts registered and ready to use.")
        }
    }
}

// --- Main App Structure ---

@main
struct PTChampionApp: App {
    // Environment objects & Services that need to be @StateObject
    @StateObject private var authService: AuthService // Declared, initialized in init
    @StateObject private var featureFlagService = FeatureFlagService() // Default init works
    @StateObject private var poseDetectorService = PoseDetectorService() // Default init works
    @StateObject private var navigationState = NavigationState() // Default init works

    // ViewModels that need to be shared or initialized early
    @StateObject private var authViewModel: AuthViewModel // Declared, initialized in init
    @StateObject private var dashboardViewModel: DashboardViewModel // Declared, initialized in init
    @StateObject private var workoutViewModel: WorkoutViewModel // Declared, initialized in init
    @StateObject private var runWorkoutViewModel: RunWorkoutViewModel // Declared, initialized in init
    @StateObject private var workoutHistoryViewModel: WorkoutHistoryViewModel // Declared, initialized in init
    @StateObject private var leaderboardViewModel: LeaderboardViewModel // Declared, initialized in init
    @StateObject private var progressViewModel: ProgressViewModel // Declared, initialized in init

    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutResultSwiftData.self,
            WorkoutDataPoint.self // Make sure this is included
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Initialize FontManager first (doesn't depend on self)
        FontManager.shared.registerFonts()
        #if DEBUG
        FontManager.shared.printAvailableFonts()
        #endif
        
        // --- Step 1: Create local temp service instances ---
        let keychainService = KeychainService()
        let networkClient = NetworkClient()
        let locationService = LocationService()
        let bluetoothService = BluetoothService()
        let leaderboardService = LeaderboardService(networkClient: networkClient)
        let workoutService = WorkoutService(networkClient: networkClient)
        // Note: poseDetectorService and featureFlagService are initialized at declaration

        // --- Step 2: Create ALL temporary VM instances (using defaults/placeholders for self-dependencies) ---
        let tempAuthService = AuthService(networkClient: networkClient)
        let tempAuthViewModel = AuthViewModel()
        let tempDashboardViewModel = DashboardViewModel() // init takes no args
        let tempWorkoutViewModel = WorkoutViewModel(
             exerciseName: "pushup", // Placeholder
             // Use default PoseDetectorService() from init, DO NOT pass self.poseDetectorService here
             workoutService: workoutService,
             keychainService: keychainService,
             modelContext: nil // Set later using self.sharedModelContainer
         )
        let tempRunWorkoutViewModel = RunWorkoutViewModel(
            locationService: locationService,
            workoutService: workoutService,
            keychainService: keychainService,
            bluetoothService: bluetoothService,
            modelContext: nil // Set later using self.sharedModelContainer
        )
        let tempWorkoutHistoryViewModel = WorkoutHistoryViewModel(workoutService: workoutService) // modelContext set later
        let tempLeaderboardViewModel = LeaderboardViewModel(
            service: leaderboardService,
            location: locationService,
            keychain: keychainService
        )
        let tempProgressViewModel = ProgressViewModel(workoutService: workoutService, keychainService: keychainService)

        // --- Step 3: Assign ALL @StateObjects declared without initial value ---
        // Note: featureFlagService & poseDetectorService are initialized at declaration
        _authService = StateObject(wrappedValue: tempAuthService)
        _authViewModel = StateObject(wrappedValue: tempAuthViewModel)
        _dashboardViewModel = StateObject(wrappedValue: tempDashboardViewModel)
        _workoutViewModel = StateObject(wrappedValue: tempWorkoutViewModel) // Assign workoutViewModel here
        _runWorkoutViewModel = StateObject(wrappedValue: tempRunWorkoutViewModel)
        _workoutHistoryViewModel = StateObject(wrappedValue: tempWorkoutHistoryViewModel)
        _leaderboardViewModel = StateObject(wrappedValue: tempLeaderboardViewModel)
        _progressViewModel = StateObject(wrappedValue: tempProgressViewModel)

        // --- Step 4: `self` is now fully initialized. Perform final configuration. ---
        // Now we can safely access self.sharedModelContainer etc.
        self.dashboardViewModel.setModelContext(self.sharedModelContainer.mainContext)
        self.workoutHistoryViewModel.modelContext = self.sharedModelContainer.mainContext
        self.runWorkoutViewModel.modelContext = self.sharedModelContainer.mainContext
        self.workoutViewModel.modelContext = self.sharedModelContainer.mainContext // Set context for workout VM too
        // We are using the default PoseDetectorService created within WorkoutViewModel's init
        // If we *needed* to use the app-level self.poseDetectorService, we'd need a setter method in WorkoutViewModel
        // e.g., self.workoutViewModel.setPoseDetector(self.poseDetectorService)
        
        // Activate AssistantKiller
        #if !targetEnvironment(simulator)
            AssistantKiller.activate()
        #endif

        // Configure appearance
        AppAppearance.configureAppearance()

        #if DEBUG
        print("DEBUG mode is ON")
        #else
        print("DEBUG mode is OFF (RELEASE mode)")
        #endif
        
        // Call other setup methods
        setupGlobalServices()
    }

    private func setupGlobalServices() {
        print("Global services setup complete.")
    }
    
    func listFilesInBundle() { /* Implementation assumed */ }

    var body: some Scene {
        WindowGroup {
            Group {
                // Use NavigationState to control which view is shown
                switch navigationState.currentScreen {
                case .loading:
                    // Use the LoadingView we created
                    LoadingView()
                        .environmentObject(navigationState)
                        .environmentObject(authViewModel)
                
                case .login:
                    // Instantiate LoginView correctly and provide necessary environment objects
                    LoginView()
                        .environmentObject(authService)
                        .environmentObject(navigationState)
                        .environmentObject(featureFlagService)
                        .environmentObject(authViewModel)
                
                case .register:
                    // Show registration view when navigating to register
                    RegistrationView()
                        .environmentObject(authService)
                        .environmentObject(navigationState)
                        .environmentObject(featureFlagService)
                        .environmentObject(authViewModel)
                
                case .main:
                    // Use AuthViewModel's computed property for isAuthenticated
                    MainTabView()
                        // Pass Services
                        .environmentObject(authService)
                        .environmentObject(navigationState)
                        .environmentObject(featureFlagService)
                        .environmentObject(poseDetectorService)
                        // Pass ViewModels (Grouped)
                        .environmentObject(authViewModel)
                        .environmentObject(dashboardViewModel)
                        .environmentObject(workoutViewModel)
                        .environmentObject(runWorkoutViewModel)
                        .environmentObject(workoutHistoryViewModel)
                        .environmentObject(leaderboardViewModel)
                        .environmentObject(progressViewModel)
                }
            }
            .modelContainer(sharedModelContainer)
            .onAppear {
                // Check initial authentication state on app launch
                if navigationState.currentScreen == .loading {
                    // Let the LoadingView handle the navigation instead of doing it here
                    // This allows for a visual loading state before auto-navigating
                    print("App launched, starting with loading screen")
                }
            }
            .environmentObject(ThemeManager.shared)
            .preferredColorScheme(ThemeManager.shared.effectiveColorScheme)
        }
    }
}

// Define Tab enum for MainTabView
enum Tab {
    case home, history, /*workout,*/ leaderboards, profile // Workout tab commented out
}

// Main TabView Structure
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var featureFlagService: FeatureFlagService
    @EnvironmentObject var leaderboardVM: LeaderboardViewModel // Use the VM passed from environment

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            WorkoutHistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            // Corrected LeaderboardView call - passes viewModel from environment
            LeaderboardView(viewModel: leaderboardVM, viewId: "mainTabLeaderboard")
                .tabItem { Label("Leaders", systemImage: "rosette") }
                .tag(Tab.leaderboards)

            ProfileView() // Replaced SettingsView with ProfileView
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .onAppear { /* Optional: Customize TabView appearance */ }
        .onChange(of: selectedTab) { newTab in
            print("Switched to tab: \(newTab)")
        }
    }
}

// --- Preview Providers (Corrected Initializers) ---
#if DEBUG
// Helper function to create a ModelContainer for previews
@MainActor
func createPreviewModelContainer() -> ModelContainer {
    let schema = Schema([
        WorkoutResultSwiftData.self,
        WorkoutDataPoint.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer for preview: \(error)")
    }
}

struct PTChampionApp_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock services and view models for preview
        let mockAuthService = AuthService(networkClient: NetworkClient()) // Use correct init
        let mockNavigationState = NavigationState()
        let mockFeatureFlagService = FeatureFlagService()
        
        let mockAuthViewModel = AuthViewModel() // Correct: Takes no args

        // Call LoginView without arguments
        LoginView()
            .environmentObject(mockAuthService) // Keep providing this if any subview needs it
            .environmentObject(mockNavigationState) // Provide NavigationState
            .environmentObject(mockFeatureFlagService) // Keep providing this
            .environmentObject(mockAuthViewModel) // Provide AuthViewModel
            // Use the helper for preview container
            .modelContainer(createPreviewModelContainer()) 
    }
}

// Preview for MainTabView specifically
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock services and view models needed by MainTabView and its children
        let mockAuthService = AuthService(networkClient: NetworkClient())
        let mockNavigationState = NavigationState()
        let mockFeatureFlagService = FeatureFlagService()
        let mockNetworkClient = NetworkClient()
        
        let mockLeaderboardService = LeaderboardService(networkClient: mockNetworkClient)
        let mockLocationService = LocationService()
        let mockKeychainService = KeychainService()
        let mockLeaderboardVM = LeaderboardViewModel(
            service: mockLeaderboardService, 
            location: mockLocationService, 
            keychain: mockKeychainService
        )
        
        MainTabView()
            .environmentObject(mockAuthService)
            .environmentObject(mockNavigationState)
            .environmentObject(mockFeatureFlagService)
            .environmentObject(mockLeaderboardVM) 
            // Ensure other necessary VMs/Services needed by child views are provided for preview
            // e.g., DashboardViewModel, WorkoutHistoryViewModel, SettingsView dependencies
            // Use the helper for preview container
            .modelContainer(createPreviewModelContainer()) 
    }
}
#endif

// Add a convenience extension to check auth state (If not already defined elsewhere)
// extension AuthState {
//     var isAuthenticated: Bool {
//         if case .authenticated = self {
//             return true
//         }
//         return false
//     }
//     
//     var user: AuthUserModel? {
//         if case .authenticated(let user) = self {
//             return user
//         }
//         return nil
//     }
// } 