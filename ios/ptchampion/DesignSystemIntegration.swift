import SwiftUI
import PTDesignSystem

/// This file serves as the integration point between the main app and the design system package.
/// It demonstrates how to use the design system components and tokens.

// Example view demonstrating the design system usage
struct DesignSystemDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.GeneratedSpacing.section) {
                Text("PT Champion Design System")
                    .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                
                // Colors section
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Text("Colors")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Text("Base Colors")
                        .font(AppTheme.GeneratedTypography.subheading())
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.GeneratedSpacing.small) {
                        colorSwatch("Primary", color: AppTheme.GeneratedColors.primary)
                        colorSwatch("Secondary", color: AppTheme.GeneratedColors.secondary)
                        colorSwatch("Accent", color: AppTheme.GeneratedColors.accent)
                        colorSwatch("Background", color: AppTheme.GeneratedColors.background)
                        colorSwatch("Card", color: AppTheme.GeneratedColors.cardBackground)
                        colorSwatch("Brass Gold", color: AppTheme.GeneratedColors.brassGold)
                    }
                    
                    Text("Text Colors")
                        .font(AppTheme.GeneratedTypography.subheading())
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.GeneratedSpacing.small) {
                        colorSwatch("Text Primary", color: AppTheme.GeneratedColors.textPrimary)
                        colorSwatch("Text Secondary", color: AppTheme.GeneratedColors.textSecondary)
                        colorSwatch("Text Tertiary", color: AppTheme.GeneratedColors.textTertiary)
                    }
                    
                    Text("Status Colors")
                        .font(AppTheme.GeneratedTypography.subheading())
                        .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.GeneratedSpacing.small) {
                        colorSwatch("Success", color: AppTheme.GeneratedColors.success)
                        colorSwatch("Error", color: AppTheme.GeneratedColors.error)
                        colorSwatch("Warning", color: AppTheme.GeneratedColors.warning)
                        colorSwatch("Info", color: AppTheme.GeneratedColors.info)
                    }
                }
                .padding()
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.card)
                
                // Typography section
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Text("Typography")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    Group {
                        typographySample("Heading 1", 
                                        font: AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading1),
                                        size: "\(Int(AppTheme.GeneratedTypography.heading1))pt")
                        
                        typographySample("Heading 2", 
                                        font: AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading2),
                                        size: "\(Int(AppTheme.GeneratedTypography.heading2))pt")
                        
                        typographySample("Heading 3", 
                                        font: AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3),
                                        size: "\(Int(AppTheme.GeneratedTypography.heading3))pt")
                        
                        typographySample("Heading 4", 
                                        font: AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading4),
                                        size: "\(Int(AppTheme.GeneratedTypography.heading4))pt")
                        
                        typographySample("Body", 
                                        font: AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body),
                                        size: "\(Int(AppTheme.GeneratedTypography.body))pt")
                        
                        typographySample("Body Bold", 
                                        font: AppTheme.GeneratedTypography.bodyBold(size: AppTheme.GeneratedTypography.body),
                                        size: "\(Int(AppTheme.GeneratedTypography.body))pt")
                        
                        typographySample("Small", 
                                        font: AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.small),
                                        size: "\(Int(AppTheme.GeneratedTypography.small))pt")
                        
                        typographySample("Tiny", 
                                        font: AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.tiny),
                                        size: "\(Int(AppTheme.GeneratedTypography.tiny))pt")
                    }
                }
                .padding()
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.card)
                
                // Component Examples
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.medium) {
                    Text("Component Examples")
                        .font(AppTheme.GeneratedTypography.heading(size: AppTheme.GeneratedTypography.heading3))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    // Buttons
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        Text("Buttons")
                            .font(AppTheme.GeneratedTypography.subheading())
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        HStack {
                            PTButton(title: "Primary", action: {})
                            PTButton(title: "Secondary", action: {}, variant: .secondary)
                        }
                        
                        HStack {
                            PTButton(title: "Outline", action: {}, variant: .outline)
                            PTButton(title: "Ghost", action: {}, variant: .ghost)
                        }
                    }
                    
                    // Cards
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        Text("Cards")
                            .font(AppTheme.GeneratedTypography.subheading())
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        PTCard {
                            VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                                Text("Card Title")
                                    .font(AppTheme.GeneratedTypography.subheading())
                                Text("This is a sample card component using the design system tokens for styling.")
                                    .font(AppTheme.GeneratedTypography.body())
                            }
                            .padding()
                        }
                    }
                    
                    // Text Fields
                    VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.small) {
                        Text("Text Fields")
                            .font(AppTheme.GeneratedTypography.subheading())
                            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        
                        PTTextField(
                            text: .constant("Example text"),
                            label: "Text Field",
                            placeholder: "Enter text",
                            icon: Image(systemName: "text.cursor")
                        )
                    }
                }
                .padding()
                .background(AppTheme.GeneratedColors.cardBackground)
                .cornerRadius(AppTheme.GeneratedRadius.card)
            }
            .padding()
        }
        .background(AppTheme.GeneratedColors.background)
    }
    
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 70, height: 70)
                .cornerRadius(AppTheme.GeneratedRadius.small)
            
            Text(name)
                .font(AppTheme.GeneratedTypography.caption())
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
        }
    }
    
    private func typographySample(_ name: String, font: Font, size: String) -> some View {
        HStack {
            Text(name)
                .font(font)
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
            
            Spacer()
            
            Text(size)
                .font(AppTheme.GeneratedTypography.caption())
                .foregroundColor(AppTheme.GeneratedColors.textTertiary)
        }
    }
}

#Preview {
    DesignSystemDemo()
} 