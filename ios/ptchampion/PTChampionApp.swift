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
    // Instantiate AuthViewModel as a StateObject to keep it alive
    @StateObject private var authViewModel = AuthViewModel()
    
    // Initialize app appearance
    init() {
        // Use the new FontManager to register fonts
        FontManager.shared.registerFonts()
        
        #if DEBUG
        // Print available fonts for debugging
        print("--- DEBUG: Available Fonts ---")
        FontManager.shared.printAvailableFonts()
        print("-----------------------------")
        #endif
        
        configureAppearance()
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
            // Use a simpler direct approach without NavigationStack
            ZStack {
                // Debug view to monitor state
                VStack {
                    Text("")
                        .onAppear {
                            print("PTChampionApp body evaluating: isAuthenticated=\(authViewModel.isAuthenticated)")
                        }
                        .hidden()
                }
                
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .transition(.opacity)
                        .onAppear {
                            print("PTChampionApp: User is authenticated, showing MainTabView")
                        }
                } else {
                    LoginView()
                        .transition(.opacity)
                        .onAppear {
                            print("PTChampionApp: User is NOT authenticated, showing LoginView")
                        }
                }
            }
            .animation(.default, value: authViewModel.isAuthenticated)
            .environmentObject(authViewModel)
            .modelContainer(for: WorkoutResultSwiftData.self)
            // Add explicit onChange handler at the root level
            .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
                print("PTChampionApp: Root level detected auth change: \(oldValue) -> \(newValue)")
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