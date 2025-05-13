import SwiftUI
import PTDesignSystem

/// This file serves as the integration point between the main app and the design system package.
/// It demonstrates how to use the design system components and tokens.

// Example view demonstrating the design system usage
struct DesignSystemDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.section) {
                Text("PT Champion Design System")
                    .heading1()
                    .foregroundColor(Color.textPrimary)
                
                // Colors section
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Colors")
                        .heading3()
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Base Colors")
                        .subheading()
                        .foregroundColor(Color.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Primary", color: Color.primary)
                        colorSwatch("Secondary", color: Color.secondary)
                        colorSwatch("Accent", color: Color.accent)
                        colorSwatch("Background", color: Color.background)
                        colorSwatch("Card", color: Color.cardBackground)
                        colorSwatch("Brass Gold", color: Color.brassGold)
                    }
                    
                    Text("Text Colors")
                        .subheading()
                        .foregroundColor(Color.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Text Primary", color: Color.textPrimary)
                        colorSwatch("Text Secondary", color: Color.textSecondary)
                        colorSwatch("Text Tertiary", color: Color.textTertiary)
                    }
                    
                    Text("Status Colors")
                        .subheading()
                        .foregroundColor(Color.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Success", color: Color.success)
                        colorSwatch("Error", color: Color.error)
                        colorSwatch("Warning", color: Color.warning)
                        colorSwatch("Info", color: Color.info)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
                
                // Typography section
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Typography")
                        .heading3()
                        .foregroundColor(Color.textPrimary)
                    
                    Group {
                        typographySample("Heading 1", 
                                        font: .heading1(),
                                        size: "24pt")
                        
                        typographySample("Heading 2", 
                                        font: .heading2(),
                                        size: "20pt")
                        
                        typographySample("Heading 3", 
                                        font: .heading3(),
                                        size: "18pt")
                        
                        typographySample("Heading 4", 
                                        font: .heading4(),
                                        size: "16pt")
                        
                        typographySample("Body", 
                                        font: .body(),
                                        size: "14pt")
                        
                        typographySample("Body Bold", 
                                        font: .bodyBold(),
                                        size: "14pt")
                        
                        typographySample("Small", 
                                        font: .small(),
                                        size: "12pt")
                        
                        typographySample("Tiny", 
                                        font: .caption(),
                                        size: "10pt")
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
                
                // Component Examples
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Component Examples")
                        .heading3()
                        .foregroundColor(Color.textPrimary)
                    
                    // Buttons
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Buttons")
                            .subheading()
                            .foregroundColor(Color.textSecondary)
                        
                        HStack {
                            PTButton("Primary", action: {})
                            PTButton("Secondary", action: {}, variant: .secondary)
                        }
                        
                        HStack {
                            PTButton("Outline", action: {}, variant: .outline)
                            PTButton("Ghost", action: {}, variant: .ghost)
                        }
                    }
                    
                    // Cards
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Cards")
                            .subheading()
                            .foregroundColor(Color.textSecondary)
                        
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("Card Title")
                                .subheading()
                            Text("This is a sample card component using the design system tokens for styling.")
                                .body()
                        }
                        .padding()
                        .card()
                    }
                    
                    // Text Fields
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Text Fields")
                            .subheading()
                            .foregroundColor(Color.textSecondary)
                        
                        PTTextField(
                            text: .constant("Example text"),
                            label: "Text Field",
                            placeholder: "Enter text",
                            icon: Image(systemName: "text.cursor")
                        )
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.card)
            }
            .padding()
        }
        .background(Color.background)
        .container()
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 70, height: 70)
                .cornerRadius(CornerRadius.small)
            
            Text(name)
                .caption()
                .multilineTextAlignment(.center)
                .foregroundColor(Color.textSecondary)
        }
    }
    
    private func typographySample(_ name: String, font: Font, size: String) -> some View {
        HStack {
            Text(name)
                .font(font)
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Text(size)
                .caption()
                .foregroundColor(Color.textTertiary)
        }
    }
}

#Preview {
    DesignSystemDemo()
} 