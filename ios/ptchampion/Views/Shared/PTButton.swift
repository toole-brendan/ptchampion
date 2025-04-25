import SwiftUI

struct PTButton: View {
    enum Size {
        case small, medium, large
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return AppConstants.Spacing.sm
            case .medium: return AppConstants.Spacing.lg
            case .large: return AppConstants.Spacing.xl
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return AppConstants.Spacing.xs
            case .medium: return AppConstants.Spacing.sm
            case .large: return AppConstants.Spacing.md
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return AppConstants.FontSize.xs
            case .medium: return AppConstants.FontSize.md
            case .large: return AppConstants.FontSize.lg
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    enum Variant {
        case primary, secondary, outline, ghost, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .brassGold
            case .secondary: return .armyTan
            case .outline, .ghost: return .clear
            case .destructive: return Color(hex: "#DC2626") // red-600 from Tailwind
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary: return .commandBlack
            case .outline, .ghost: return .brassGold
            }
        }
        
        var hasBorder: Bool {
            return self == .outline
        }
        
        var borderColor: Color {
            return .brassGold
        }
    }
    
    let title: String
    let icon: Image?
    let action: () -> Void
    let size: Size
    let variant: Variant
    let isFullWidth: Bool
    let isLoading: Bool
    
    init(
        title: String,
        icon: Image? = nil,
        action: @escaping () -> Void,
        size: Size = .medium,
        variant: Variant = .primary,
        isFullWidth: Bool = false,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.size = size
        self.variant = variant
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: isLoading ? {} : action) {
            HStack(spacing: AppConstants.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.iconSize, height: size.iconSize)
                }
                
                Text(title)
                    .font(.custom(AppFonts.bodyBold, size: size.fontSize))
                    .lineLimit(1)
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(variant.backgroundColor)
            .foregroundColor(variant.textColor)
            .cornerRadius(AppConstants.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                    .stroke(variant.hasBorder ? variant.borderColor : Color.clear, lineWidth: 1)
            )
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .disabled(isLoading)
    }
}

// Preview provider
struct PTButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Group {
                PTButton(title: "Primary Button", action: {})
                
                PTButton(
                    title: "Secondary Button",
                    icon: Image(systemName: "arrow.right"),
                    action: {},
                    variant: .secondary
                )
                
                PTButton(
                    title: "Outline Button",
                    action: {},
                    variant: .outline,
                    isFullWidth: true
                )
                
                PTButton(
                    title: "Ghost Button",
                    action: {},
                    variant: .ghost
                )
                
                PTButton(
                    title: "Destructive Button",
                    icon: Image(systemName: "trash"),
                    action: {},
                    variant: .destructive
                )
                
                PTButton(
                    title: "Loading Button",
                    action: {},
                    isLoading: true
                )
                
                PTButton(
                    title: "Small Button",
                    action: {},
                    size: .small
                )
                
                PTButton(
                    title: "Large Button",
                    icon: Image(systemName: "play.fill"),
                    action: {},
                    size: .large,
                    isFullWidth: true
                )
            }
        }
        .padding()
        .background(Color.tacticalCream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 