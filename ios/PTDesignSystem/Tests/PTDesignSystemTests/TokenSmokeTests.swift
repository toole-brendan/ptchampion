import XCTest
@testable import DesignTokens

final class TokenSmokeTests: XCTestCase {
    func testTokensCompile() {
        // Colors
        _ = ThemeColor.brand500
        _ = ThemeColor.success500
        _ = ThemeColor.primary
        _ = ThemeColor.surface
        
        // Typography
        _ = Typography.h1
        _ = Typography.body
        _ = Typography.base
        
        // Radius
        _ = CornerRadius.lg
        _ = CornerRadius.card
        
        // Shadow
        _ = Shadow.md
        _ = Shadow.card
        
        // Spacing
        _ = Spacing.space4
        _ = Spacing.itemSpacing
    }
} 