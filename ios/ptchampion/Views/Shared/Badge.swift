import SwiftUI

struct Badge: View {
    enum Variant {
        case primary
        case secondary
        case outline
        case destructive
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .brassGold
            case .secondary: return .armyTan
            case .outline: return .clear
            case .destructive: return Color(hex: "#DC2626") // red-600 from Tailwind
            case .success: return Color(hex: "#10B981") // emerald-500 from Tailwind
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive, .success: return .white
            case .secondary: return .commandBlack
            case .outline: return .brassGold
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .outline: return .brassGold
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
        HStack(spacing: AppConstants.Spacing.xs) {
            if let icon = icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
            }
            
            Text(text)
                .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.xs))
                .lineLimit(1)
        }
        .padding(.horizontal, AppConstants.Spacing.sm)
        .padding(.vertical, AppConstants.Spacing.xs)
        .background(variant.backgroundColor)
        .foregroundColor(variant.textColor)
        .cornerRadius(AppConstants.Radius.full)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Radius.full)
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
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.lg) {
                Badge(text: "Primary")
                Badge(text: "Secondary", variant: .secondary)
                Badge(text: "Outline", variant: .outline)
            }
            
            HStack(spacing: AppConstants.Spacing.lg) {
                Badge(text: "Destructive", variant: .destructive)
                Badge(text: "Success", variant: .success)
            }
            
            HStack(spacing: AppConstants.Spacing.lg) {
                Badge(text: "With Icon", icon: Image(systemName: "checkmark.circle.fill"))
                Badge.status("Active", isActive: true)
                Badge.status("Inactive", isActive: false)
                Badge.count(5)
            }
        }
        .padding()
        .background(Color.tacticalCream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 