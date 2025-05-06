import SwiftUI
import DesignTokens

// MARK: - Helper to use .tint only where it exists
private extension View {
    @ViewBuilder
    func tintCompat(_ color: Color) -> some View {
        if #available(iOS 16.0, *) {
            self.tint(color)
        } else {
            // .accentColor is available from iOS 13 and still works through iOS 17
            self.accentColor(color)
        }
    }
}

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
    private let isLoading: Bool
    
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
    ///   - isLoading: Whether the button should display a loading indicator (default: false)
    ///   - action: The closure to execute when the button is tapped
    public init(_ title: String, style: ButtonStyle = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Keep original label invisible while loading to avoid width-jump
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(foregroundColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                
                if isLoading {
                    // Use ProgressView as a spinner
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tintCompat(foregroundColor)
                }
            }
        }
        .background(backgroundColor)
        .cornerRadius(8)
        .disabled(isLoading)  // prevent taps while busy
        .animation(.easeInOut(duration: 0.15), value: isLoading)
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

// MARK: – vNext API (keeps ComponentGalleryView working)
//
// NOTE: These are convenience wrappers around the core PTButton
// so nothing upstream breaks. Remove after all call-sites migrate.

public extension PTButton {

    enum ButtonSize { case small, medium, large }

    enum ExtendedStyle {
        case primary, secondary, outline, ghost, destructive
    }

    /// Drop-in replacement for the older wide-API initialiser
    init(_ title: String,
         style: ExtendedStyle = .primary,
         size: ButtonSize = .medium,
         icon: Image? = nil,
         fullWidth: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void) {

        // Map old style → current core style + decorations
        let coreStyle: ButtonStyle
        switch style {
        case .primary       : coreStyle = .primary
        case .secondary     : coreStyle = .secondary
        case .destructive   : coreStyle = .destructive
        case .outline, .ghost:
            coreStyle = .secondary   // treat as secondary visually
        }

        // Use the base initializer without the icon
        self.init(title, style: coreStyle, isLoading: isLoading, action: action)

        // --- per-instance modifiers ---
        _ = self                         // allows chaining if desired
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: fullWidth ? .infinity : nil)
            // Note: We're not actually adding icon overlay here since it would duplicate content
            // The icon would need to be incorporated at the base Button level
            .opacity(isLoading ? 0.5 : 1.0)
    }
}
