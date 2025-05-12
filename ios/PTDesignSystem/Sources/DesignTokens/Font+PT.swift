import SwiftUI
import UIKit

// Extension to provide easier access to the Futura PT font family
public extension Font {
    // Helper to check if a font exists
    private static func fontExists(_ fontName: String) -> Bool {
        return UIFont(name: fontName, size: 16) != nil
    }
    
    static func futuraBook(size: CGFloat) -> Font { 
        if fontExists("FuturaPT-Book") {
            return .custom("FuturaPT-Book", size: size, relativeTo: .body)
        } else {
            // Fall back to system font
            return .system(size: size, weight: .regular, design: .default)
        }
    }
    
    static func futuraMedium(size: CGFloat) -> Font { 
        if fontExists("FuturaPT-Medium") {
            return .custom("FuturaPT-Medium", size: size, relativeTo: .body)
        } else {
            // Fall back to system font
            return .system(size: size, weight: .medium, design: .default)
        }
    }
    
    static func futuraDemi(size: CGFloat) -> Font { 
        if fontExists("FuturaPT-Demi") {
            return .custom("FuturaPT-Demi", size: size, relativeTo: .body)
        } else {
            // Fall back to system font
            return .system(size: size, weight: .semibold, design: .default)
        }
    }
    
    static func futuraBold(size: CGFloat) -> Font { 
        if fontExists("FuturaPT-Bold") {
            return .custom("FuturaPT-Bold", size: size, relativeTo: .body)
        } else {
            // Fall back to system font
            return .system(size: size, weight: .bold, design: .default)
        }
    }
    
    // Semantic font methods that match web typography styles
    static func webH1() -> Font { futuraBold(size: 36) }   // 2.25rem
    static func webH2() -> Font { futuraBold(size: 30) }   // 1.875rem
    static func webH3() -> Font { futuraDemi(size: 24) }   // 1.5rem
    static func webH4() -> Font { futuraDemi(size: 20) }   // 1.25rem
    static func webH5() -> Font { futuraDemi(size: 18) }   // 1.125rem
    static func webH6() -> Font { futuraDemi(size: 16) }   // 1rem
    
    static func webBodyLarge() -> Font { futuraBook(size: 18) }  // 1.125rem
    static func webBody() -> Font { futuraBook(size: 16) }       // 1rem
    static func webBodySmall() -> Font { futuraBook(size: 14) }  // 0.875rem
    static func webCaption() -> Font { futuraBook(size: 12) }    // 0.75rem
    static func webLabel() -> Font { futuraMedium(size: 14) }    // 0.875rem
    static func webButton() -> Font { futuraDemi(size: 14) }     // 0.875rem
    
    // Return configured SFMono or fallback to system monospace
    static func webMonospace() -> Font {
        // Check if system has SFMono font
        if fontExists("SFMono-Regular") {
            return .custom("SFMono-Regular", size: 14, relativeTo: .body)
        } else {
            return .system(.body, design: .monospaced)
        }
    }
} 