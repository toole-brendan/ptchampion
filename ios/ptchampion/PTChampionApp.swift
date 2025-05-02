import SwiftUI
import SwiftData
import UIKit
import Foundation

// Import any necessary files directly since PTChampionImports module is causing issues

// FontManager class to handle font registration
class FontManager {
    static let shared = FontManager()
    
    // Font registration status
    private var fontsRegistered = false
    
    // Register all required fonts
    func registerFonts() {
        guard !fontsRegistered else { return }
        
        // Define all the fonts we need to register
        let fontNames = [
            "BebasNeue-Bold",
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
            Bundle.main.resourcePath! + "/" // Resources directory
        ]
        
        var registeredCount = 0
        
        for fontName in fontNames {
            var fontRegistered = false
            
            // Try each path with each extension
            for path in possibleFontPaths {
                for ext in ["ttf", "otf"] {
                    let fullPath = path + fontName + "." + ext
                    
                    if let fontURL = URL(string: "file://" + fullPath),
                       let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
                       let font = CGFont(fontDataProvider) {
                        
                        var error: Unmanaged<CFError>?
                        if CTFontManagerRegisterGraphicsFont(font, &error) {
                            print("Successfully registered font: \(fontName)")
                            fontRegistered = true
                            registeredCount += 1
                            break
                        } else {
                            if let unwrappedError = error?.takeRetainedValue() {
                                print("Failed to register font: \(fontName) with error: \(unwrappedError)")
                            }
                        }
                    }
                }
                
                if fontRegistered {
                    break
                }
            }
            
            if !fontRegistered {
                print("⚠️ Could not register font: \(fontName)")
                // Fallback - try direct registration with the font file name
                if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                    var error: Unmanaged<CFError>?
                    if let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
                       let font = CGFont(fontDataProvider),
                       CTFontManagerRegisterGraphicsFont(font, &error) {
                        print("Successfully registered font through fallback: \(fontName)")
                        registeredCount += 1
                    } else {
                        print("⚠️ Fallback also failed for font: \(fontName)")
                    }
                }
            }
        }
        
        print("Font registration complete. Registered \(registeredCount)/\(fontNames.count) fonts.")
        fontsRegistered = true
    }
    
    // Helper to list all available fonts - useful for debugging
    func printAvailableFonts() {
        for family in UIFont.familyNames.sorted() {
            print("Font Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   Font: \(name)")
            }
        }
    }
}

@main
struct PTChampionApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    // --- Restore initial state to LOADING ---
    @State private var appNavigationState: AppScreen = .loading // Restore loading state
    
    enum AppScreen {
        case loading, login, main
    }
    
    // Initialize app appearance
    init() {
        print("DEBUG: PTChampionApp init() called")
        // Restore init contents
        FontManager.shared.registerFonts()
        
        #if DEBUG
        print("--- DEBUG: Available Fonts ---")
        FontManager.shared.printAvailableFonts()
        print("-----------------------------")
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
        
        // Convert SwiftUI Color to UIColor
        UINavigationBar.appearance().tintColor = UIColor(Color("DeepOps"))
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(Color("DeepOps")),
            .font: UIFont(name: "BebasNeue-Bold", size: 22) ?? UIFont.systemFont(ofSize: 22, weight: .bold)
        ]
    }

    var body: some Scene {
        WindowGroup {
            let _ = Self.logBody()
            RootContentView()
                .environmentObject(authViewModel)
                .modelContainer(for: WorkoutResultSwiftData.self)
        }
    }
    
    // Helper to determine initial screen
    private func determineInitialScreen() {
        print("DEBUG: determineInitialScreen called")
        // --- Call updateNavigationState DIRECTLY --- 
        print("DEBUG: Calling updateNavigationState directly from determineInitialScreen")
        updateNavigationState()
        
        /* // Original delay logic commented out
        // Short delay to allow auth state to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: determineInitialScreen timer fired - calling updateNavigationState")
            updateNavigationState()
        }
        */
    }
    
    // Centralized navigation state update
    private func updateNavigationState() {
        print("DEBUG: updateNavigationState called. Auth=\(authViewModel.isAuthenticated)")
        let targetState = authViewModel.isAuthenticated ? AppScreen.main : AppScreen.login
        print("DEBUG: Target navigation state is: \(targetState)")
        
        // Only update if the state needs to change
        if appNavigationState != targetState {
            print("DEBUG: State needs update from \(appNavigationState) to \(targetState) — applying now on main thread")
            // Directly update the @State property (we are already on the main thread in typical UI callbacks)
            withAnimation(nil) { // No animation by default; change to .default if desired later
                appNavigationState = targetState
            }
            print("DEBUG: State updated to: \(appNavigationState)")
        } else {
            print("DEBUG: State \(appNavigationState) already matches target \(targetState), no update needed.")
        }
    }

    // MARK: - Debug Helpers
    private static func logBody() {
        print("DEBUG: PTChampionApp body recomputed")
    }

    // MARK: - RootContentView (inlined to avoid target-membership issues)
    struct RootContentView: View {
        @State private var navState: AppScreen = .loading
        @EnvironmentObject var authViewModel: AuthViewModel

        var body: some View {
            let _ = { print("DEBUG: RootContentView body recomputed, state=\(navState)") }()
            Group {
                if navState == .loading {
                    ProgressView()
                        .onAppear {
                            print("DEBUG: Loading screen appeared (RootContentView)")
                            determineInitialScreen()
                        }
                } else if navState == .login {
                    LoginView()
                        .onAppear { print("PTChampionApp: Showing LoginView (RootContentView)") }
                } else {
                    MainTabView()
                        .onAppear { print("PTChampionApp: Showing MainTabView (RootContentView)") }
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { oldVal, newVal in
                print("DEBUG: RootContentView onChange detected auth change: \(oldVal) -> \(newVal)")
                updateNavigationState()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PTChampionAuthStateChanged"))) { _ in
                print("DEBUG: RootContentView onReceive detected notification")
                updateNavigationState()
            }
        }

        // MARK: - Helpers
        private func determineInitialScreen() {
            updateNavigationState()
        }

        private func updateNavigationState() {
            print("DEBUG: RootContentView updateNavigationState called. Auth=\(authViewModel.isAuthenticated)")
            let target: AppScreen = authViewModel.isAuthenticated ? .main : .login
            if navState != target {
                print("DEBUG: RootContentView changing navigation from \(navState) to \(target) (direct update)")
                withAnimation(nil) {
                    navState = target
                    print("DEBUG: RootContentView state updated to \(navState) synchronously")
                }
            } else {
                print("DEBUG: RootContentView navigation already at \(target)")
            }
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