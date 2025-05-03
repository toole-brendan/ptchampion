import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentColorScheme: ColorScheme = .light
    
    // For future theme switching capability
    func toggleDarkMode() {
        currentColorScheme = currentColorScheme == .light ? .dark : .light
    }
} 