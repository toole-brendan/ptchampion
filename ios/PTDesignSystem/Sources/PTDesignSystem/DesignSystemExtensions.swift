import SwiftUI
import DesignTokens

// Define card variant matching web variants
public enum CardVariant {
    case `default`
    case interactive
    case elevated
    case panel
    case flush
}

// A ViewModifier for applying card styling
public struct CardModifier: ViewModifier {
    let variant: CardVariant
    
    public init(variant: CardVariant = .default) {
        self.variant = variant
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(Spacing.contentPadding)
            .background(ThemeColor.cardBackground)
            .cornerRadius(CornerRadius.card)
    }
}

public extension View {
    /// Card styling with web style
    public func webCardStyle(
        shadowStyle: DSShadow = Shadow.card,
        cornerRadius: CGFloat = CornerRadius.lg
    ) -> some View {
        self
            .background(ThemeColor.surface)
            .cornerRadius(cornerRadius)
            .withDSShadow(shadowStyle)
    }

    /// Add standard spacing around content using web spacing
    public func webSpacing(
        horizontal: CGFloat = Spacing.space4,
        vertical: CGFloat = Spacing.space4
    ) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }
    
    /// Container view modifier that limits max width and applies horizontal padding responsively
    public func container(maxWidth: CGFloat = 600) -> some View {
        self.frame(maxWidth: maxWidth)
            .adaptivePadding()
    }
    
    /// Card view modifier for card styling
    public func card(variant: CardVariant = .default) -> some View {
        self.modifier(CardModifier(variant: variant))
    }
    
    /// Adaptive padding that applies appropriate horizontal padding based on device size
    @ViewBuilder public func adaptivePadding() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.padding(.horizontal, 32)
        } else {
            self.padding(.horizontal, 16)
        }
    }
} 