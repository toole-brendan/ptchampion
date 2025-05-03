import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
    var shadowDepth: CardShadowDepth = .small
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .withShadow(shadowDepth.shadow)
    }
}

struct PanelStyle: ViewModifier {
    var padding: CGFloat = AppTheme.GeneratedSpacing.contentPadding
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.GeneratedColors.background)
            .cornerRadius(AppTheme.GeneratedRadius.panel)
            .withShadow(AppTheme.GeneratedShadows.medium)
    }
}

enum CardShadowDepth {
    case small
    case medium
    case large
    
    var shadow: Shadow {
        switch self {
        case .small: return AppTheme.GeneratedShadows.small
        case .medium: return AppTheme.GeneratedShadows.medium
        case .large: return AppTheme.GeneratedShadows.large
        }
    }
}

extension View {
    func cardStyle(
        padding: CGFloat = AppTheme.GeneratedSpacing.contentPadding,
        shadowDepth: CardShadowDepth = .small
    ) -> some View {
        self.modifier(CardStyle(padding: padding, shadowDepth: shadowDepth))
    }
    
    func panelStyle(padding: CGFloat = AppTheme.GeneratedSpacing.contentPadding) -> some View {
        self.modifier(PanelStyle(padding: padding))
    }
    
    func headerBackground() -> some View {
        self.background(AppTheme.GeneratedColors.deepOps)
            .foregroundColor(AppTheme.GeneratedColors.cream)
            .cornerRadius(AppTheme.GeneratedRadius.card, corners: [.topLeft, .topRight])
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 