import SwiftUI

public enum AppTheme {
    public enum Colors {
        // Brand colors - use Asset Catalog references with namespace
        @available(*, deprecated, message: "Use GeneratedColors.cream instead")
        public static let cream = Color("Cream")
        @available(*, deprecated, message: "Use GeneratedColors.deepOps instead")
        public static let deepOps = Color("DeepOps")
        @available(*, deprecated, message: "Use GeneratedColors.brassGold instead")
        public static let brassGold = Color("BrassGold")
        @available(*, deprecated, message: "Use GeneratedColors.armyTan instead")
        public static let armyTan = Color("ArmyTan")
        @available(*, deprecated, message: "Use GeneratedColors.oliveMist instead")
        public static let oliveMist = Color("OliveMist")
        @available(*, deprecated, message: "Use GeneratedColors.commandBlack instead")
        public static let commandBlack = Color("CommandBlack")
        @available(*, deprecated, message: "Use GeneratedColors.tacticalGray instead")
        public static let tacticalGray = Color("TacticalGray")
        
        // Semantic colors (maintains backward compatibility)
        public static let primary = deepOps
        public static let secondary = brassGold
        public static let accent = brassGold
        public static let background = cream
        public static let cardBackground = Color.white.opacity(0.8)
        
        public static let success = Color("Success")
        public static let warning = Color("Warning")
        public static let error = Color("Error")
        public static let info = Color("Info")
        
        public static let textPrimary = commandBlack
        public static let textSecondary = deepOps
        public static let textTertiary = tacticalGray
    }
    
    public enum Typography {
        // Based on the web frontend fonts
        @available(*, deprecated, message: "Use GeneratedTypography.heading(size:) instead")
        public static func heading(size: CGFloat = 34) -> Font {
            Font.custom("BebasNeue-Bold", size: size)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.heading1() instead")
        public static func heading1() -> Font {
            heading(size: 40)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.heading2() instead")
        public static func heading2() -> Font {
            heading(size: 32)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.heading3() instead")
        public static func heading3() -> Font {
            heading(size: 26)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.heading4() instead")
        public static func heading4() -> Font {
            heading(size: 22)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.body(size:) instead")
        public static func body(size: CGFloat = 16) -> Font {
            Font.custom("Montserrat-Regular", size: size)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.bodyBold(size:) instead")
        public static func bodyBold(size: CGFloat = 16) -> Font {
            Font.custom("Montserrat-Bold", size: size)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.bodySemiBold(size:) instead")
        public static func bodySemiBold(size: CGFloat = 16) -> Font {
            Font.custom("Montserrat-SemiBold", size: size)
        }
        
        @available(*, deprecated, message: "Use GeneratedTypography.mono(size:) instead")
        public static func mono(size: CGFloat = 14) -> Font {
            Font.custom("RobotoMono-Medium", size: size)
        }
    }
    
    public enum Radius {
        @available(*, deprecated, message: "Use GeneratedRadius.card instead")
        public static let card: CGFloat = 12
        @available(*, deprecated, message: "Use GeneratedRadius.panel instead")
        public static let panel: CGFloat = 16
        @available(*, deprecated, message: "Use GeneratedRadius.button instead")
        public static let button: CGFloat = 8
        @available(*, deprecated, message: "Use GeneratedRadius.input instead")
        public static let input: CGFloat = 8
    }
    
    public enum Spacing {
        @available(*, deprecated, message: "Use GeneratedSpacing.section instead")
        public static let section: CGFloat = 32 // 2rem
        @available(*, deprecated, message: "Use GeneratedSpacing.cardGap instead")
        public static let cardGap: CGFloat = 16 // 1rem
        @available(*, deprecated, message: "Use GeneratedSpacing.contentPadding instead")
        public static let contentPadding: CGFloat = 16
        @available(*, deprecated, message: "Use GeneratedSpacing.itemSpacing instead")
        public static let itemSpacing: CGFloat = 8
    }
    
    public enum Shadows {
        @available(*, deprecated, message: "Use GeneratedShadows.small instead")
        public static let small = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        @available(*, deprecated, message: "Use GeneratedShadows.medium instead")
        public static let medium = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        @available(*, deprecated, message: "Use GeneratedShadows.large instead")
        public static let large = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        
        public static let card = small
        public static let cardMd = medium
        public static let cardLg = large
    }
    
    // Add Animation constants
    public enum Animation {
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    // Add DistanceUnit enum
    public enum DistanceUnit: String, Codable, CaseIterable {
        case kilometers = "km"
        case miles = "mi"

        public var id: String { self.rawValue }

        public var displayName: String {
            switch self {
            case .kilometers: return "Kilometers"
            case .miles: return "Miles"
            }
        }

        // Conversion factor from meters
        public func convertFromMeters(_ meters: Double) -> Double {
            switch self {
            case .kilometers: return meters / 1000.0
            case .miles: return meters / 1609.34
            }
        }
    }
}

// Extension for Font to provide direct access to custom fonts
public extension Font {
    static func bebasNeueBold(size: CGFloat) -> Font {
        return Font.custom("BebasNeue-Bold", size: size)
    }
    
    static func montserratRegular(size: CGFloat) -> Font {
        return Font.custom("Montserrat-Regular", size: size)
    }
    
    static func montserratBold(size: CGFloat) -> Font {
        return Font.custom("Montserrat-Bold", size: size)
    }
    
    static func montserratSemiBold(size: CGFloat) -> Font {
        return Font.custom("Montserrat-SemiBold", size: size)
    }
    
    static func robotoMonoBold(size: CGFloat) -> Font {
        return Font.custom("RobotoMono-Bold", size: size)
    }
    
    static func robotoMonoMedium(size: CGFloat) -> Font {
        return Font.custom("RobotoMono-Medium", size: size)
    }
}

public struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

extension View {
    public func withShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    public func cardStyle() -> some View {
        self
            .background(AppTheme.GeneratedColors.cardBackground)
            .cornerRadius(AppTheme.GeneratedRadius.card)
            .withShadow(AppTheme.GeneratedShadows.small)
    }
    
    public func panelStyle() -> some View {
        self
            .background(AppTheme.GeneratedColors.background)
            .cornerRadius(AppTheme.GeneratedRadius.panel)
            .withShadow(AppTheme.GeneratedShadows.medium)
    }
} 