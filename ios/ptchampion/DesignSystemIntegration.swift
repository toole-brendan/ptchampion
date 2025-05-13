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
                    .foregroundColor(ThemeColor.textPrimary)
                
                // Colors section
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Colors")
                        .heading3()
                        .foregroundColor(ThemeColor.textPrimary)
                    
                    Text("Base Colors")
                        .subheading()
                        .foregroundColor(ThemeColor.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Primary", color: ThemeColor.primary)
                        colorSwatch("Secondary", color: ThemeColor.secondary)
                        colorSwatch("Accent", color: ThemeColor.accent)
                        colorSwatch("Background", color: ThemeColor.background)
                        colorSwatch("Card", color: ThemeColor.cardBackground)
                        colorSwatch("Brass Gold", color: ThemeColor.brassGold)
                    }
                    
                    Text("Text Colors")
                        .subheading()
                        .foregroundColor(ThemeColor.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Text Primary", color: ThemeColor.textPrimary)
                        colorSwatch("Text Secondary", color: ThemeColor.textSecondary)
                        colorSwatch("Text Tertiary", color: ThemeColor.textTertiary)
                    }
                    
                    Text("Status Colors")
                        .subheading()
                        .foregroundColor(ThemeColor.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.small) {
                        colorSwatch("Success", color: ThemeColor.success)
                        colorSwatch("Error", color: ThemeColor.error)
                        colorSwatch("Warning", color: ThemeColor.warning)
                        colorSwatch("Info", color: ThemeColor.info)
                    }
                }
                .padding()
                .background(ThemeColor.cardBackground)
                .cornerRadius(CornerRadius.card)
                
                // Typography section
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Typography")
                        .heading3()
                        .foregroundColor(ThemeColor.textPrimary)
                    
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
                .background(ThemeColor.cardBackground)
                .cornerRadius(CornerRadius.card)
                
                // Component Examples
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Component Examples")
                        .heading3()
                        .foregroundColor(ThemeColor.textPrimary)
                    
                    // Buttons
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Buttons")
                            .subheading()
                            .foregroundColor(ThemeColor.textSecondary)
                        
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
                            .foregroundColor(ThemeColor.textSecondary)
                        
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
                            .foregroundColor(ThemeColor.textSecondary)
                        
                        PTTextField(
                            text: .constant("Example text"),
                            label: "Text Field",
                            placeholder: "Enter text",
                            icon: Image(systemName: "text.cursor")
                        )
                    }
                }
                .padding()
                .background(ThemeColor.cardBackground)
                .cornerRadius(CornerRadius.card)
            }
            .padding()
        }
        .background(ThemeColor.background)
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
                .foregroundColor(ThemeColor.textSecondary)
        }
    }
    
    private func typographySample(_ name: String, font: Font, size: String) -> some View {
        HStack {
            Text(name)
                .font(font)
                .foregroundColor(ThemeColor.textPrimary)
            
            Spacer()
            
            Text(size)
                .caption()
                .foregroundColor(ThemeColor.textTertiary)
        }
    }
}

#Preview {
    DesignSystemDemo()
} 