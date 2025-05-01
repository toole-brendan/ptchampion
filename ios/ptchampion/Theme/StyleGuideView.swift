import SwiftUI

struct StyleGuideView: View {
    @State private var textField1 = ""
    @State private var textField2 = ""
    @State private var passwordField = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                headerSection
                colorsSection
                typographySection
                buttonsSection
                textFieldsSection
                cardsSection
            }
            .padding(.horizontal, AppTheme.Spacing.contentPadding)
            .padding(.vertical, 30)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Style Guide")
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PT Champion Design System")
                .font(AppTheme.Typography.heading())
                .foregroundColor(AppTheme.Colors.deepOps)
            
            Text("Visual reference for the design tokens and components")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Colors")
            
            VStack(spacing: 12) {
                colorRow("Cream", color: AppTheme.Colors.cream)
                colorRow("Deep Ops", color: AppTheme.Colors.deepOps)
                colorRow("Brass Gold", color: AppTheme.Colors.brassGold)
                colorRow("Army Tan", color: AppTheme.Colors.armyTan)
                colorRow("Olive Mist", color: AppTheme.Colors.oliveMist)
                colorRow("Command Black", color: AppTheme.Colors.commandBlack)
                colorRow("Tactical Gray", color: AppTheme.Colors.tacticalGray)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                colorRow("Primary", color: AppTheme.Colors.primary)
                colorRow("Secondary", color: AppTheme.Colors.secondary)
                colorRow("Accent", color: AppTheme.Colors.accent)
                colorRow("Background", color: AppTheme.Colors.background)
                colorRow("Card Background", color: AppTheme.Colors.cardBackground)
                colorRow("Success", color: AppTheme.Colors.success)
                colorRow("Warning", color: AppTheme.Colors.warning)
                colorRow("Error", color: AppTheme.Colors.error)
                colorRow("Info", color: AppTheme.Colors.info)
            }
        }
    }
    
    private func colorRow(_ name: String, color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 60, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            Text(name)
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
        }
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Typography")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Heading 1")
                    .font(AppTheme.Typography.heading1())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Heading 2")
                    .font(AppTheme.Typography.heading2())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Heading 3")
                    .font(AppTheme.Typography.heading3())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Heading 4")
                    .font(AppTheme.Typography.heading4())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Body Regular")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Body Bold")
                    .font(AppTheme.Typography.bodyBold())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Body Semibold")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Monospace")
                    .font(AppTheme.Typography.mono())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Buttons")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button("Primary Button") { }
                    .ptButtonStyle(variant: .primary)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Secondary")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button("Secondary Button") { }
                    .ptButtonStyle(variant: .secondary)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Outline")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button("Outline Button") { }
                    .ptButtonStyle(variant: .outline)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ghost")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button("Ghost Button") { }
                    .ptButtonStyle(variant: .ghost)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Destructive")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Button("Destructive Button") { }
                    .ptButtonStyle(variant: .destructive)
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Button Sizes")
                    .font(AppTheme.Typography.bodySemiBold())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                HStack {
                    Button("Small") { }
                        .ptButtonStyle(variant: .primary, size: .small)
                    
                    Spacer()
                    
                    Button("Medium") { }
                        .ptButtonStyle(variant: .primary, size: .medium)
                    
                    Spacer()
                    
                    Button("Large") { }
                        .ptButtonStyle(variant: .primary, size: .large)
                }
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Text Fields")
            
            PTTextField(
                title: "Standard Text Field",
                text: $textField1,
                placeholder: "Enter text",
                isRequired: true
            )
            
            PTTextField(
                title: "Error State",
                text: $textField2,
                placeholder: "Enter text",
                isRequired: true,
                isError: true,
                errorMessage: "This field is required"
            )
            
            PTTextField(
                title: "Password Field",
                text: $passwordField,
                placeholder: "Enter password",
                isSecure: true,
                isRequired: true
            )
            
            PTTextField(
                title: "Disabled Field",
                text: .constant("Disabled value"),
                placeholder: "Enter text",
                isDisabled: true
            )
        }
    }
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Cards & Panels")
            
            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Card with Small Shadow")
                        .font(AppTheme.Typography.bodySemiBold())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("This is a card with a small shadow and standard padding")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(shadowDepth: .small)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Card with Medium Shadow")
                        .font(AppTheme.Typography.bodySemiBold())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("This is a card with a medium shadow and standard padding")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(shadowDepth: .medium)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Card with Large Shadow")
                        .font(AppTheme.Typography.bodySemiBold())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("This is a card with a large shadow and standard padding")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(shadowDepth: .large)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Card with Header")
                            .font(AppTheme.Typography.bodySemiBold())
                        Spacer()
                    }
                    .padding()
                    .headerBackground()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This is card content with a colored header")
                            .font(AppTheme.Typography.body())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                }
                .cornerRadius(AppTheme.Radius.card)
                .withShadow(AppTheme.Shadows.card)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Panel Style")
                        .font(AppTheme.Typography.bodySemiBold())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("This content uses the panel style with cream background")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .panelStyle()
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.heading3())
            .foregroundColor(AppTheme.Colors.deepOps)
            .padding(.bottom, 4)
    }
}

#Preview {
    NavigationView {
        StyleGuideView()
    }
} 