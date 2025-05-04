import SwiftUI
import DesignTokens

/// A design token-driven button component that automatically applies styling
/// based on the design system.
///
/// Usage:
///
/// ```swift
/// PTButton("Sign In", style: .primary) {
///    handleSignIn()
/// }
/// ```
public struct PTButton: View {
    private let title: String
    private let action: () -> Void
    private let style: ButtonStyle
    
    /// Defines the available button styles in the design system
    public enum ButtonStyle {
        /// Primary action button with strong visual emphasis
        case primary
        
        /// Secondary action button with moderate visual emphasis
        case secondary
        
        /// Used for destructive actions like delete or remove
        case destructive
    }
    
    /// Creates a new button with the specified title, style, and action
    /// - Parameters:
    ///   - title: The text to display on the button
    ///   - style: The visual style of the button (default: .primary)
    ///   - action: The closure to execute when the button is tapped
    public init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(foregroundColor)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
        }
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppTheme.GeneratedColors.primary
        case .secondary:
            return AppTheme.GeneratedColors.secondary
        case .destructive:
            return AppTheme.GeneratedColors.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return AppTheme.GeneratedColors.textPrimary
        }
    }
} 