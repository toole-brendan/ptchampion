import SwiftUI

// This file contains common styles and modifiers used throughout the app
// We're keeping this simple and independent to avoid import conflicts

extension View {
    func headingStyle() -> some View {
        self.font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    func subheadingStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.secondary)
    }
    
    func labelStyle() -> some View {
        self.font(.caption)
            .foregroundColor(.secondary)
    }
    
    func statsNumberStyle() -> some View {
        self.font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.primary)
    }
    
    func cardStyle() -> some View {
        self.padding()
            .background(Color(red: 0.957, green: 0.945, blue: 0.902))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
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