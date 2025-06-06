// Generated by Style Dictionary
import SwiftUI

public extension AppTheme {
  enum GeneratedColors {
    public static let cream = Color("Cream", bundle: .module)
    public static let creamDark = Color("CreamDark", bundle: .module)
    public static let deepOps = Color("DeepOps", bundle: .module)
    public static let brassGold = Color("BrassGold", bundle: .module)
    public static let armyTan = Color("ArmyTan", bundle: .module)
    public static let oliveMist = Color("OliveMist", bundle: .module)
    public static let commandBlack = Color("CommandBlack", bundle: .module)
    public static let tacticalGray = Color("TacticalGray", bundle: .module)
    public static let success = Color("Success", bundle: .module)
    public static let warning = Color("Warning", bundle: .module)
    public static let error = Color("Error", bundle: .module)
    public static let info = Color("Info", bundle: .module)

    // Semantic colours
    public static let primary = Color("Primary", bundle: .module)
    public static let secondary = Color("Secondary", bundle: .module)
    public static let accent = Color("Accent", bundle: .module)
    public static let background = Color("Background", bundle: .module)
    public static let cardBackground = Color("CardBackground", bundle: .module)
    public static let textPrimary = Color("TextPrimary", bundle: .module)
    public static let textSecondary = Color("TextSecondary", bundle: .module)
    public static let textTertiary = Color("TextTertiary", bundle: .module)
    
    // Additional semantic colors
    public static let textOnPrimary = cream // Text on primary color (usually white/cream)
    
    // New color tokens for elements on dark backgrounds
    public static let textPrimaryOnDark = Color.white // Primary text on dark backgrounds
    public static let textSecondaryOnDark = Color.gray // Secondary text on dark backgrounds
    public static let backgroundOverlay = Color.black.opacity(0.7) // Semi-transparent overlay background
  }

  enum GeneratedTypography {
    public static let heading1: CGFloat = 40
    public static let heading2: CGFloat = 32
    public static let heading3: CGFloat = 26
    public static let heading4: CGFloat = 22
    public static let body: CGFloat = 16
    public static let small: CGFloat = 14
    public static let tiny: CGFloat = 12

    // Fallback handling
    private static func fontWithFallback(_ primaryFont: String, size: CGFloat, weight: Font.Weight? = nil) -> Font {
      let font = Font.custom(primaryFont, fixedSize: size)
      let _ = Font.system(size: size, weight: weight ?? .regular)
      
      // In SwiftUI, we can't directly check if a font exists
      // This won't actually catch font failures, but it's a placeholder for more advanced handling
      return font
    }

    public static func heading(size: CGFloat? = nil) -> Font {
      return fontWithFallback("Futura", size: size ?? heading1, weight: .bold)
    }

    public static func body(size: CGFloat? = nil) -> Font {
      return fontWithFallback("Futura", size: size ?? body)
    }

    public static func bodyBold(size: CGFloat? = nil) -> Font {
      return fontWithFallback("Futura", size: size ?? body, weight: .bold)
    }

    public static func bodySemibold(size: CGFloat? = nil) -> Font {
      return fontWithFallback("Futura", size: size ?? body, weight: .medium)
    }

    public static func mono(size: CGFloat? = nil) -> Font {
      return Font.system(size: size ?? body, design: .monospaced)
    }
    
    // Additional font styles
    public static func caption(size: CGFloat? = nil) -> Font {
      return body(size: size ?? tiny)
    }
    
    public static func title(size: CGFloat? = nil) -> Font {
      return heading(size: size ?? heading3)
    }
    
    public static func subheading(size: CGFloat? = nil) -> Font {
      return bodySemibold(size: size ?? body)
    }
  }

  enum GeneratedRadius {
    public static let card: CGFloat = 12
    public static let panel: CGFloat = 16
    public static let button: CGFloat = 8
    public static let input: CGFloat = 8
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 12
    public static let full: CGFloat = 9999 // For pill-shaped elements
    public static let badge: CGFloat = 4 // For badge elements
  }

  enum GeneratedSpacing {
    public static let section: CGFloat = 32
    public static let cardGap: CGFloat = 16
    public static let contentPadding: CGFloat = 16
    public static let itemSpacing: CGFloat = 8
    public static let extraSmall: CGFloat = 4 // Smallest spacing unit
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
  }

  enum GeneratedShadows {
    public static let small = Shadow(
      color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2
    )

    public static let medium = Shadow(
      color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4
    )

    public static let large = Shadow(
      color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8
    )

  }

  enum GeneratedBorderWidth {
  }

}