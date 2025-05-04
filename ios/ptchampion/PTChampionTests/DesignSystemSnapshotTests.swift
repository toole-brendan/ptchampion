import SwiftUI
import PTDesignSystem
import SnapshotTesting
@testable import PTChampion

class DesignSystemSnapshotTests: XCTestCase {
    
    func testButtonVariants() {
        let buttonVariants = ButtonVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: buttonVariants), as: .image(on: .iPhone13), named: "buttons-light")
        assertSnapshot(matching: UIHostingController(rootView: buttonVariants.preferredColorScheme(.dark)), as: .image(on: .iPhone13), named: "buttons-dark")
    }
    
    func testMetricCardVariants() {
        let metricCards = MetricCardVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: metricCards), as: .image(on: .iPhone13), named: "metric-cards-light")
        assertSnapshot(matching: UIHostingController(rootView: metricCards.preferredColorScheme(.dark)), as: .image(on: .iPhone13), named: "metric-cards-dark")
    }
    
    func testTextFieldVariants() {
        let textFields = TextFieldVariantsView()
        
        // Test in Light and Dark mode
        assertSnapshot(matching: UIHostingController(rootView: textFields), as: .image(on: .iPhone13), named: "text-fields-light")
        assertSnapshot(matching: UIHostingController(rootView: textFields.preferredColorScheme(.dark)), as: .image(on: .iPhone13), named: "text-fields-dark")
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
                    .font(AppTheme.GeneratedTypography.heading2())
                
                Group {
                    Button("Primary Button") {}
                        .ptButtonStyle(variant: .primary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Secondary Button") {}
                        .ptButtonStyle(variant: .secondary)
                        .frame(maxWidth: .infinity)
                    
                    Button("Outline Button") {}
                        .ptButtonStyle(variant: .outline)
                        .frame(maxWidth: .infinity)
                    
                    Button("Ghost Button") {}
                        .ptButtonStyle(variant: .ghost)
                        .frame(maxWidth: .infinity)
                    
                    Button("Destructive Button") {}
                        .ptButtonStyle(variant: .destructive)
                        .frame(maxWidth: .infinity)
                }
                
                Text("Button Sizes")
                    .font(AppTheme.GeneratedTypography.heading2())
                
                Group {
                    Button("Small Button") {}
                        .ptButtonStyle(size: .small)
                        .frame(maxWidth: .infinity)
                    
                    Button("Medium Button") {}
                        .ptButtonStyle(size: .medium)
                        .frame(maxWidth: .infinity)
                    
                    Button("Large Button") {}
                        .ptButtonStyle(size: .large)
                        .frame(maxWidth: .infinity)
                }
                
                Text("Loading State")
                    .font(AppTheme.GeneratedTypography.heading2())
                
                Button("Loading Button") {}
                    .ptButtonStyle(isLoading: true)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(AppTheme.GeneratedColors.background)
    }
}

struct MetricCardVariantsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Metric Cards")
                    .font(AppTheme.GeneratedTypography.heading2())
                
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
        .background(AppTheme.GeneratedColors.background)
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
                    .font(AppTheme.GeneratedTypography.heading2())
                
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
        .background(AppTheme.GeneratedColors.background)
    }
}

struct ColorTokensView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Tokens")
                    .font(AppTheme.GeneratedTypography.heading2())
                
                ColorSwatch("deepOps", color: AppTheme.GeneratedColors.deepOps)
                ColorSwatch("brassGold", color: AppTheme.GeneratedColors.brassGold)
                ColorSwatch("armyTan", color: AppTheme.GeneratedColors.armyTan)
                ColorSwatch("oliveMist", color: AppTheme.GeneratedColors.oliveMist)
                ColorSwatch("commandBlack", color: AppTheme.GeneratedColors.commandBlack)
                ColorSwatch("tacticalGray", color: AppTheme.GeneratedColors.tacticalGray)
                ColorSwatch("cream", color: AppTheme.GeneratedColors.cream)
                ColorSwatch("success", color: AppTheme.GeneratedColors.success)
                ColorSwatch("warning", color: AppTheme.GeneratedColors.warning)
                ColorSwatch("error", color: AppTheme.GeneratedColors.error)
                ColorSwatch("info", color: AppTheme.GeneratedColors.info)
            }
            .padding()
        }
        .background(AppTheme.GeneratedColors.background)
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
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(name)
                .font(AppTheme.GeneratedTypography.body())
                .padding(.leading, 8)
        }
    }
} 