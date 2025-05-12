import SwiftUI

// WebUI-aligned extension to AppTheme
public extension AppTheme {

    // Color tokens matching web UI
    enum Color {
        // Brand palette
        public static let brand50 = Color(hex: "f0f9ff")
        public static let brand100 = Color(hex: "e0f2fe")
        public static let brand200 = Color(hex: "bae6fd")
        public static let brand300 = Color(hex: "7dd3fc")
        public static let brand400 = Color(hex: "38bdf8")
        public static let brand500 = Color(hex: "0ea5e9")
        public static let brand600 = Color(hex: "0284c7")
        public static let brand700 = Color(hex: "0369a1")
        public static let brand800 = Color(hex: "075985")
        public static let brand900 = Color(hex: "0c4a6e")
        public static let brand950 = Color(hex: "082f49")
        
        // Success palette
        public static let success50 = Color(hex: "f0fdf4")
        public static let success100 = Color(hex: "dcfce7")
        public static let success200 = Color(hex: "bbf7d0")
        public static let success300 = Color(hex: "86efac")
        public static let success400 = Color(hex: "4ade80")
        public static let success500 = Color(hex: "22c55e")
        public static let success600 = Color(hex: "16a34a")
        public static let success700 = Color(hex: "15803d")
        public static let success800 = Color(hex: "166534")
        public static let success900 = Color(hex: "14532d")
        public static let success950 = Color(hex: "052e16")
        
        // Warning palette
        public static let warning50 = Color(hex: "fffbeb")
        public static let warning100 = Color(hex: "fef3c7")
        public static let warning200 = Color(hex: "fde68a")
        public static let warning300 = Color(hex: "fcd34d")
        public static let warning400 = Color(hex: "fbbf24")
        public static let warning500 = Color(hex: "f59e0b")
        public static let warning600 = Color(hex: "d97706")
        public static let warning700 = Color(hex: "b45309")
        public static let warning800 = Color(hex: "92400e")
        public static let warning900 = Color(hex: "78350f")
        public static let warning950 = Color(hex: "451a03")
        
        // Error palette
        public static let error50 = Color(hex: "fef2f2")
        public static let error100 = Color(hex: "fee2e2")
        public static let error200 = Color(hex: "fecaca")
        public static let error300 = Color(hex: "fca5a5")
        public static let error400 = Color(hex: "f87171")
        public static let error500 = Color(hex: "ef4444")
        public static let error600 = Color(hex: "dc2626")
        public static let error700 = Color(hex: "b91c1c")
        public static let error800 = Color(hex: "991b1b")
        public static let error900 = Color(hex: "7f1d1d")
        public static let error950 = Color(hex: "450a0a")
        
        // Gray palette
        public static let gray50 = Color(hex: "f9fafb")
        public static let gray100 = Color(hex: "f3f4f6")
        public static let gray200 = Color(hex: "e5e7eb")
        public static let gray300 = Color(hex: "d1d5db")
        public static let gray400 = Color(hex: "9ca3af")
        public static let gray500 = Color(hex: "6b7280")
        public static let gray600 = Color(hex: "4b5563")
        public static let gray700 = Color(hex: "374151")
        public static let gray800 = Color(hex: "1f2937")
        public static let gray900 = Color(hex: "111827")
        public static let gray950 = Color(hex: "030712")
        
        // Semantic colors
        public static let background = Color(hex: "ffffff")
        public static let backgroundSubtle = Color(hex: "f9fafb")
        public static let surface = Color(hex: "ffffff")
        public static let surfaceRaised = Color(hex: "f9fafb")
        public static let borderDefault = Color(hex: "e5e7eb")
        public static let borderStrong = Color(hex: "d1d5db")
        public static let textDefault = Color(hex: "111827")
        public static let textSubtle = Color(hex: "6b7280")
        public static let textDisabled = Color(hex: "9ca3af")
        public static let textInverted = Color(hex: "ffffff")
        
        // Legacy aliases for backward compatibility
        public static let primary = brand500
        public static let secondary = brand300
        public static let accent = brand700
        public static let cardBackground = surface
        public static let textPrimary = textDefault
        public static let textSecondary = textSubtle
        public static let textTertiary = textDisabled
    }
    
    // Typography tokens matching web UI
    enum Typography {
        // Font sizes in points (converted from rem)
        public static let xs: CGFloat = 12
        public static let sm: CGFloat = 14
        public static let base: CGFloat = 16
        public static let lg: CGFloat = 18
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 30
        public static let xxxxl: CGFloat = 36
        public static let xxxxxl: CGFloat = 48
        public static let xxxxxxl: CGFloat = 60
        
        // Typography styles matching web
        public static let h1 = Font.futuraBold(size: 36)
        public static let h2 = Font.futuraBold(size: 30)
        public static let h3 = Font.futuraDemi(size: 24)
        public static let h4 = Font.futuraDemi(size: 20)
        public static let h5 = Font.futuraDemi(size: 18)
        public static let h6 = Font.futuraDemi(size: 16)
        public static let bodyLarge = Font.futuraBook(size: 18)
        public static let body = Font.futuraBook(size: 16)
        public static let bodySmall = Font.futuraBook(size: 14)
        public static let caption = Font.futuraBook(size: 12)
        public static let label = Font.futuraMedium(size: 14)
        public static let button = Font.futuraDemi(size: 14)
        public static let monospace = Font.webMonospace()
        
        // Legacy aliases for backward compatibility
        public static let heading1 = h1
        public static let heading2 = h2
        public static let heading3 = h3
        public static let heading4 = h4
        public static let heading = h3  // Default heading size
        public static let small = bodySmall
        public static let tiny = caption
    }
    
    // Radius tokens matching web UI
    enum Radius {
        public static let none: CGFloat = 0
        public static let xs: CGFloat = 2
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 6
        public static let lg: CGFloat = 8
        public static let xl: CGFloat = 12
        public static let xxl: CGFloat = 16
        public static let xxxl: CGFloat = 24
        public static let full: CGFloat = 9999
        
        // Legacy aliases for backward compatibility
        public static let card = xl
        public static let panel = xxl
        public static let button = lg
        public static let input = lg
        public static let small = xs
        public static let medium = md
        public static let large = xl
        public static let badge = xs
    }
    
    // Shadow tokens matching web UI
    enum Shadow {
        // Web shadows converted to SwiftUI format
        public static let sm = Shadow(
            color: Color.black.opacity(0.05),
            radius: 1,
            x: 0,
            y: 1
        )
        
        public static let md = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        public static let lg = Shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
        
        public static let xl = Shadow(
            color: Color.black.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
        
        public static let xxl = Shadow(
            color: Color.black.opacity(0.25),
            radius: 25,
            x: 0,
            y: 12
        )
        
        public static let inner = Shadow(
            color: Color.black.opacity(0.06),
            radius: 2,
            x: 0,
            y: 2
        )
        
        public static let card = Shadow(
            color: Color.black.opacity(0.06),
            radius: 1,
            x: 0,
            y: 1
        )
        
        public static let button = Shadow(
            color: Color.black.opacity(0.05),
            radius: 1,
            x: 0,
            y: 1
        )
        
        public static let none = Shadow(
            color: Color.clear,
            radius: 0,
            x: 0,
            y: 0
        )
        
        // Legacy aliases for backward compatibility
        public static let small = sm
        public static let medium = md
        public static let large = lg
    }
    
    // Spacing tokens matching web UI
    enum Spacing {
        public static let space0: CGFloat = 0
        public static let space1: CGFloat = 4      // 0.25rem
        public static let space2: CGFloat = 8      // 0.5rem
        public static let space3: CGFloat = 12     // 0.75rem
        public static let space4: CGFloat = 16     // 1rem
        public static let space5: CGFloat = 20     // 1.25rem
        public static let space6: CGFloat = 24     // 1.5rem
        public static let space8: CGFloat = 32     // 2rem
        public static let space10: CGFloat = 40    // 2.5rem
        public static let space12: CGFloat = 48    // 3rem
        public static let space16: CGFloat = 64    // 4rem
        public static let space20: CGFloat = 80    // 5rem
        public static let space24: CGFloat = 96    // 6rem
        public static let space32: CGFloat = 128   // 8rem
        public static let space40: CGFloat = 160   // 10rem
        public static let space48: CGFloat = 192   // 12rem
        public static let space56: CGFloat = 224   // 14rem
        public static let space64: CGFloat = 256   // 16rem
        
        // Legacy aliases for backward compatibility
        public static let section = space8
        public static let cardGap = space4
        public static let contentPadding = space4
        public static let itemSpacing = space2
        public static let extraSmall = space1
        public static let small = space2
        public static let medium = space4
        public static let large = space6
    }
}

// Helper extension to create colors from hex strings
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
}

// Convenience extensions for applying web styles
public extension View {
    // Card styling with web style
    func webCardStyle(
        shadowStyle: AppTheme.Shadow = AppTheme.Shadow.card,
        cornerRadius: CGFloat = AppTheme.Radius.lg
    ) -> some View {
        self
            .background(AppTheme.Color.surface)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
    
    // Add standard spacing around content using web spacing
    func webSpacing(
        horizontal: CGFloat = AppTheme.Spacing.space4,
        vertical: CGFloat = AppTheme.Spacing.space4
    ) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }
} 