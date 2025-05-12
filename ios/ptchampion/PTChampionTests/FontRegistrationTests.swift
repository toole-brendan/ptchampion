import XCTest
import UIKit
@testable import PTChampion

class FontRegistrationTests: XCTestCase {
    
    func testHelveticaNeueFontsRegistered() {
        // System fonts should be available
        let fontNames = [
            "HelveticaNeue",
            "HelveticaNeue-Medium",
            "HelveticaNeue-Bold",
            "HelveticaNeue-Semibold",
            "Menlo-Regular",
            "Menlo-Bold"
        ]
        
        for fontName in fontNames {
            let font = UIFont(name: fontName, size: 16)
            XCTAssertNotNil(font, "Font '\(fontName)' is not registered/available")
        }
    }
    
    func testDynamicTypeFontScaling() {
        // Test that our font scaling works with dynamic type
        let contentSizeCategories: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        // Test that body font size changes across content size categories
        for category in contentSizeCategories {
            // Create a trait collection with the content size category
            let traitCollection = UITraitCollection(preferredContentSizeCategory: category)
            
            // Set up the dynamic type environment
            UITraitCollection.current = traitCollection
            
            // Create a custom SwiftUI font with relative size (simplified test)
            let relativeFontName = "HelveticaNeue"
            let fontSize: CGFloat = 16
            let preferredFont = UIFontMetrics.default.scaledFont(for: UIFont(name: relativeFontName, size: fontSize)!)
            
            // For larger accessibility sizes, the scaled font should be larger than the base size
            if category.isAccessibilityCategory {
                XCTAssertGreaterThan(preferredFont.pointSize, fontSize, "Font should scale up for accessibility size \(category)")
            }
        }
    }
} 