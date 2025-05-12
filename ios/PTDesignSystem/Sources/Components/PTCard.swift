import SwiftUI
import DesignTokens

/// Card style options for flexibility
public enum PTCardStyle: Equatable {
    case standard    // Default card style
    case elevated    // More prominent shadow
    case flat        // No shadow, just border
    case highlight   // Accent color border
    case interactive // Designed for touch interaction
    
    // Custom style with specified parameters
    case custom(
        backgroundColor: Color,
        cornerRadius: CGFloat,
        shadowRadius: CGFloat,
        borderColor: Color?,
        borderWidth: CGFloat
    )
    
    // Implementation of Equatable for custom case
    public static func == (lhs: PTCardStyle, rhs: PTCardStyle) -> Bool {
        switch (lhs, rhs) {
        case (.standard, .standard),
             (.elevated, .elevated),
             (.flat, .flat),
             (.highlight, .highlight),
             (.interactive, .interactive):
            return true
        case (.custom, .custom):
            // For custom, we consider them equal if they're both custom
            // A more detailed comparison could be implemented if needed
            return true
        default:
            return false
        }
    }
}

/// A container component that provides card-like styling for content
public struct PTCard<Content: View>: View {
    private let content: Content
    private let style: PTCardStyle
    private let padding: EdgeInsets?
    
    // States for interactive cards
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Creates a new card with the specified content and style
    /// - Parameters:
    ///   - style: The visual style of the card (default: .standard)
    ///   - padding: Optional custom padding (default: use standard spacing)
    ///   - content: The content to display inside the card
    public init(
        style: PTCardStyle = .standard,
        padding: EdgeInsets? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding ?? EdgeInsets(
                top: AppTheme.GeneratedSpacing.contentPadding,
                leading: AppTheme.GeneratedSpacing.contentPadding,
                bottom: AppTheme.GeneratedSpacing.contentPadding,
                trailing: AppTheme.GeneratedSpacing.contentPadding
            ))
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            // Apply scale effect for interactive cards
            .scaleEffect(isPressed && style == .interactive && !reduceMotion ? 0.98 : 1.0)
            // Apply brightness change for interactive cards
            .brightness(isPressed && style == .interactive ? 0.03 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            // Only add gesture recognizer for interactive cards
            .gesture(style == .interactive ? pressGesture : nil)
    }
    
    // The press gesture for interactive cards
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    isPressed = true
                    // Add light haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
            .onEnded { _ in
                isPressed = false
            }
    }
    
    // Background view based on style
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .standard, .elevated, .flat, .highlight, .interactive:
            // Use web theme if enabled
            if ThemeManager.useWebTheme {
                PTDesignSystem.AppTheme.Color.surface
            } else {
                // Gradient background for more dimension
                LinearGradient(
                    gradient: Gradient(colors: [
                        PTDesignSystem.AppTheme.GeneratedColors.cardBackground,
                        PTDesignSystem.AppTheme.GeneratedColors.cardBackground.opacity(0.97)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .custom(let backgroundColor, _, _, _, _):
            backgroundColor
        }
    }
    
    // Border overlay based on style
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                borderColor,
                lineWidth: borderWidth
            )
    }
    
    // Card corner radius based on style
    private var cornerRadius: CGFloat {
        switch style {
        case .custom(_, let radius, _, _, _):
            return radius
        default:
            // Use web theme radius if enabled
            return ThemeManager.useWebTheme ? 
                AppTheme.Radius.lg : 
                AppTheme.GeneratedRadius.card
        }
    }
    
    // Shadow color based on style
    private var shadowColor: Color {
        if ThemeManager.useWebTheme {
            switch style {
            case .standard, .interactive:
                return AppTheme.Shadow.card.color
            case .elevated:
                return AppTheme.Shadow.md.color
            case .flat, .highlight:
                return Color.clear
            case .custom(_, _, _, _, _):
                return AppTheme.Shadow.card.color
            }
        } else {
            switch style {
            case .standard, .interactive:
                return Color.black.opacity(0.1)
            case .elevated:
                return Color.black.opacity(0.15)
            case .flat, .highlight:
                return Color.clear
            case .custom(_, _, _, _, _):
                return Color.black.opacity(0.1)
            }
        }
    }
    
    // Shadow radius based on style
    private var shadowRadius: CGFloat {
        if ThemeManager.useWebTheme {
            switch style {
            case .standard, .interactive:
                return AppTheme.Shadow.card.radius
            case .elevated:
                return AppTheme.Shadow.md.radius
            case .flat, .highlight:
                return 0
            case .custom(_, _, let radius, _, _):
                return radius
            }
        } else {
            switch style {
            case .standard, .interactive:
                return 4
            case .elevated:
                return 8
            case .flat, .highlight:
                return 0
            case .custom(_, _, let radius, _, _):
                return radius
            }
        }
    }
    
    // Shadow Y offset
    private var shadowY: CGFloat {
        if ThemeManager.useWebTheme {
            switch style {
            case .standard, .interactive:
                return PTDesignSystem.AppTheme.Shadow.card.y
            case .elevated:
                return PTDesignSystem.AppTheme.Shadow.md.y
            case .flat, .highlight:
                return 0
            case .custom(_, _, _, _, _):
                return PTDesignSystem.AppTheme.Shadow.card.y
            }
        } else {
            switch style {
            case .standard, .interactive:
                return 2
            case .elevated:
                return 4
            case .flat, .highlight:
                return 0
            case .custom(_, _, _, _, _):
                return 2
            }
        }
    }
    
    // Border color based on style
    private var borderColor: Color {
        if ThemeManager.useWebTheme {
            switch style {
            case .flat:
                return PTDesignSystem.AppTheme.Color.borderDefault
            case .highlight:
                return PTDesignSystem.AppTheme.Color.brand500
            case .interactive:
                return isPressed ? 
                    PTDesignSystem.AppTheme.Color.brand500.opacity(0.3) : 
                    PTDesignSystem.AppTheme.Color.borderDefault
            case .custom(_, _, _, let color, _):
                return color ?? Color.clear
            default:
                return Color.clear
            }
        } else {
            switch style {
            case .flat:
                return PTDesignSystem.AppTheme.GeneratedColors.tacticalGray.opacity(0.3)
            case .highlight:
                return PTDesignSystem.AppTheme.GeneratedColors.brassGold
            case .interactive:
                return isPressed ? 
                    PTDesignSystem.AppTheme.GeneratedColors.brassGold.opacity(0.3) : 
                    PTDesignSystem.AppTheme.GeneratedColors.tacticalGray.opacity(0.3)
            case .custom(_, _, _, let color, _):
                return color ?? Color.clear
            default:
                return Color.clear
            }
        }
    }
    
    // Border width based on style
    private var borderWidth: CGFloat {
        switch style {
        case .flat:
            return 1
        case .highlight:
            return 1.5
        case .interactive:
            return 1
        case .custom(_, _, _, _, let width):
            return width
        default:
            return 0
        }
    }
}

// Add an extension for interactive cards
public extension PTCard {
    /// Creates a new interactive card that responds to touch
    /// - Parameters:
    ///   - action: The action to perform when the card is tapped
    ///   - content: The content to display inside the card
    init(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            style: .interactive,
            content: content
        )
    }
}

// Preview
struct PTCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                PTCard {
                    Text("Standard Card")
                        .padding()
                }
                
                PTCard(style: .elevated) {
                    Text("Elevated Card")
                        .padding()
                }
                
                PTCard(style: .flat) {
                    Text("Flat Card")
                        .padding()
                }
                
                PTCard(style: .highlight) {
                    Text("Highlight Card")
                        .padding()
                }
                
                PTCard(style: .interactive) {
                    Text("Interactive Card (Press Me)")
                        .padding()
                }
                
                PTCard(style: .custom(
                    backgroundColor: AppTheme.GeneratedColors.brassGold.opacity(0.1),
                    cornerRadius: 20,
                    shadowRadius: 5,
                    borderColor: AppTheme.GeneratedColors.brassGold.opacity(0.3),
                    borderWidth: 2
                )) {
                    Text("Custom Card")
                        .padding()
                }
            }
            .padding()
        }
    }
} 