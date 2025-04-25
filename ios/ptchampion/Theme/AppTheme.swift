import SwiftUI

enum AppTheme {
    enum Colors {
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let accent = Color("Accent")
        static let background = Color("Background")
        static let cardBackground = Color("CardBackground")
        
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")
        static let info = Color("Info")
        
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
    }
    
    enum Shadows {
        static let small = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func withShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
} 