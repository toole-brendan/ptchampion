import XCTest
@testable import DesignTokens

final class TokenSmokeTests: XCTestCase {
    func testTokensCompile() {
        // Colors
        _ = Color.brand500
        _ = Color.success500
        _ = Color.primary
        _ = Color.surface
        
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