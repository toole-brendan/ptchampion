import SwiftUI
import DesignTokens

/// A container component that provides consistent card styling based on design tokens.
///
/// The card applies background, corner radius, and shadow styling automatically,
/// while allowing you to provide any content within the card.
///
/// Usage:
/// ```swift
/// PTCard {
///     VStack(alignment: .leading) {
///         Text("Card Title").font(.headline)
///         Text("Card Content").font(.body)
///     }
/// }
/// ```
public struct PTCard<Content: View>: View {
    private let content: Content
    
    /// Creates a new card with the specified content
    /// - Parameter content: A closure that returns the content to display within the card
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(16)
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(8)
            .withShadow(AppTheme.GeneratedShadows.small)
    }
} 