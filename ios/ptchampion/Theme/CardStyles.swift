import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.contentPadding
    var shadowDepth: CardShadowDepth = .small
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .withShadow(shadowDepth.shadow)
    }
}

struct PanelStyle: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.contentPadding
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.Radius.panel)
            .withShadow(AppTheme.Shadows.medium)
    }
}

enum CardShadowDepth {
    case small
    case medium
    case large
    
    var shadow: Shadow {
        switch self {
        case .small: return AppTheme.Shadows.card
        case .medium: return AppTheme.Shadows.cardMd
        case .large: return AppTheme.Shadows.cardLg
        }
    }
}

extension View {
    func cardStyle(
        padding: CGFloat = AppTheme.Spacing.contentPadding,
        shadowDepth: CardShadowDepth = .small
    ) -> some View {
        self.modifier(CardStyle(padding: padding, shadowDepth: shadowDepth))
    }
    
    func panelStyle(padding: CGFloat = AppTheme.Spacing.contentPadding) -> some View {
        self.modifier(PanelStyle(padding: padding))
    }
    
    func headerBackground() -> some View {
        self.background(AppTheme.Colors.deepOps)
            .foregroundColor(AppTheme.Colors.cream)
            .cornerRadius(AppTheme.Radius.card, corners: [.topLeft, .topRight])
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