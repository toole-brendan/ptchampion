import SwiftUI
import PTDesignSystem
import SnapshotTesting
@testable import PTChampion

class DesignSystemSnapshotTests: XCTestCase {
    
    func testButtonVariants() {
        let buttonVariants = ButtonVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: buttonVariants), as: .image(on: .iPhone13), named: "buttons-light")
        assertSnapshot(matching: UIHostingController(rootView: buttonVariants.preferredColorScheme(.dark), as: .image(on: .iPhone13), named: "buttons-dark")
    }
    
    func testMetricCardVariants() {
        let metricCards = MetricCardVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: metricCards), as: .image(on: .iPhone13), named: "metric-cards-light")
        assertSnapshot(matching: UIHostingController(rootView: metricCards.preferredColorScheme(.dark), as: .image(on: .iPhone13), named: "metric-cards-dark")
    }
    
    func testTextFieldVariants() {
        let textFields = TextFieldVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: textFields), as: .image(on: .iPhone13), named: "text-fields-light")
        assertSnapshot(matching: UIHostingController(rootView: textFields.preferredColorScheme(.dark), as: .image(on: .iPhone13), named: "text-fields-dark")
    }
    
    func testColorTokens() {
        let colorTokens = ColorTokensView()
        
        // Test all color tokens
        assertSnapshot(matching: UIHostingController(rootView: colorTokens), as: .image(on: .iPhone13), named: "color-tokens")
    }
}

// Test Views

struct ButtonVariantsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Button Variants")
                    .font(.heading2()())
                
                Group {
                    Button("Primary Button") {}
                        .ptButtonStyle(variant: .primary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Secondary Button") {}
                        .ptButtonStyle(variant: .secondary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Outline Button") {}
                        .ptButtonStyle(variant: .secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.textPrimary, lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity)
                    
                    Button("Ghost Button") {}
                        .ptButtonStyle(variant: .secondary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Destructive Button") {}
                        .ptButtonStyle(variant: .destructive)
                        .frame(maxWidth: .infinity)
                }
                
                Text("Button Sizes")
                    .font(.heading2()())
                
                Group {
                    Button("Small Button") {}
                        .ptButtonStyle(variant: .primary)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                    
                    Button("Medium Button") {}
                        .ptButtonStyle(variant: .primary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Large Button") {}
                        .ptButtonStyle(variant: .primary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                
                Text("Loading State")
                    .font(.heading2()())
                
                Button("Loading Button") {}
                    .ptButtonStyle(isLoading: true)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color.background)
    }
}

struct MetricCardVariantsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Metric Cards")
                    .font(.heading2()())
                
                MetricCardView(
                    .init(
                        title: "TOTAL WORKOUTS",
                        value: 42,
                        icon: Image(systemName: "flame.fill"),
                        trend: .up
                    )
                )
                
                MetricCardView(
                    .init(
                        title: "DISTANCE", 
                        value: 8.5, 
                        unit: "km",
                        icon: Image(systemName: "figure.run"),
                        trend: .down
                    )
                )
                
                MetricCardView(
                    .init(
                        title: "LAST ACTIVITY",
                        value: "Pull-ups",
                        description: "Yesterday - 42 reps",
                        icon: Image(systemName: "clock"),
                        trend: .neutral
                    )
                )
            }
            .padding()
        }
        .background(Color.background)
    }
}

struct TextFieldVariantsView: View {
    @State private var text1 = ""
    @State private var text2 = "john.doe@military.gov"
    @State private var password = "password123"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Text Fields")
                    .font(.heading2()())
                
                FocusableTextField(
                    text: $text1,
                    placeholder: "Enter your name"
                )
                
                FocusableTextField(
                    text: $text2,
                    placeholder: "Email",
                    keyboardType: .emailAddress
                )
                
                FocusableTextField(
                    text: $password,
                    placeholder: "Password",
                    isSecure: true
                )
            }
            .padding()
        }
        .background(Color.background)
    }
}

struct ColorTokensView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.itemSpacing) {
                Text("Color Tokens")
                    .font(.heading2()())
                
                ColorSwatch("deepOps", color: Color.deepOps)
                ColorSwatch("brassGold", color: Color.brassGold)
                ColorSwatch("armyTan", color: Color.armyTan)
                ColorSwatch("oliveMist", color: Color.oliveMist)
                ColorSwatch("commandBlack", color: Color.commandBlack)
                ColorSwatch("tacticalGray", color: Color.tacticalGray)
                ColorSwatch("cream", color: Color.cream)
                ColorSwatch("success", color: Color.success)
                ColorSwatch("warning", color: Color.warning)
                ColorSwatch("error", color: Color.error)
                ColorSwatch("info", color: Color.info)
            }
            .padding()
        }
        .background(Color.background)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    init(_ name: String, color: Color) {
        self.name = name
        self.color = color
    }
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(name)
                .font(.body()())
                .padding(.leading, Spacing.small)
        }
    }
} 