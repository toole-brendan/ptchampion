import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Base Colors
    
    // Base PT Champion colors from web
    static let cream = Color(hex: "F4F1E6")
    static let creamDark = Color(hex: "EDE9DB")
    static let creamLight = Color(hex: "FAF8F1")
    static let deepOps = Color(hex: "1E241E")
    static let brassGold = Color(hex: "BFA24D")
    static let armyTan = Color(hex: "E0D4A6")
    static let oliveMist = Color(hex: "C9CCA6")
    static let commandBlack = Color(hex: "1E1E1E")
    static let tacticalGray = Color(hex: "4E5A48")
    static let hunterGreen = Color(hex: "355E3B")
    static let border = Color(hex: "E2D9C2")
    
    // MARK: - Semantic Colors
    
    // Light mode semantic mapping (direct)
    static var background: Color {
        ThemeColor.cream
    }
    
    static var foreground: Color {
        ThemeColor.commandBlack
    }
    
    static var primary: Color {
        ThemeColor.brassGold
    }
    
    static var primaryForeground: Color {
        ThemeColor.deepOps
    }
    
    static var secondary: Color {
        ThemeColor.armyTan
    }
    
    static var secondaryForeground: Color {
        ThemeColor.commandBlack
    }
    
    static var muted: Color {
        ThemeColor.oliveMist
    }
    
    static var mutedForeground: Color {
        ThemeColor.tacticalGray
    }
    
    static var accent: Color {
        ThemeColor.brassGold
    }
    
    static var accentForeground: Color {
        ThemeColor.deepOps
    }
    
    static var card: Color {
        ThemeColor.cream
    }
    
    static var cardForeground: Color {
        ThemeColor.commandBlack
    }
    
    static var popover: Color {
        ThemeColor.cream
    }
    
    static var popoverForeground: Color {
        ThemeColor.commandBlack
    }
    
    // MARK: - Status Colors
    
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FF9800")
    static let error = Color(hex: "F44336")
    static let info = Color(hex: "2196F3")
    
    static var destructive: Color {
        ThemeColor.error
    }
    
    static var destructiveForeground: Color {
        ThemeColor.white
    }
    
    static var ring: Color {
        ThemeColor.brassGold
    }
}

// MARK: - Shadow Values

struct AppShadow {
    static let small = Shadow(color: ThemeColor.black.opacity(0.04), radius: 2, x: 0, y: 1)
    static let medium = Shadow(color: ThemeColor.black.opacity(0.1), radius: 6, x: 0, y: 4)
    static let large = Shadow(color: ThemeColor.black.opacity(0.1), radius: 15, x: 0, y: 10)
    static let card = Shadow(color: ThemeColor.black.opacity(0.06), radius: 4, x: 0, y: 2)
    static let cardHover = Shadow(color: ThemeColor.black.opacity(0.08), radius: 8, x: 0, y: 4)
} 