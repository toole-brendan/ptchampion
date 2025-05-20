import SwiftUI
import SwiftData
import UIKit
import Foundation
import PTDesignSystem
import ObjectiveC
import Combine
import HealthKit
import BackgroundTasks
import GoogleSignIn  // Add GoogleSignIn import


// Import local files/modules
@_exported import class UIKit.UIView  // Ensure UIView is available for swizzling

// No typealiases needed - use direct references

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
    private let verboseLogging = true
    
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
            "FuturaPT-Regular",
            "FuturaPT-Medium",
            "FuturaPT-Bold",
            "Consolas"
        ]
        
        // Try alternate paths where fonts might be
        let possibleFontPaths = [
            Bundle.main.bundlePath + "/Fonts/", // Custom Fonts folder
            Bundle.main.bundlePath + "/", // Root bundle
            Bundle.main.resourcePath! + "/Fonts/", // Resources/Fonts directory
            Bundle.main.resourcePath! + "/", // Resources directory
        ]
        
        // Print the bundle identifier and paths we're checking
        print("FONT REGISTRATION: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("FONT REGISTRATION: Bundle path: \(Bundle.main.bundlePath)")
        print("FONT REGISTRATION: Resource path: \(Bundle.main.resourcePath ?? "unknown")")
        
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
                    print("FONT REGISTRATION: Fonts directory doesn't exist at: \(fontsPath)")
                }
                
                // Check Info.plist for font declaration
                if let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
                   let infoPlistData = FileManager.default.contents(atPath: infoPlistPath),
                   let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, format: nil) as? [String: Any],
                   let uiAppFonts = infoPlist["UIAppFonts"] as? [String] {
                    print("FONT REGISTRATION: Fonts declared in Info.plist: \(uiAppFonts)")
                } else {
                    print("⚠️ FONT REGISTRATION: No fonts declared in Info.plist or couldn't read plist")
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
                print("FONT REGISTRATION: Found \(fontName).ttf via bundle resource at \(fontURL.path)")
                fontRegistered = registerFontWith(url: fontURL, fontName: fontName)
                if fontRegistered { registeredCount += 1 }
            } else if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") {
                print("FONT REGISTRATION: Found \(fontName).otf via bundle resource at \(fontURL.path)")
                fontRegistered = registerFontWith(url: fontURL, fontName: fontName)
                if fontRegistered { registeredCount += 1 }
            } else {
                print("FONT REGISTRATION: Trying to find \(fontName) in possible paths...")
                // Try each path with each extension (original approach)
                for path in possibleFontPaths {
                    for ext in ["ttf", "otf"] {
                        let fullPath = path + fontName + "." + ext
                        
                        if FileManager.default.fileExists(atPath: fullPath),
                           let fontURL = URL(string: "file://" + fullPath) {
                            print("FONT REGISTRATION: Found \(fontName).\(ext) at \(fullPath)")
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
        
        // Print available fonts to verify registration
        printAvailableFonts()
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

// Add AppDelegate to handle Google Sign-In URL callbacks
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Google Sign-In with iOS client ID from Info.plist
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("Google Sign-In configured with client ID from Info.plist")
        } else {
            print("⚠️ Missing GoogleClientID in Info.plist")
        }
        return true
    }
    
    func application(_ application: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Let GoogleSignIn handle the URL
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// --- Main App Structure ---

@main
struct PTChampionApp: App {
    // Register AppDelegate to handle Google Sign-In callbacks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Environment objects & Services that need to be @StateObject
    @StateObject private var authService: AuthService // Declared, initialized in init
    @StateObject private var featureFlagService = FeatureFlagService() // Default init works
    @StateObject private var poseDetectorService = PoseDetectorService() // Default init works
    @StateObject private var navigationState = NavigationState() // Default init works
    
    // Bluetooth and HealthKit services
    @StateObject private var bluetoothService = BluetoothService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var fitnessDeviceManagerViewModel: FitnessDeviceManagerViewModel // Declared, initialized in init

    // Network monitoring and offline sync
    @StateObject private var networkMonitorService = NetworkMonitorService()
    @StateObject private var synchronizationService: SynchronizationService // Declared, initialized in init

    // ViewModels that need to be shared or initialized early
    @StateObject private var authViewModel: AuthViewModel // Declared, initialized in init
    @StateObject private var dashboardViewModel: DashboardViewModel // Declared, initialized in init
    @StateObject private var workoutSessionViewModel: WorkoutSessionViewModel // Declared, initialized in init (renamed from workoutViewModel)
    @StateObject private var runWorkoutViewModel: RunWorkoutViewModel // Declared, initialized in init
    @StateObject private var workoutHistoryViewModel: WorkoutHistoryViewModel // Direct reference to class
    @StateObject private var leaderboardViewModel: LeaderboardViewModel // Declared, initialized in init
    @StateObject private var progressViewModel: ProgressViewModel // Declared, initialized in init

    // SwiftData model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutResultSwiftData.self,
            WorkoutDataPoint.self, // Make sure this is included
            RunMetricSample.self   // Add RunMetricSample to schema
        ])
        
        // Define a version-based migration strategy
        let modelVersion = "3" // Increment this when schema changes 
        let migrationKey = "SwiftDataModelVersion"
        
        // Check stored version vs current version
        let currentVersion = UserDefaults.standard.string(forKey: migrationKey)
        
        // If versions don't match or no version exists, we'll reset the store
        if currentVersion != modelVersion {
            print("SwiftData model version changed from \(currentVersion ?? "nil") to \(modelVersion), resetting store")
            
            // Try to find and delete the store files
            if let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupportDir.appendingPathComponent("default.store")
                let storeSHMURL = appSupportDir.appendingPathComponent("default.store-shm")
                let storeWALURL = appSupportDir.appendingPathComponent("default.store-wal")
                
                for url in [storeURL, storeSHMURL, storeWALURL] {
                    try? FileManager.default.removeItem(at: url)
                    print("Deleted store file: \(url.lastPathComponent)")
                }
                
                // Update the stored version
                UserDefaults.standard.set(modelVersion, forKey: migrationKey)
            }
        }
        
        // Create a configuration with normal storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Error creating ModelContainer: \(error)")
            
            // If we still can't create the container, try in-memory as last resort
            do {
                print("Falling back to in-memory store")
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                print("Fatal error: Could not create ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
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
        // Create local temporary instances of services that are also StateObjects
        let tempBluetoothService = BluetoothService()
        let tempHealthKitService = HealthKitService()
        let leaderboardService = LeaderboardService(networkClient: networkClient)
        let workoutService = WorkoutService(networkClient: networkClient)
        // Note: poseDetectorService and featureFlagService are initialized at declaration
        
        // Create persistence service for offline sync
        let workoutPersistenceService = WorkoutPersistenceService()
        
        // Create network monitor and sync services
        let tempNetworkMonitorService = NetworkMonitorService()
        let tempSynchronizationService = SynchronizationService(
            workoutService: workoutService,
            persistenceService: workoutPersistenceService,
            networkMonitor: tempNetworkMonitorService
        )

        // --- Step 2: Create ALL temporary VM instances (using defaults/placeholders for self-dependencies) ---
        let tempAuthService = AuthService(networkClient: networkClient)
        let tempAuthViewModel = AuthViewModel()
        let tempDashboardViewModel = DashboardViewModel() // init takes no args
        let tempWorkoutSessionViewModel = WorkoutSessionViewModel(
            exerciseType: .pushup, // Default exercise type
            cameraService: CameraService(),
            poseDetectorService: PoseDetectorService()
        )
        let tempRunWorkoutViewModel = RunWorkoutViewModel(
            locationService: locationService,
            workoutService: workoutService,
            keychainService: keychainService,
            bluetoothService: tempBluetoothService, // Use local temp instance instead of self.bluetoothService
            healthKitService: tempHealthKitService, // Use local temp instance instead of self.healthKitService
            modelContext: nil // Set later using self.sharedModelContainer
        )
        let tempWorkoutHistoryViewModel = WorkoutHistoryViewModel(workoutService: workoutService as WorkoutServiceProtocol) // Direct reference to class
        let tempLeaderboardViewModel = LeaderboardViewModel(
            service: leaderboardService,
            location: locationService,
            keychain: keychainService
        )
        let tempProgressViewModel = ProgressViewModel(workoutService: workoutService, keychainService: keychainService)
        let tempFitnessDeviceManagerViewModel = FitnessDeviceManagerViewModel(
            bluetoothService: tempBluetoothService, // Use local temp instance
            healthKitService: tempHealthKitService // Use local temp instance
        )

        // --- Step 3: Assign ALL @StateObjects declared without initial value ---
        // Note: featureFlagService & poseDetectorService are initialized at declaration
        _authService = StateObject(wrappedValue: tempAuthService)
        _authViewModel = StateObject(wrappedValue: tempAuthViewModel)
        _dashboardViewModel = StateObject(wrappedValue: tempDashboardViewModel)
        _workoutSessionViewModel = StateObject(wrappedValue: tempWorkoutSessionViewModel) // Renamed from workoutViewModel
        _runWorkoutViewModel = StateObject(wrappedValue: tempRunWorkoutViewModel)
        _workoutHistoryViewModel = StateObject(wrappedValue: tempWorkoutHistoryViewModel)
        _leaderboardViewModel = StateObject(wrappedValue: tempLeaderboardViewModel)
        _progressViewModel = StateObject(wrappedValue: tempProgressViewModel)
        _fitnessDeviceManagerViewModel = StateObject(wrappedValue: tempFitnessDeviceManagerViewModel)
        _synchronizationService = StateObject(wrappedValue: tempSynchronizationService)

        // Activate AssistantKiller
        #if !targetEnvironment(simulator)
            AssistantKiller.activate()
        #endif

        // Configure appearance
        AppAppearance.configureAppearance()
        
        // Register background tasks
        setupBackgroundTasks()

        #if DEBUG
        print("DEBUG mode is ON")
        #else
        print("DEBUG mode is OFF (RELEASE mode)")
        #endif
    }
    
    private func setupGlobalServices() {
        // Now that all properties are initialized, we can setup any further configuration
        // --- Step 4: Perform final configuration now that `self` is fully initialized ---
        dashboardViewModel.setModelContext(sharedModelContainer.mainContext)
        workoutHistoryViewModel.modelContext = sharedModelContainer.mainContext
        runWorkoutViewModel.modelContext = sharedModelContainer.mainContext
        workoutSessionViewModel.modelContext = sharedModelContainer.mainContext // Renamed from workoutViewModel
        // We are using the default PoseDetectorService created within WorkoutSessionViewModel's init
        // If we *needed* to use the app-level self.poseDetectorService, we'd need a setter method in WorkoutSessionViewModel
        // e.g., self.workoutSessionViewModel.setPoseDetector(self.poseDetectorService)
        
        // Schedule initial background sync
        synchronizationService.scheduleBackgroundSync()
        
        print("Global services setup complete.")
    }
    
    /// Register background tasks with the system
    private func setupBackgroundTasks() {
        // Register background tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SynchronizationService.backgroundTaskIdentifier,
            using: nil
        ) { task in
            // Handle background sync task
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            
            // Since we have no direct access to the synchronizationService here
            // (as it's a property of the app structure), we use a notification to trigger the sync
            NotificationCenter.default.post(name: .connectivityRestored, object: nil)
            
            // Set up a timer to ensure we complete the task before expiration
            let timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { _ in
                appRefreshTask.setTaskCompleted(success: true)
            }
            
            // Add an expiration handler to handle the case where the task takes too long
            appRefreshTask.expirationHandler = {
                timer.invalidate() // Invalidate the timer
                appRefreshTask.setTaskCompleted(success: false)
            }
        }
        
        print("Background tasks registered")
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
                        .environmentObject(bluetoothService)
                        .environmentObject(healthKitService)
                        .environmentObject(networkMonitorService)
                        // Pass ViewModels (Grouped)
                        .environmentObject(authViewModel)
                        .environmentObject(dashboardViewModel)
                        .environmentObject(workoutSessionViewModel) // Renamed from workoutViewModel
                        .environmentObject(runWorkoutViewModel)
                        .environmentObject(workoutHistoryViewModel)
                        .environmentObject(leaderboardViewModel)
                        .environmentObject(progressViewModel)
                        .environmentObject(fitnessDeviceManagerViewModel)
                }
            }
            .modelContainer(sharedModelContainer)
            .onAppear {
                // Setup global services after all properties are initialized
                setupGlobalServices()
                
                // Check initial authentication state on app launch
                if navigationState.currentScreen == .loading {
                    // Let the LoadingView handle the navigation instead of doing it here
                    // This allows for a visual loading state before auto-navigating
                    print("App launched, starting with loading screen")
                }
            }
            .task {
                // Fix for missing generic parameter R by using explicit type annotation
                await MainActor.run { () -> Void in
                    print("App started on main actor")
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
    @EnvironmentObject var workoutHistoryViewModel: WorkoutHistoryViewModel // Direct reference to class

    var body: some View {
        TabView(selection: $selectedTab) {
            // Each view already has a NavigationStack in their own file
            // Don't add an additional NavigationView wrapper here
            
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            // Use a dedicated HistoryTabView to wrap WorkoutHistoryView
            HistoryTabView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            LeaderboardView(viewModel: leaderboardVM, viewId: "mainTabLeaderboard")
                .tabItem { Label("Leaders", systemImage: "rosette") }
                .tag(Tab.leaderboards)

            ProfileView() 
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(AppTheme.GeneratedColors.brassGold)
        .onAppear { 
            // Customize TabView appearance 
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(AppTheme.GeneratedColors.deepOps)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
        .onChange(of: selectedTab) { _, newTab in
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
        WorkoutDataPoint.self,
        RunMetricSample.self
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

// Dedicated wrapper view for History tab
struct HistoryTabView: View {
    @EnvironmentObject var workoutHistoryViewModel: WorkoutHistoryViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            // Directly create the view and environmentObject wrapper in a single statement
            AnyView(
                WorkoutHistoryView()
                    .environmentObject(workoutHistoryViewModel)
                    .onAppear {
                        // Ensure the view model has the context
                        workoutHistoryViewModel.modelContext = modelContext
                        
                        // Fetch workouts when the view appears
                        Task {
                            await workoutHistoryViewModel.fetchWorkouts()
                        }
                    }
            )
        }
    }
}

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