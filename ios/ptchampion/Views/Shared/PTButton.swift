import SwiftUI
import PTDesignSystem

struct PTButton: View {
    let title: String
    let icon: Image?
    let action: () -> Void
    let size: PTButtonSize
    let variant: PTButtonVariant
    let isFullWidth: Bool
    let isLoading: Bool
    
    init(
        title: String,
        icon: Image? = nil,
        action: @escaping () -> Void,
        size: PTButtonSize = .medium,
        variant: PTButtonVariant = .primary,
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
        Button(action: action) {
            HStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
                if let icon = icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                }
                
                Text(title)
                    .lineLimit(1)
            }
        }
        .ptButtonStyle(
            variant: variant,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            size: size
        )
        .disabled(isLoading)
    }
    
    var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }
}

// Preview provider
struct PTButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
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
        .background(AppTheme.GeneratedColors.background)
        .previewLayout(.sizeThatFits)
    }
} 