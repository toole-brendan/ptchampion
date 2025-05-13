import SwiftUI
import DesignTokens
// Import modules needed for CardVariant and adaptivePadding
import PTDesignSystem

public extension View {
    /// Card styling with web style
    func webCardStyle(
        shadowStyle: DSShadow = Shadow.card,
        cornerRadius: CGFloat = CornerRadius.lg
    ) -> some View {
        self
            .background(Color.surface)
            .cornerRadius(cornerRadius)
            .withDSShadow(shadowStyle)
    }

    /// Add standard spacing around content using web spacing
    func webSpacing(
        horizontal: CGFloat = Spacing.space4,
        vertical: CGFloat = Spacing.space4
    ) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }
    
    /// Container view modifier that limits max width and applies horizontal padding responsively
    func container(maxWidth: CGFloat = 600) -> some View {
        self.frame(maxWidth: maxWidth)
            .adaptivePadding()
    }
    
    /// Card view modifier for card styling
    func card(variant: CardVariant = .default) -> some View {
        self.modifier(CardModifier(variant: variant))
    }
} 