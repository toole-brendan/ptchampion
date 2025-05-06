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
    
    @AppStorage("selectedTheme") private var storedThemeRawValue: String = AppThemeOption.system.rawValue
    
    // Initialize with a default; will be synced with AppStorage in init.
    @Published public var currentThemeOption: AppThemeOption = .system 
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // All stored properties now have initial values (storedThemeRawValue from @AppStorage, currentThemeOption from its declaration).
        // Now, synchronize currentThemeOption with the value actually in AppStorage.
        let initialValueFromStorage = AppThemeOption(rawValue: storedThemeRawValue) ?? .system
        if self.currentThemeOption != initialValueFromStorage { // Sync if different
            self.currentThemeOption = initialValueFromStorage
        }
        
        // If the stored value was invalid and currentThemeOption (now synced) defaulted,
        // ensure AppStorage is updated to reflect this valid default.
        if self.currentThemeOption.rawValue != storedThemeRawValue {
            self.storedThemeRawValue = self.currentThemeOption.rawValue
        }
        
        // Subscribe to subsequent changes in currentThemeOption to update AppStorage.
        $currentThemeOption
            .dropFirst() // Important: Only react to changes *after* this initial setup.
            .sink { [weak self] newThemeOption in
                self?.storedThemeRawValue = newThemeOption.rawValue
            }
            .store(in: &cancellables)
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