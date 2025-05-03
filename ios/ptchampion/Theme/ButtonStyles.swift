import SwiftUI

enum PTButtonVariant {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

// Create a struct to encapsulate the variant styling for cleaner code
private struct VariantStyle {
    let foreground: Color
    let background: Color
    let borderColor: Color?
    let loadingTint: Color
    
    init(foreground: Color, background: Color, borderColor: Color? = nil) {
        self.foreground = foreground
        self.background = background
        self.borderColor = borderColor
        self.loadingTint = foreground
    }
}

struct PTButtonStyle: ButtonStyle {
    var variant: PTButtonVariant = .primary
    var isFullWidth: Bool = false
    var isLoading: Bool = false
    var size: PTButtonSize = .medium
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Map variants to their styles for cleaner code
    private var style: VariantStyle {
        switch variant {
        case .primary:
            return VariantStyle(foreground: AppTheme.GeneratedColors.deepOps, background: AppTheme.GeneratedColors.brassGold)
        case .secondary:
            return VariantStyle(foreground: AppTheme.GeneratedColors.cream, background: AppTheme.GeneratedColors.deepOps)
        case .outline:
            return VariantStyle(foreground: AppTheme.GeneratedColors.brassGold, background: .clear, borderColor: AppTheme.GeneratedColors.brassGold)
        case .ghost:
            return VariantStyle(foreground: AppTheme.GeneratedColors.deepOps, background: .clear)
        case .destructive:
            return VariantStyle(foreground: .white, background: AppTheme.GeneratedColors.error)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        // Use offset instead of scale effect for web parity
        let yOffset: CGFloat = configuration.isPressed && !reduceMotion ? -2 : 0
        let pressedBackground = variant == .ghost ? 
            style.foreground.opacity(0.1) : 
            style.background.opacity(0.9)
        
        return configuration.label
            .font(size.font)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
            .foregroundColor(style.foreground)
            .background(configuration.isPressed && variant == .ghost ? pressedBackground : style.background)
            .cornerRadius(AppTheme.GeneratedRadius.button)
            .overlay(
                Group {
                    if let borderColor = style.borderColor {
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.button)
                            .strokeBorder(borderColor, lineWidth: 1)
                    }
                }
            )
            .overlay(
                isLoading ? ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: style.loadingTint))
                    .padding(8) : nil
            )
            .opacity(configuration.isPressed && variant != .ghost ? 0.9 : 1.0)
            .offset(y: yOffset) // Replace scale with y-offset for web parity
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .disabled(isLoading)
    }
}

enum PTButtonSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return AppTheme.GeneratedTypography.body(size: 12)
        case .medium: return AppTheme.GeneratedTypography.body(size: 14)
        case .large: return AppTheme.GeneratedTypography.body(size: 16)
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }
}

extension View {
    func ptButtonStyle(
        variant: PTButtonVariant = .primary,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        size: PTButtonSize = .medium
    ) -> some View {
        self.buttonStyle(PTButtonStyle(
            variant: variant,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            size: size
        ))
    }
} 