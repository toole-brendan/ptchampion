import SwiftUI
import Combine
// ThemeManager for handling dark/light mode
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var currentColorScheme: ColorScheme = .light
    
    public func toggleDarkMode() {
        currentColorScheme = currentColorScheme == .light ? .dark : .light
    }
} 