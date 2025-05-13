import SwiftUI
import DesignTokens

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
} 