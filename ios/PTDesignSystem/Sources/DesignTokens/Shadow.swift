import SwiftUI

// Shadow tokens for the design system
public enum Shadow {
    // Web shadows converted to SwiftUI format
    public static let sm = DSShadow(
        color: SwiftUI.Color.black.opacity(0.05),
        radius: 1,
        x: 0,
        y: 1
    )
    
    public static let md = DSShadow(
        color: SwiftUI.Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    public static let lg = DSShadow(
        color: SwiftUI.Color.black.opacity(0.1),
        radius: 10,
        x: 0,
        y: 4
    )
    
    public static let xl = DSShadow(
        color: SwiftUI.Color.black.opacity(0.1),
        radius: 20,
        x: 0,
        y: 10
    )
    
    public static let xxl = DSShadow(
        color: SwiftUI.Color.black.opacity(0.25),
        radius: 25,
        x: 0,
        y: 12
    )
    
    public static let inner = DSShadow(
        color: SwiftUI.Color.black.opacity(0.06),
        radius: 2,
        x: 0,
        y: 2
    )
    
    public static let card = DSShadow(
        color: SwiftUI.Color.black.opacity(0.06),
        radius: 1,
        x: 0,
        y: 1
    )
    
    public static let button = DSShadow(
        color: SwiftUI.Color.black.opacity(0.05),
        radius: 1,
        x: 0,
        y: 1
    )
    
    public static let none = DSShadow(
        color: SwiftUI.Color.clear,
        radius: 0,
        x: 0,
        y: 0
    )
    
    // Legacy aliases for backward compatibility
    public static let small = sm
    public static let medium = md
    public static let large = lg
} 