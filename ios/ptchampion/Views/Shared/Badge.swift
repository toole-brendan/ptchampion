import SwiftUI
import PTDesignSystem

// Badge size options for flexibility
public enum BadgeSize {
    case small
    case medium
    case large
    
    var textSize: CGFloat {
        switch self {
        case .small: return AppTheme.GeneratedTypography.tiny
        case .medium: return AppTheme.GeneratedTypography.small
        case .large: return AppTheme.GeneratedTypography.body
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}

public struct PTBadge: View {
    private let text: String
    private let type: PTBadgeType
    private let size: BadgeSize
    private let icon: Image?
    private let count: Int?
    
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        _ text: String,
        type: PTBadgeType = .default,
        size: BadgeSize = .medium,
        icon: Image? = nil,
        count: Int? = nil
    ) {
        self.text = text
        self.type = type
        self.size = size
        self.icon = icon
        self.count = count
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // Icon if provided
            if let icon = icon {
                icon
                    .font(.system(size: size.textSize))
                    .foregroundColor(type.foregroundColor)
            }
            
            // Text label
            Text(text)
                .font(.system(size: size.textSize, weight: .medium))
                .foregroundColor(type.foregroundColor)
            
            // Count if provided
            if let count = count {
                Text("\(count)")
                    .font(.system(size: size.textSize, weight: .bold, design: .monospaced))
                    .foregroundColor(type.foregroundColor)
            }
        }
        .padding(.vertical, size.verticalPadding)
        .padding(.horizontal, size.horizontalPadding)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.badge)
                    .fill(type.backgroundColor)
                
                // Subtle gradient overlay for dimension
                RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.badge)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Animated pulse for important/new badges
                if type == .new || type == .important {
                    RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.badge)
                        .stroke(type.foregroundColor.opacity(isAnimating ? 0.0 : 0.5), lineWidth: 2)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                }
            }
        )
        .cornerRadius(AppTheme.GeneratedRadius.badge)
        // Optional shadow for some badge types
        .shadow(
            color: type == .premium || type == .important ? 
                type.foregroundColor.opacity(0.3) : Color.clear,
            radius: 2,
            x: 0,
            y: 1
        )
        .onAppear {
            if (type == .new || type == .important) && !reduceMotion {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
}

// Badge type variations for semantic meaning
public enum PTBadgeType {
    case `default`    // General purpose badge
    case success      // Success or completion
    case warning      // Warning or caution
    case error        // Error or alert
    case info         // Informational
    case premium      // Premium or paid feature
    case new          // New feature or item
    case important    // Important notice
    
    // Custom colors
    var backgroundColor: Color {
        switch self {
        case .default:
            return AppTheme.GeneratedColors.brassGold.opacity(0.15)
        case .success:
            return AppTheme.GeneratedColors.success.opacity(0.15)
        case .warning:
            return AppTheme.GeneratedColors.warning.opacity(0.15)
        case .error:
            return AppTheme.GeneratedColors.error.opacity(0.15)
        case .info:
            return AppTheme.GeneratedColors.info.opacity(0.15)
        case .premium:
            return AppTheme.GeneratedColors.brassGold.opacity(0.2)
        case .new:
            return AppTheme.GeneratedColors.primary.opacity(0.15)
        case .important:
            return AppTheme.GeneratedColors.error.opacity(0.15)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .default:
            return AppTheme.GeneratedColors.brassGold
        case .success:
            return AppTheme.GeneratedColors.success
        case .warning:
            return AppTheme.GeneratedColors.warning
        case .error:
            return AppTheme.GeneratedColors.error
        case .info:
            return AppTheme.GeneratedColors.info
        case .premium:
            return AppTheme.GeneratedColors.brassGold
        case .new:
            return AppTheme.GeneratedColors.primary
        case .important:
            return AppTheme.GeneratedColors.error
        }
    }
}

// Preview for badge variations
struct PTBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                PTBadge("Default")
                PTBadge("Small", size: .small)
                PTBadge("Large", size: .large)
            }
            
            HStack {
                PTBadge("Success", type: .success)
                PTBadge("Warning", type: .warning)
                PTBadge("Error", type: .error)
            }
            
            HStack {
                PTBadge("Info", type: .info)
                PTBadge("Premium", type: .premium)
                PTBadge("New", type: .new)
            }
            
            HStack {
                PTBadge("With icon", icon: Image(systemName: "star.fill"))
                PTBadge("With count", count: 5)
                PTBadge("Important", type: .important, icon: Image(systemName: "exclamationmark.triangle"))
            }
            
            HStack {
                PTBadge("Push-ups", icon: Image(systemName: "figure.highintensity.intervaltraining"), count: 42)
                PTBadge("Run", type: .success, icon: Image(systemName: "figure.run"), count: 5)
                PTBadge("Best Rank", type: .premium, icon: Image(systemName: "trophy"), count: 1)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                PTBadge("Default")
                PTBadge("New", type: .new)
                PTBadge("Premium", type: .premium)
            }
        }
        .padding()
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
} 