import SwiftUI

/// Card styling constants - aligned with web card styles
struct CardStyle {
    // Card geometry
    static let cornerRadius: CGFloat = ContainerStyle.Radius.card
    static let panelCornerRadius: CGFloat = ContainerStyle.Radius.panel
    
    // Card content spacing
    static let padding: CGFloat = ContainerStyle.Spacing.contentPadding
    static let spacing: CGFloat = ContainerStyle.Spacing.md
    
    // Shadow values
    static let shadow = AppShadow.card
    static let hoverShadow = AppShadow.cardHover
    
    // Border
    static let borderWidth: CGFloat = 1
    static let borderColor = Color.border
    static let interactiveBorderColor = Color.brassGold.opacity(0.4)
    
    // Interactive properties
    static let pressedScale: CGFloat = 0.98
    static let hoverTranslationY: CGFloat = -4
}

/// Card variants matching web variants
enum CardVariant {
    case `default`
    case interactive
    case elevated
    case panel
    case flush
}

/// A ViewModifier for applying card styling
struct CardModifier: ViewModifier {
    let variant: CardVariant
    let isPressed: Bool
    
    // We'll use a simpler approach for iOS without hover state
    // @State private var isHovered = false
    
    init(variant: CardVariant = .default, isPressed: Bool = false) {
        self.variant = variant
        self.isPressed = isPressed
    }
    
    func body(content: Content) -> some View {
        content
            .padding(CardStyle.padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        variant == .interactive ? 
                        CardStyle.interactiveBorderColor : 
                        CardStyle.borderColor,
                        lineWidth: shouldShowBorder ? CardStyle.borderWidth : 0
                    )
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .scaleEffect(isPressed && variant == .interactive ? CardStyle.pressedScale : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Computed Properties
    
    private var cornerRadius: CGFloat {
        switch variant {
        case .panel:
            return CardStyle.panelCornerRadius
        case .flush:
            return 0
        default:
            return CardStyle.cornerRadius
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .panel:
            return Color.creamDark
        default:
            return Color.card
        }
    }
    
    private var shouldShowBorder: Bool {
        switch variant {
        case .flush:
            return false
        default:
            return true
        }
    }
    
    private var shadowRadius: CGFloat {
        switch variant {
        case .flush:
            return 0
        case .elevated:
            return AppShadow.medium.radius
        case .interactive:
            return isPressed ? CardStyle.shadow.radius : CardStyle.hoverShadow.radius
        default:
            return CardStyle.shadow.radius
        }
    }
    
    private var shadowColor: Color {
        switch variant {
        case .flush:
            return Color.clear
        case .elevated:
            return AppShadow.medium.color
        case .interactive:
            return isPressed ? CardStyle.shadow.color : CardStyle.hoverShadow.color
        default:
            return CardStyle.shadow.color
        }
    }
    
    private var shadowY: CGFloat {
        switch variant {
        case .flush:
            return 0
        case .elevated:
            return AppShadow.medium.y
        case .interactive:
            return isPressed ? CardStyle.shadow.y : CardStyle.hoverShadow.y
        default:
            return CardStyle.shadow.y
        }
    }
}

/// A ViewModifier for card dividers
struct CardDividerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 1)
            .frame(width: 64)
            .background(Color.brassGold)
            .padding(.vertical, 8)
    }
}

// Extensions for applying modifiers
extension View {
    /// Apply card styling with the specified variant
    func card(variant: CardVariant = .default, isPressed: Bool = false) -> some View {
        modifier(CardModifier(variant: variant, isPressed: isPressed))
    }
    
    /// Apply styling for an interactive card
    func interactiveCard(isPressed: Bool = false) -> some View {
        modifier(CardModifier(variant: .interactive, isPressed: isPressed))
    }
    
    /// Apply styling for a section card with panel style
    func panelCard() -> some View {
        modifier(CardModifier(variant: .panel))
    }
    
    /// Apply styling for an elevated card
    func elevatedCard() -> some View {
        modifier(CardModifier(variant: .elevated))
    }
    
    /// Apply styling for a card divider
    func cardDivider() -> some View {
        modifier(CardDividerModifier())
    }
}

// MARK: - Card Components

/// A title component for card headers
struct CardTitle: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = .brassGold) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .heading4(color: color)
            .textCase(.uppercase)
    }
}

/// A description component for card headers
struct CardDescription: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .small(color: .mutedForeground)
    }
} 