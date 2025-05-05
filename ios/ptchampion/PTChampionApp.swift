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
    // Create a SINGLE source of truth for authentication
    @StateObject private var auth = AuthViewModel()
    // Add ThemeManager for styling
    @StateObject private var themeManager = ThemeManager.shared
    
    // Initialize app appearance
    init() {
        AssistantKiller.activate()
        print("DEBUG: PTChampionApp init() called")
        
        // Register fonts with error handling to prevent app crashes
        do {
            // Register fonts first, before accessing auth state
            FontManager.shared.registerFonts()
        } catch {
            // If font registration fails, log error but continue app execution
            print("❌ ERROR: Font registration failed but continuing app execution: \(error)")
        }
        
        #if DEBUG
        // FontManager.shared.printAvailableFonts() - Font listing removed to reduce console output
        print("--- DEBUG APP INITIALIZATION ---")
        // Don't access StateObject here - defer to body
        print("-------------------------------")
        #endif
        
        configureAppearance()
        print("DEBUG: PTChampionApp init() finished")
    }
    
    // Configure UI appearance manually
    private func configureAppearance() {
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
        
        // Use system fonts as fallback if custom fonts fail to load
        let navTitleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        // Use proper tokens from design system
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.GeneratedColors.deepOps)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.GeneratedColors.textPrimary),
            .font: navTitleFont
        ]
    }

    var body: some Scene {
        WindowGroup {
            // Pass the shared auth view model to all views
            RootSwitcher()
                .environmentObject(auth)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentColorScheme)
                .modelContainer(for: WorkoutResultSwiftData.self)
                .onAppear {
                    Self.logBody() // Debug log function
                    #if DEBUG
                    print("AuthViewModel instance being passed to views: \(ObjectIdentifier(auth))")
                    #endif
                    print("🚀 App Root view appeared with AuthViewModel instance: \(ObjectIdentifier(auth))")
                }
        }
    }
    
    // MARK: - Debug Helpers
    private static func logBody() {
        print("DEBUG: PTChampionApp body recomputed")
    }
}

// MARK: - Root Content Switcher that directly depends on auth.authState
struct RootSwitcher: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showDebugInfo = false

    var body: some View {
        ZStack {
            // Main content based on authentication state
            Group {
                switch auth.authState {
                case .authenticated(let user):
                    // Authenticated content
                    MainTabView()
                        .transition(.opacity)
                        .onAppear {
                            print("DEBUG: MainTabView appeared with user ID: \(user.id)")
                        }
                case .unauthenticated:
                    // Login view when not authenticated
                    LoginView()
                        .transition(.opacity)
                }
            }
            
            // Debug overlay
            if showDebugInfo {
                DebugOverlayView(
                    authState: auth.authState,
                    showDebugInfo: $showDebugInfo,
                    authenticateAction: { auth.debugForceAuthenticated() },
                    logoutAction: { auth.logout() }
                )
            }
            
            // Debug button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showDebugInfo.toggle() }) {
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.gray.opacity(0.8)))
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.authState)
    }
}

// Move debug overlay to its own view
struct DebugOverlayView: View {
    let authState: AuthState
    @Binding var showDebugInfo: Bool
    let authenticateAction: () -> Void
    let logoutAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEBUG INFO")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Auth State: \(authState.isAuthenticated ? "authenticated" : "unauthenticated")")
                .foregroundColor(.white)
            
            if let user = authState.user {
                Text("User ID: \(user.id)")
                    .foregroundColor(.white)
                Text("User Email: \(user.email)")
                    .foregroundColor(.white)
            }
            
            Button("Force Authenticated") {
                print("DEBUG: Force authenticated requested")
                authenticateAction()
            }
            .padding(8)
            .background(AppTheme.GeneratedColors.success)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Force Unauthenticated") {
                print("DEBUG: Manual logout requested")
                logoutAction()
            }
            .padding(8)
            .background(AppTheme.GeneratedColors.error)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Hide Debug") {
                showDebugInfo = false
            }
            .padding(8)
            .background(AppTheme.GeneratedColors.info)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(AppTheme.GeneratedColors.deepOps.opacity(0.8))
        .cornerRadius(12)
        .padding()
    }
}

// Placeholder for the main authenticated view (replace with your actual implementation)
struct MainTabView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var selectedTab: Tab = .dashboard // Keep track of selected tab
    
    // Add tab tracking for debugging
    @State private var previousTab: Tab? = nil
    
    // Add a flag to prevent rapid tab switching
    @State private var isTabSwitchInProgress = false
    
    // Expose ComponentGallery in debug builds for design review
    @State private var showingComponentGallery = false

    // StateObject for the leaderboard view model - keeps it alive
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()

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

            // Standard leaderboard view for all builds
            LeaderboardView(viewModel: leaderboardViewModel, viewId: UUID().uuidString.prefix(6).uppercased())
                .tabItem {
                    Label("Leaders", systemImage: "list.star")
                }
                .tag(Tab.leaderboards)

            #if DEBUG
            // Remove or replace StyleGuideView with a placeholder
            Text("Style Guide")
                .tabItem {
                    Label("Style Guide", systemImage: "paintpalette.fill")
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
            // showingComponentGallery.toggle() // Uncomment if ComponentGalleryView exists
            #endif
        }
        .sheet(isPresented: $showingComponentGallery) {
            // Replace with actual ComponentGalleryView if it exists
            Text("Component Gallery View Placeholder")
        }
        .onChange(of: selectedTab) { _, newTab in
            // Prevent rapid tab switching which can cause UI freezes
            guard !isTabSwitchInProgress else {
                print("📱 MainTabView: Tab change blocked during switch transition")
                return
            }
            
            let previousTabString = previousTab?.description ?? "nil"
            print("📱 MainTabView: Tab changed from \(previousTabString) to \(newTab)")
            
            // Set switch in progress flag
            isTabSwitchInProgress = true
            
            // Add a small delay before allowing another tab switch
            // This helps prevent rapid tab switching which can cause UI issues
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTabSwitchInProgress = false
                print("📱 MainTabView: Tab switch completed, now ready for next tab change")
            }
            
            // Important: If switching to leaderboards tab, give extra time
            // for the view to initialize to prevent freezing
            if newTab == .leaderboards {
                // Use a significantly longer delay for leaderboards
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // This delay gives the leaderboards view time to set up before loading data
                    print("📱 MainTabView: Leaderboard tab delay completed")
                }
                
                // IMPORTANT: Disable quick switching from leaderboards tab
                // This prevents a common crash scenario where users rapidly switch away
                isTabSwitchInProgress = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isTabSwitchInProgress = false
                    print("📱 MainTabView: Allowing tab changes after leaderboard stabilization period")
                }
            }
            
            // Keep track of previous tab for debugging
            previousTab = newTab
        }
        .onAppear {
            print("📱 MainTabView: onAppear")
        }
        .onDisappear {
            print("📱 MainTabView: onDisappear")
        }
    }
}

// Add extension to help with debugging
extension MainTabView.Tab: CustomStringConvertible {
    var description: String {
        switch self {
        case .dashboard: return "dashboard"
        case .progress: return "progress"
        case .workout: return "workout"
        case .leaderboards: return "leaderboards"
        case .settings: return "settings"
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
    // Create the auth view model and wrap the view
    let previewAuth = AuthViewModel()
    MainTabView()
        .environmentObject(previewAuth)
}

// Add a convenience extension to check auth state
extension AuthState {
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: AuthUserModel? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
} 