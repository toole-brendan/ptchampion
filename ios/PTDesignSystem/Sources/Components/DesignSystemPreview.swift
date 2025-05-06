import SwiftUI
import DesignTokens

public struct DesignSystemPreview: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var textFieldText = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Design System Preview")
                    .font(.title)
                
                colorsSection
                
                typographySection
                
                buttonsSection
                
                textFieldsSection
                
                separatorsSection
                
                cardsSection
                
                themeToggle
            }
            .padding()
        }
        .preferredColorScheme(themeManager.effectiveColorScheme)
        .background(AppTheme.GeneratedColors.background)
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Colors", style: .heading)
            
            HStack(spacing: 8) {
                colorSwatch(color: AppTheme.GeneratedColors.primary, name: "Primary")
                colorSwatch(color: AppTheme.GeneratedColors.secondary, name: "Secondary")
                colorSwatch(color: AppTheme.GeneratedColors.error, name: "Error")
            }
            
            HStack(spacing: 8) {
                colorSwatch(color: AppTheme.GeneratedColors.background, name: "Background")
                colorSwatch(color: AppTheme.GeneratedColors.cardBackground, name: "Card")
                colorSwatch(color: AppTheme.GeneratedColors.textPrimary, name: "Text")
            }
        }
    }
    
    private func colorSwatch(color: Color, name: String) -> some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            Text(name)
                .font(.caption)
                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
        }
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Typography", style: .heading)
            
            PTLabel("Heading Text", style: .heading)
            PTLabel("Subheading Text", style: .subheading)
            PTLabel("Body Text", style: .body)
            PTLabel("Caption Text", style: .caption)
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Buttons", style: .heading)
            
            PTButton("Primary Button") {
                print("Primary button tapped")
            }
            
            PTButton("Secondary Button", style: .secondary) {
                print("Secondary button tapped")
            }
            
            PTButton("Destructive Button", style: .destructive) {
                print("Destructive button tapped")
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Text Fields", style: .heading)
            
            PTTextField("Email", text: $textFieldText)
            
            PTTextField("Password", text: .constant("password123"), isSecure: true)
        }
    }
    
    private var separatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Separators", style: .heading)
            
            PTSeparator()
            
            HStack(spacing: 16) {
                Text("Left content")
                PTSeparator(orientation: .vertical, thickness: 2)
                Text("Right content")
            }
            .frame(height: 50)
            
            PTSeparator(thickness: 3, color: AppTheme.GeneratedColors.primary)
        }
    }
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PTLabel("Cards", style: .heading)
            
            PTCard {
                VStack(alignment: .leading, spacing: 8) {
                    PTLabel("Card Title", style: .subheading)
                    
                    PTLabel("This is a card component that uses the design tokens for styling.", style: .body)
                    
                    PTSeparator()
                    
                    HStack {
                        PTButton("Action", style: .secondary) {
                            print("Card action tapped")
                        }
                        .frame(maxWidth: 100)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var themeToggle: some View {
        Button("Cycle Theme: \(themeManager.currentThemeOption.rawValue)") {
            let allCases = AppThemeOption.allCases
            if let currentIndex = allCases.firstIndex(of: themeManager.currentThemeOption) {
                let nextIndex = (currentIndex + 1) % allCases.count
                themeManager.currentThemeOption = allCases[nextIndex]
            } else {
                themeManager.currentThemeOption = .system
            }
        }
        .padding()
        .background(AppTheme.GeneratedColors.secondary)
        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
        .cornerRadius(8)
    }
}

struct DesignSystemPreview_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            DesignSystemPreview()
                .preferredColorScheme(.light)
            
            DesignSystemPreview()
                .preferredColorScheme(.dark)
        }
    }
} 