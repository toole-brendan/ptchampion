import SwiftUI
import PTDesignSystem

// Legacy file that redefines the badge type
// This file needs to be kept for backward compatibility
// This will forward all calls to the new PTBadge implementation

// Create a typealias to redirect Badge to PTBadge
public typealias Badge = PTBadge

// Add an extension for backward compatibility with the old Badge.Variant enum
extension PTBadge {
    // This mimics the old Badge.Variant enum
    public enum Variant {
        case primary
        case secondary
        case outline
        case destructive
        case success
        
        // Map old variants to new BadgeType
        var toBadgeType: PTBadgeType {
            switch self {
            case .primary: return .default
            case .secondary: return .info
            case .outline: return .default // With custom styling
            case .destructive: return .error
            case .success: return .success
            }
        }
    }
    
    // Convenience initializer for the old Badge API
    public init(text: String, variant: Variant = .primary, icon: Image? = nil) {
        // Use the new initializer with mapped types
        self.init(
            text,
            type: variant.toBadgeType,
            icon: icon
        )
    }
    
    // Recreate the old static factory methods
    public static func status(_ text: String, isActive: Bool) -> PTBadge {
        PTBadge(
            text,
            type: isActive ? .success : .info
        )
    }
    
    public static func count(_ count: Int) -> PTBadge {
        PTBadge(
            "\(count)",
            type: .default
        )
    }
}

/// Shared Badge model (renamed to avoid conflict)
enum AchievementBadgeType: String, CaseIterable {
    case streak, personalBest, milestone
} 