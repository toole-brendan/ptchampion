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
    private let icon: Image?
    private let fullWidth: Bool
    private let size: ButtonSize
    
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
    ///   - action: The closure to execute when the button is tapped
    public init(_ title: String, 
                style: ButtonStyle = .primary, 
                size: ButtonSize = .medium,
                icon: Image? = nil,
                fullWidth: Bool = false,
                isLoading: Bool = false, 
                action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.icon = icon
        self.fullWidth = fullWidth
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Add haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Short delay to show press animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                // Show icon if provided
                if let icon = icon, !isLoading {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.fontSize, height: size.fontSize)
                        .foregroundColor(foregroundColor)
                }
                
                // Keep original label invisible while loading to avoid width-jump
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(foregroundColor)
                
                if isLoading {
                    // Use ProgressView as a spinner
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tintCompat(foregroundColor)
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, size.padding.horizontal)
            .padding(.vertical, size.padding.vertical)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                        .fill(backgroundColor)
                    
                    // Add light highlight on top for depth
                    RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                foregroundColor.opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        ))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                    .stroke(style == .secondary ? AppTheme.GeneratedColors.tacticalGray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isPressed && !reduceMotion ? 0.97 : 1.0)
            .shadow(color: backgroundColor.opacity(style == .primary ? 0.3 : 0), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)  // prevent taps while busy
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isLoading)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppTheme.GeneratedColors.primary
        case .secondary:
            return AppTheme.GeneratedColors.secondary.opacity(0.1)
        case .destructive:
            return AppTheme.GeneratedColors.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return AppTheme.GeneratedColors.textOnPrimary
        case .secondary:
            return AppTheme.GeneratedColors.textPrimary
        case .destructive:
            return .white
        }
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
            action: action
        )
    }
}
