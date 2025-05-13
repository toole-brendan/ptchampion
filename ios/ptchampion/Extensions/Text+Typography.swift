import SwiftUI
import PTDesignSystem

extension Text {
    func heading3() -> Text {
        self.font(.system(size: 20, weight: .bold))
    }
    
    func caption() -> Text {
        self.font(.caption)
    }
    
    func small() -> Text {
        self.font(.footnote)
    }
    
    func body(weight: Font.Weight = .regular) -> Text {
        self.font(.system(size: 16, weight: weight))
    }
}

extension View {
    func frame(maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View {
        self.frame(maxWidth: maxWidth ?? .infinity, maxHeight: maxHeight ?? .infinity, alignment: alignment)
    }
    
    func accessibilityAddTraits(_ traits: AccessibilityTraits) -> some View {
        self.accessibilityAddTraits(traits)
    }
} 