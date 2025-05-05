import SwiftUI
import PTDesignSystem

struct Badge: View {
    enum Variant {
        case primary
        case secondary
        case outline
        case destructive
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppTheme.GeneratedColors.primary
            case .secondary: return AppTheme.GeneratedColors.secondary
            case .outline: return .clear
            case .destructive: return AppTheme.GeneratedColors.error
            case .success: return AppTheme.GeneratedColors.success
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive, .success: return AppTheme.GeneratedColors.textOnPrimary
            case .secondary: return AppTheme.GeneratedColors.textPrimary
            case .outline: return AppTheme.GeneratedColors.primary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .outline: return AppTheme.GeneratedColors.primary
            default: return nil
            }
        }
    }
    
    let text: String
    let variant: Variant
    let icon: Image?
    
    init(text: String, variant: Variant = .primary, icon: Image? = nil) {
        self.text = text
        self.variant = variant
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: AppTheme.GeneratedSpacing.extraSmall) {
            if let icon = icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
            }
            
            PTLabel(text, style: .bodyBold, size: .small)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.GeneratedSpacing.small)
        .padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
        .background(variant.backgroundColor)
        .foregroundColor(variant.textColor)
        .cornerRadius(AppTheme.GeneratedRadius.full)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.full)
                .stroke(variant.borderColor ?? Color.clear, lineWidth: variant.borderColor != nil ? 1 : 0)
        )
    }
}

// Common usage variants
extension Badge {
    static func status(_ text: String, isActive: Bool) -> Badge {
        Badge(
            text: text,
            variant: isActive ? .success : .secondary
        )
    }
    
    static func count(_ count: Int) -> Badge {
        Badge(
            text: "\(count)",
            variant: .primary
        )
    }
}

// Preview
struct Badge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                HStack(spacing: AppTheme.GeneratedSpacing.large) {
                    Badge(text: "Primary")
                    Badge(text: "Secondary", variant: .secondary)
                    Badge(text: "Outline", variant: .outline)
                }
                
                HStack(spacing: AppTheme.GeneratedSpacing.large) {
                    Badge(text: "Destructive", variant: .destructive)
                    Badge(text: "Success", variant: .success)
                }
                
                HStack(spacing: AppTheme.GeneratedSpacing.large) {
                    Badge(text: "With Icon", icon: Image(systemName: "checkmark.circle.fill"))
                    Badge.status("Active", isActive: true)
                    Badge.status("Inactive", isActive: false)
                    Badge.count(5)
                }
            }
            .padding()
            .background(AppTheme.GeneratedColors.background.opacity(0.5))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Light Mode")
            
            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                HStack(spacing: AppTheme.GeneratedSpacing.large) {
                    Badge(text: "Primary")
                    Badge(text: "Secondary", variant: .secondary)
                    Badge(text: "Outline", variant: .outline)
                }
            }
            .padding()
            .background(AppTheme.GeneratedColors.background.opacity(0.5))
            .previewLayout(.sizeThatFits)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark Mode")
        }
    }
}

// Updated to use GeneratedColors
private extension BadgeType {
    var color: Color {
        switch self {
        case .primary: return AppTheme.GeneratedColors.brassGold
        case .secondary: return AppTheme.GeneratedColors.armyTan
        case .outline: return .clear
        case .destructive: return AppTheme.GeneratedColors.error // Use semantic color instead of hardcoded
        case .success: return AppTheme.GeneratedColors.success // Use semantic color instead of hardcoded
        }
    }
} 