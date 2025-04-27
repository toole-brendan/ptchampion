import SwiftUI
import Foundation
import Combine
import UIKit

/* 
This file provides a common way to import shared types across the app.
Import this file in any Swift file that needs access to shared constants,
styles, or other common definitions.

IMPORTANT: This file should be imported by all Swift files in the project
that need access to the app's shared types.
*/

// This file ensures all necessary types are available throughout the app
// Import this file in any Swift file that needs access to shared types like AppConstants

// Re-export the Theme namespace so it's available when importing this file
@_exported import struct Theme
@_exported import struct AppConstants 

// Create a simple constant definition to fix AppConstants issues
public enum AppConstants {
    // Global padding used throughout the app
    public static let globalPadding: CGFloat = 16
    
    // Spacing between cards in stack views
    public static let cardGap: CGFloat = 12
}

// Add color extension for tacticalCream
extension Color {
    public static let tacticalCream = Color(hex: "#F4F1E6")
    
    // Helper to initialize Color from HEX string
    public init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
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

// Add style extensions
extension View {
    public func headingStyle() -> some View {
        self.font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    public func subheadingStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.secondary)
    }
    
    public func labelStyle() -> some View {
        self.font(.caption)
            .foregroundColor(.secondary)
    }
    
    public func statsNumberStyle() -> some View {
        self.font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.primary)
    }
    
    public func cardStyle() -> some View {
        self.padding()
            .background(Color.tacticalCream)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// Add button style
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
} 