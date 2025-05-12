import SwiftUI

// These are core types used by the design system to avoid namespace collisions with SwiftUI
public struct DSColor {
    public let value: Color
    
    public init(_ value: Color) {
        self.value = value
    }
}

public struct DSFont {
    public let value: Font
    
    public init(_ value: Font) {
        self.value = value
    }
}

public struct DSRadius {
    public let value: CGFloat
    
    public init(_ value: CGFloat) {
        self.value = value
    }
}

public struct DSShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    // Convenience initializer with fewer parameter labels
    public init(_ color: Color, _ radius: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        self.init(color: color, radius: radius, x: x, y: y)
    }
}

// Extension to apply shadow to a view
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