import SwiftUI

// These are core types used by the design system to avoid namespace collisions with SwiftUI
// (Removed DSColor, DSFont, DSRadius to avoid duplicate declarations)

// Core shadow type used by the design system
public struct DSShadow {
    public let color: SwiftUI.Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: SwiftUI.Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    // Convenience initializer with positional parameters
    public init(_ color: SwiftUI.Color, _ radius: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        self.init(color: color, radius: radius, x: x, y: y)
    }
}

// Extension to apply a DSShadow to any SwiftUI view
public extension View {
    func withDSShadow(_ shadow: DSShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
} 