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

// Card style options for flexibility
public enum CardStyle {
    case standard    // Default card style
    case elevated    // More prominent shadow
    case flat        // No shadow, just border
    case highlight   // Gold accent border
    case military    // Military style with corner cuts
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
    func standardCardStyle(style: CardStyle = .standard) -> some View {
        self
            .padding(AppTheme.GeneratedSpacing.contentPadding)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .modifier(CardStyleModifier(style: style))
    }
    
    /// Applies military-style card with stencil-like corner cutouts
    func militaryCardStyle() -> some View {
        self
            .padding(AppTheme.GeneratedSpacing.contentPadding)
            .background(
                MilitaryCardBackground()
            )
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
    
    /// Applies a standard badge style
    func badgeStyle(color: Color = AppTheme.GeneratedColors.brassGold) -> some View {
        self
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(AppTheme.GeneratedRadius.badge)
    }
    
    /// Provides a standard hit target size for buttons and interactive elements
    func standardHitTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
    
    /// Applies a standard adaptive padding based on device size
    func adaptivePadding() -> some View {
        let padding: CGFloat
        
        #if os(iOS)
        // Different padding based on device size
        switch UIScreen.main.bounds.width {
        case ..<375: // iPhone SE, 8, etc.
            padding = AppTheme.GeneratedSpacing.small
        case 375..<428: // iPhone X, 11, 12, etc.
            padding = AppTheme.GeneratedSpacing.medium
        default: // Larger iPhones, iPads
            padding = AppTheme.GeneratedSpacing.large
        }
        #else
        padding = AppTheme.GeneratedSpacing.medium
        #endif
        
        return self.padding(padding)
    }
}

// Military style card background with corner cutouts
public struct MilitaryCardBackground: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let cornerCutSize: CGFloat = 15
            
            ZStack {
                // Main background
                AppTheme.GeneratedColors.cardBackground
                
                // Corner cutouts - military/stencil style
                Path { path in
                    // Top-left corner
                    path.move(to: CGPoint(x: 0, y: cornerCutSize))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerCutSize, y: 0))
                    path.closeSubpath()
                    
                    // Top-right corner
                    path.move(to: CGPoint(x: width - cornerCutSize, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: cornerCutSize))
                    path.closeSubpath()
                    
                    // Bottom-right corner
                    path.move(to: CGPoint(x: width, y: height - cornerCutSize))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width - cornerCutSize, y: height))
                    path.closeSubpath()
                    
                    // Bottom-left corner
                    path.move(to: CGPoint(x: cornerCutSize, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height - cornerCutSize))
                    path.closeSubpath()
                }
                .fill(AppTheme.GeneratedColors.background)
                
                // Border outline
                Path { path in
                    // Top edge with gap
                    path.move(to: CGPoint(x: cornerCutSize, y: 0))
                    path.addLine(to: CGPoint(x: width - cornerCutSize, y: 0))
                    
                    // Right edge with gap
                    path.move(to: CGPoint(x: width, y: cornerCutSize))
                    path.addLine(to: CGPoint(x: width, y: height - cornerCutSize))
                    
                    // Bottom edge with gap
                    path.move(to: CGPoint(x: width - cornerCutSize, y: height))
                    path.addLine(to: CGPoint(x: cornerCutSize, y: height))
                    
                    // Left edge with gap
                    path.move(to: CGPoint(x: 0, y: height - cornerCutSize))
                    path.addLine(to: CGPoint(x: 0, y: cornerCutSize))
                    
                    // Diagonal corner connectors
                    path.move(to: CGPoint(x: 0, y: cornerCutSize))
                    path.addLine(to: CGPoint(x: cornerCutSize, y: 0))
                    
                    path.move(to: CGPoint(x: width - cornerCutSize, y: 0))
                    path.addLine(to: CGPoint(x: width, y: cornerCutSize))
                    
                    path.move(to: CGPoint(x: width, y: height - cornerCutSize))
                    path.addLine(to: CGPoint(x: width - cornerCutSize, y: height))
                    
                    path.move(to: CGPoint(x: cornerCutSize, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height - cornerCutSize))
                }
                .stroke(AppTheme.GeneratedColors.tacticalGray.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

// Custom ViewModifier to handle different card styles
struct CardStyleModifier: ViewModifier {
    let style: CardStyle
    
    func body(content: Content) -> some View {
        Group {
            switch style {
            case .standard:
                content
                    .withShadow(AppTheme.GeneratedShadows.small)
            case .elevated:
                content
                    .withShadow(AppTheme.GeneratedShadows.medium)
            case .flat:
                content
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
                            .stroke(AppTheme.GeneratedColors.tacticalGray.opacity(0.3), lineWidth: 1)
                    )
            case .highlight:
                content
                    .withShadow(AppTheme.GeneratedShadows.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)
                            .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1.5)
                    )
            case .military:
                content
                    .withShadow(AppTheme.GeneratedShadows.small)
            }
        }
    }
} 