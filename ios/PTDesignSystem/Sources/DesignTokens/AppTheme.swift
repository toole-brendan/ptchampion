import SwiftUI

// Base AppTheme struct that will be extended by generated code
public struct AppTheme {
    // Empty base struct - extensions will be added through generated code
}

// Shadow type definition for use by GeneratedShadows
public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// Shadow sizes for convenience
public enum ShadowSize {
    case small
    case medium
    case large
}

// Extension to apply shadow
public extension View {
    func withShadow(_ shadow: Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Applies standard card styling using the design system tokens
    func standardCardStyle() -> some View {
        self
            .padding(AppTheme.GeneratedSpacing.contentPadding)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
    }
    
    /// Applies a shadow based on the design system tokens
    func standardShadow(size: ShadowSize = .medium) -> some View {
        let shadow: Shadow
        
        switch size {
        case .small:
            shadow = AppTheme.GeneratedShadows.small
        case .medium:
            shadow = AppTheme.GeneratedShadows.medium
        case .large:
            shadow = AppTheme.GeneratedShadows.large
        }
        
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
} 