import SwiftUI

/// A view that showcases all the styling components
struct StyleShowcaseView: View {
    @State private var isPressed = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ContainerStyle.Spacing.section) {
                // MARK: - Typography Section
                VStack(alignment: .leading, spacing: ContainerStyle.Spacing.md) {
                    Text("Typography")
                        .heading1()
                        .padding(.bottom, ContainerStyle.Spacing.sm)
                    
                    Divider().background(Color.brassGold)
                    
                    // Headings
                    Group {
                        Text("Heading 1").heading1()
                        Text("Heading 2").heading2()
                        Text("Heading 3").heading3()
                        Text("Heading 4").heading4()
                    }
                    
                    Divider().background(Color.brassGold.opacity(0.5)
                    
                    // Body Text
                    Group {
                        Text("Body Text").body()
                        Text("Body Bold").bodyBold()
                        Text("Body Semibold").bodySemibold()
                    }
                    
                    Divider().background(Color.brassGold.opacity(0.5)
                    
                    // Small Text
                    Group {
                        Text("Small Text").small()
                        Text("Small Semibold").smallSemibold()
                        Text("Caption").caption()
                        Text("LABEL TEXT").label()
                    }
                    
                    Divider().background(Color.brassGold.opacity(0.5)
                    
                    // Special Text
                    Group {
                        Text("123.45").metric()
                        Text("monospace").code()
                    }
                }
                .padding()
                .card(variant: .default)
                
                // MARK: - Color Section
                VStack(alignment: .leading, spacing: ContainerStyle.Spacing.md) {
                    Text("Colors")
                        .heading2()
                        .padding(.bottom, ContainerStyle.Spacing.sm)
                    
                    Divider().background(Color.brassGold)
                    
                    // Base Colors
                    Text("Base Colors").heading4(color: .brassGold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100)], spacing: 10) {
                        ColorSwatch(name: "Cream", color: .cream)
                        ColorSwatch(name: "Cream Dark", color: .creamDark)
                        ColorSwatch(name: "Cream Light", color: .creamLight)
                        ColorSwatch(name: "Deep Ops", color: .deepOps)
                        ColorSwatch(name: "Brass Gold", color: .brassGold)
                        ColorSwatch(name: "Army Tan", color: .armyTan)
                        ColorSwatch(name: "Olive Mist", color: .oliveMist)
                        ColorSwatch(name: "Command Black", color: .commandBlack)
                        ColorSwatch(name: "Tactical Gray", color: .tacticalGray)
                        ColorSwatch(name: "Hunter Green", color: .hunterGreen)
                    }
                    
                    // Semantic Colors
                    Text("Semantic Colors").heading4(color: .brassGold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100)], spacing: 10) {
                        ColorSwatch(name: "Primary", color: .primary)
                        ColorSwatch(name: "Secondary", color: .secondary)
                        ColorSwatch(name: "Background", color: .background)
                        ColorSwatch(name: "Foreground", color: .foreground)
                        ColorSwatch(name: "Accent", color: .accent)
                        ColorSwatch(name: "Muted", color: .muted)
                    }
                    
                    // Status Colors
                    Text("Status Colors").heading4(color: .brassGold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100)], spacing: 10) {
                        ColorSwatch(name: "Success", color: .success)
                        ColorSwatch(name: "Warning", color: .warning)
                        ColorSwatch(name: "Error", color: .error)
                        ColorSwatch(name: "Info", color: .info)
                    }
                }
                .padding()
                .card(variant: .default)
                
                // MARK: - Card Variants Section
                VStack(alignment: .leading, spacing: ContainerStyle.Spacing.md) {
                    Text("Card Variants")
                        .heading2()
                        .padding(.bottom, ContainerStyle.Spacing.sm)
                    
                    Divider().background(Color.brassGold)
                    
                    VStack(spacing: ContainerStyle.Spacing.lg) {
                        CardExampleView(title: "Default Card", variant: .default)
                        CardExampleView(title: "Interactive Card", variant: .interactive)
                        CardExampleView(title: "Elevated Card", variant: .elevated)
                        CardExampleView(title: "Panel Card", variant: .panel)
                        CardExampleView(title: "Flush Card", variant: .flush)
                    }
                }
                .padding()
                .card(variant: .default)
                
                // MARK: - Button Demo
                VStack(alignment: .leading, spacing: ContainerStyle.Spacing.md) {
                    Text("Buttons")
                        .heading2()
                        .padding(.bottom, ContainerStyle.Spacing.sm)
                    
                    Text("Note: This section just shows button styling recommendations, not actual button components. You should create a Button.swift file to implement these styles.")
                        .small(color: .tacticalGray)
                        .padding(.bottom, ContainerStyle.Spacing.md)
                    
                    VStack(spacing: ContainerStyle.Spacing.md) {
                        // Primary Button Example
                        Text("PRIMARY BUTTON")
                            .bodyBold(color: .deepOps)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brassGold)
                            .cornerRadius(8)
                        
                        // Secondary Button Example
                        Text("SECONDARY BUTTON")
                            .bodyBold(color: .brassGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.brassGold, lineWidth: 1)
                            )
                        
                        // Destructive Button Example
                        Text("DESTRUCTIVE BUTTON")
                            .bodyBold(color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.error)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .card(variant: .default)
                
                // MARK: - Interactive Demo
                VStack(alignment: .leading, spacing: ContainerStyle.Spacing.md) {
                    Text("Interactive Demo")
                        .heading2()
                        .padding(.bottom, ContainerStyle.Spacing.sm)
                    
                    VStack(spacing: ContainerStyle.Spacing.md) {
                        Text("Tap to see pressed state")
                            .body(color: .tacticalGray)
                        
                        Button(action: { }) {
                            VStack {
                                Text("Interactive Card")
                                    .heading4(color: .brassGold)
                                
                                Color.brassGold
                                    .opacity(0.1)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
                        .buttonStyle(PressableCardStyle()
                    }
                }
                .padding()
                .card(variant: .default)
            }
            .padding(.vertical, ContainerStyle.Spacing.section)
            .container()
        }
        .background(Color.background.edgesIgnoringSafeArea(.all)
        .navigationTitle("Style Showcase")
    }
}

// MARK: - Helper Components

/// A color swatch component
struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            Text(name)
                .caption()
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

/// A card example component
struct CardExampleView: View {
    let title: String
    let variant: CardVariant
    
    var body: some View {
        VStack(alignment: .leading, spacing: ContainerStyle.Spacing.sm) {
            CardTitle(title)
            
            Text("This is a sample card with the \(String(describing: variant)) variant.")
                .small()
        }
        .card(variant: variant)
    }
}

/// A pressable card button style
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .interactiveCard(isPressed: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        StyleShowcaseView()
    }
} 