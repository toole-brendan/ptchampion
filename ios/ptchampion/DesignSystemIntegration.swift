import SwiftUI

/// This file serves as the integration point between the main app and the design system package.
/// It re-exports the necessary types and provides convenience access to the design system.

// Example view demonstrating the design system usage
struct DesignSystemDemo: View {
    var body: some View {
        VStack {
            Text("Design System Components")
                .font(.largeTitle)
            
            Spacer()
                .frame(height: 30)
            
            // Colors section
            VStack(alignment: .leading) {
                Text("Colors").font(.headline)
                
                HStack {
                    colorSwatch("Primary", color: AppTheme.GeneratedColors.primary)
                    colorSwatch("Secondary", color: AppTheme.GeneratedColors.secondary)
                    colorSwatch("Background", color: AppTheme.GeneratedColors.background)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            Text(name)
                .font(.caption)
        }
    }
}

#Preview {
    DesignSystemDemo()
} 