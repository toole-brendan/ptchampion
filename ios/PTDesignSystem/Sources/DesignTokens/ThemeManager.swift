import SwiftUI
import Combine

// Theme options enum
public enum AppThemeOption: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { self.rawValue }
}

// ThemeManager for handling dark/light mode
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var storedThemeRawValue: String = AppThemeOption.light.rawValue
    
    // Initialize with a default; will be synced with AppStorage in init.
    @Published public var currentThemeOption: AppThemeOption = .light // Default to light
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Force light theme
        self.currentThemeOption = .light
        self.storedThemeRawValue = AppThemeOption.light.rawValue
        
        // Remove subscription to currentThemeOption as it's now fixed
        // $currentThemeOption
        //     .dropFirst()
        //     .sink { [weak self] newThemeOption in
        //         self?.storedThemeRawValue = newThemeOption.rawValue
        //     }
        //     .store(in: &cancellables)
    }

    // Computed property to get the SwiftUI ColorScheme for .preferredColorScheme
    public var effectiveColorScheme: ColorScheme? {
        switch currentThemeOption {
        case .system:
            return nil // nil tells SwiftUI to use the system setting
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // Old toggle function, can be removed or kept for specific toggle UI if needed
    // public func toggleDarkMode() {
    //     currentThemeOption = currentThemeOption == .light ? .dark : .light
    // }
}

// Extension for monospaced styling
public extension View {
    // Apply military-style monospaced font to text
    func militaryMonospacedStyle(size: CGFloat? = nil) -> some View {
        let fontSize = size ?? AppTheme.GeneratedTypography.body
        let view = self.font(.system(size: fontSize, weight: .medium, design: .monospaced))
        
        // Only apply tracking on iOS 16+ where it's available
        if #available(iOS 16.0, *) {
            return view.tracking(0.5)
        } else {
            // For earlier iOS versions, just return the monospaced font without tracking
            return view
        }
    }
}

// Extension for Text to easily apply monospaced styling
public extension Text {
    func militaryMonospaced(size: CGFloat? = nil) -> Text {
        let fontSize = size ?? AppTheme.GeneratedTypography.body
        let text = self.font(.system(size: fontSize, weight: .medium, design: .monospaced))
        
        // Only apply tracking on iOS 16+ where it's available
        if #available(iOS 16.0, *) {
            return text.tracking(0.5)
        } else {
            // For earlier iOS versions, just return the monospaced font without tracking
            return text
        }
    }
}

// Extension for Font to easily create monospaced fonts
public extension Font {
    static func militaryMonospaced(size: CGFloat = AppTheme.GeneratedTypography.body) -> Font {
        return .system(size: size, weight: .medium, design: .monospaced)
    }
}

// Extension for web design system support
public extension ThemeManager {
    // Helper to detect if the web theme should be used
    static var useWebTheme: Bool {
        // If FeatureFlagService exists, check the flag
        #if canImport(ptchampion)
        if let featureFlagType = NSClassFromString("ptchampion.FeatureFlagService") as? NSObject.Type,
           let sharedInstance = featureFlagType.value(forKey: "shared") as? NSObject,
           let isEnabled = sharedInstance.perform(NSSelectorFromString("isEnabled:defaultValue:"), 
                                              with: "design_system_v2", 
                                              with: false)?.takeUnretainedValue() as? Bool {
            return isEnabled
        }
        #endif
        
        // For direct development in the PTDesignSystem package, allow a debug setting
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "useWebTheme")
        #else
        return false
        #endif
    }
    
    // For components to programmatically choose between design systems
    static func shadowStyle(legacy: AppTheme.GeneratedShadows.Type, web: AppTheme.Shadow) -> Shadow {
        if useWebTheme {
            return web
        } else {
            // Convert the legacy shadow type to actual Shadow
            switch legacy {
            case AppTheme.GeneratedShadows.small.self:
                return AppTheme.GeneratedShadows.small
            case AppTheme.GeneratedShadows.medium.self:
                return AppTheme.GeneratedShadows.medium
            case AppTheme.GeneratedShadows.large.self:
                return AppTheme.GeneratedShadows.large
            default:
                return AppTheme.GeneratedShadows.small
            }
        }
    }
    
    // For components to programmatically choose between design systems
    static func colorStyle(legacy: Color, web: Color) -> Color {
        return useWebTheme ? web : legacy
    }
    
    // For components to programmatically choose between design systems
    static func fontStyle(legacy: Font, web: Font) -> Font {
        return useWebTheme ? web : legacy
    }
    
    // For components to programmatically choose between design systems
    static func radiusValue(legacy: CGFloat, web: CGFloat) -> CGFloat {
        return useWebTheme ? web : legacy
    }
} 