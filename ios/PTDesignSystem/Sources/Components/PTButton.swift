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
    private let isLoading: Bool
    private let icon: Image?
    private let fullWidth: Bool
    private let size: ButtonSize
    private let isEnabled: Bool
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPressed = false
    
    /// Defines the available button styles in the design system
    public enum ButtonStyle {
        /// Primary action button with strong visual emphasis
        case primary
        
        /// Secondary action button with moderate visual emphasis
        case secondary
        
        /// Used for destructive actions like delete or remove
        case destructive
        
        var backgroundColor: SwiftUI.Color {
            switch self {
            case .primary:
                return DesignTokens.Color.primary
            case .secondary:
                return DesignTokens.Color.secondary.opacity(0.1)
            case .destructive:
                return DesignTokens.Color.error
            }
        }
        
        var foregroundColor: SwiftUI.Color {
            switch self {
            case .primary:
                return DesignTokens.Color.textOnPrimary
            case .secondary:
                return DesignTokens.Color.textPrimary
            case .destructive:
                return .white
            }
        }
        
        var disabledBackgroundColor: SwiftUI.Color {
            return backgroundColor.opacity(0.5)
        }
        
        var disabledColor: SwiftUI.Color {
            return foregroundColor.opacity(0.7)
        }
        
        var borderColor: SwiftUI.Color {
            return SwiftUI.Color.clear
        }
        
        var borderWidth: CGFloat {
            return 0
        }
        
        var contentPadding: EdgeInsets {
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }
        
        var minimumWidth: CGFloat {
            return 0
        }
        
        var iconSize: CGFloat {
            return 16
        }
        
        var useShadow: Bool {
            return self == .primary
        }
        
        var shouldShowLeadingIcon: Bool {
            return true
        }
    }
    
    /// Button size variants
    public enum ButtonSize {
        case small
        case medium
        case large
        
        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .small: return (horizontal: 12, vertical: 8)
            case .medium: return (horizontal: 16, vertical: 12)
            case .large: return (horizontal: 20, vertical: 16)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }
    
    /// Creates a new button with the specified title, style, and action
    /// - Parameters:
    ///   - title: The text to display on the button
    ///   - style: The visual style of the button (default: .primary)
    ///   - size: Size variant of the button (default: .medium)
    ///   - icon: Optional icon to display alongside text
    ///   - fullWidth: Whether the button should expand to full width
    ///   - isLoading: Whether the button should display a loading indicator (default: false)
    ///   - isEnabled: Whether the button is enabled (default: true)
    ///   - action: The closure to execute when the button is tapped
    public init(_ title: String, 
                style: ButtonStyle = .primary, 
                size: ButtonSize = .medium,
                icon: Image? = nil,
                fullWidth: Bool = false,
                isLoading: Bool = false,
                isEnabled: Bool = true,
                action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.icon = icon
        self.fullWidth = fullWidth
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            if !isLoading {
                hapticFeedback()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if let icon = icon, style.shouldShowLeadingIcon {
                    icon
                        .font(.system(size: style.iconSize))
                        .foregroundColor(isEnabled ? style.foregroundColor : style.disabledColor)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: style.foregroundColor
                        ))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(ThemeManager.useWebTheme ? Typography.button : .system(size: 16, weight: .semibold))
                        .foregroundColor(isEnabled ? style.foregroundColor : style.disabledColor)
                        .lineLimit(1)
                }
            }
            .padding(style.contentPadding)
            .frame(minWidth: style.minimumWidth, maxWidth: fullWidth ? .infinity : nil)
            .background(
                isEnabled 
                ? style.backgroundColor 
                : style.disabledBackgroundColor
            )
            .cornerRadius(ThemeManager.useWebTheme ? 
                CornerRadius.md : 
                CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeManager.useWebTheme ? 
                    CornerRadius.md : 
                    CornerRadius.button)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: style.useShadow ? (ThemeManager.useWebTheme ? 
                    Shadow.button.color : 
                    SwiftUI.Color.black.opacity(0.1)) : SwiftUI.Color.clear,
                radius: style.useShadow ? (ThemeManager.useWebTheme ? 
                    Shadow.button.radius : 
                    4) : 0,
                x: style.useShadow ? (ThemeManager.useWebTheme ? 
                    Shadow.button.x : 
                    0) : 0,
                y: style.useShadow ? (ThemeManager.useWebTheme ? 
                    Shadow.button.y : 
                    2) : 0
            )
        }
        .opacity(isEnabled ? 1.0 : 0.6)
        .disabled(!isEnabled || isLoading)
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: – Extended styles and backwards compatibility
public extension PTButton {
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
         isEnabled: Bool = true,
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

        // Use the new initializer
        self.init(
            title, 
            style: coreStyle, 
            size: size,
            icon: icon,
            fullWidth: fullWidth,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
}
