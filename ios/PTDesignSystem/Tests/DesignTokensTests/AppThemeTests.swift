import XCTest
import SwiftUI
@testable import DesignTokens

final class AppThemeTests: XCTestCase {
    func testColorsExist() {
        // Basic verification that colors exist and don't crash when accessed
        _ = Color.primary
        _ = Color.secondary
        _ = Color.error
        _ = Color.background
        _ = Color.cardBackground
        
        // If we reach here without crashing, the test passes
        XCTAssert(true)
    }
    
    func testThemeManagerDefaults() {
        // Verify ThemeManager defaults to light mode
        let themeManager = ThemeManager.shared
        XCTAssertEqual(themeManager.currentColorScheme, .light)
        
        // Test toggle functionality
        themeManager.toggleDarkMode()
        XCTAssertEqual(themeManager.currentColorScheme, .dark)
        
        // Reset back to light mode for other tests
        themeManager.toggleDarkMode()
        XCTAssertEqual(themeManager.currentColorScheme, .light)
    }
    
    func testShadowInitializer() {
        // Test Shadow initializer
        let shadow = Shadow(color: .black, radius: 5, x: 2, y: 2)
        XCTAssertEqual(shadow.radius, 5)
        XCTAssertEqual(shadow.x, 2)
        XCTAssertEqual(shadow.y, 2)
    }
} 