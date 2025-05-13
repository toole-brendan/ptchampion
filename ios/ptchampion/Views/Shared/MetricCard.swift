import SwiftUI
import PTDesignSystem
/// A tappable metric card component that displays a key metric
/// with title, value, and optional unit, description, and trend indicators.
public struct MetricCardView: View {
    private let metric: MetricData
    private let action: (() -> Void)?
    private let trend: TrendDirection?
    
    @State private var isPressed = false
    @State private var animateValue = false
    
    public init(
        _ metric: MetricData,
        trend: TrendDirection? = nil,
        action: (() -> Void)? = nil
    ) {
        self.metric = metric
        self.trend = trend
        self.action = action
    }
    
    public var body: some View {
        Button(action: { 
            // Trigger haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action?() 
        }) {
            cardContent
        }
        .buttonStyle(MetricCardButtonStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(metric.title), \(displayValue) \(metric.unit ?? "")")
        .accessibilityHint(metric.description ?? "")
        .onAppear {
            // Animate the value counter when the card appears
            if !animateValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8) {
                        animateValue = true
                    }
                }
            }
        }
    }
    
    // Helper to convert the Any value to a displayable string
    private var displayValue: String {
        switch metric.value {
        case let intValue as Int:
            return "\(intValue)"
        case let doubleValue as Double:
            // Format with 1 decimal place if needed
            return doubleValue.truncatingRemainder(dividingBy: 1) == 0 ? 
                "\(Int(doubleValue))" : String(format: "%.1f", doubleValue)
        case let stringValue as String:
            return stringValue
        default:
            return "\(metric.value)"
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.itemSpacing) {
            // Title row with optional icon
            HStack(spacing: 6) {
                if let icon = metric.icon {
                    icon
                        .font(.system(size: 15, weight: .medium)
                        .foregroundColor(ThemeColor.brassGold)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(ThemeColor.brassGold.opacity(0.15)
                        )
                }
                
                Text(metric.title)
                    .small(weight: .medium))
                    .foregroundColor(ThemeColor.textSecondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Trend indicator
                if let trend = self.trend {
                    HStack(spacing: 3) {
                        trend.icon
                            .caption() weight: .bold))
                            .foregroundColor(trend.color)
                            // Add subtle rotation animation when trend changes
                            .rotationEffect(trend == .up ? .degrees(0) : (trend == .down ? .degrees(180) : .degrees(90))
                            .animation(.spring(response: 0.3), value: trend)
                            
                        // Optional percentage or change value could go here
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(trend.color.opacity(0.1)
                    )
                }
            }
            
            // Value with optional unit
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if displayValue == "-" || displayValue == "0" {
                    // For placeholder or zero values
                    Text(displayValue)
                        .heading1(weight: .bold, design: .rounded).monospacedDigit()
                        .foregroundColor(ThemeColor.tacticalGray)
                        .opacity(0.7)
                } else {
                    // For actual values with counting animation
                    if let intValue = Int(displayValue), animateValue {
                        Text("\(intValue)")
                            .heading1(weight: .bold, design: .rounded).monospacedDigit()
                            .foregroundColor(ThemeColor.textPrimary)
                            .contentTransition(.numericText()
                            .transaction { transaction in
                                transaction.animation = .spring(response: 0.8, dampingFraction: 0.8)
                            }
                    } else if let doubleValue = Double(displayValue), animateValue {
                        Text(String(format: "%.1f", doubleValue))
                            .heading1(weight: .bold, design: .rounded).monospacedDigit()
                            .foregroundColor(ThemeColor.textPrimary)
                            .contentTransition(.numericText()
                    } else {
                        // For string values or before animation
                        Text(displayValue)
                            .heading1(weight: .bold, design: .rounded).monospacedDigit()
                            .foregroundColor(ThemeColor.textPrimary)
                    }
                }
                
                if let unit = metric.unit {
                    Text(unit)
                        .body(weight: .medium))
                        .foregroundColor(ThemeColor.textTertiary)
                        .padding(.leading, 2)
                        .alignmentGuide(.firstTextBaseline) { d in
                            d[.firstTextBaseline] - 4 // Align slightly below baseline
                        }
                }
            }
            
            // Optional description
            if let description = metric.description {
                Text(description)
                    .font(.system(size: 13)
                    .foregroundColor(ThemeColor.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(Spacing.contentPadding)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(
            ZStack {
                // Base layer
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(ThemeColor.cardBackground)
                
                // Subtle accent gradient at top
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ThemeColor.brassGold.opacity(0.05),
                                ThemeColor.cardBackground.opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Subtle border
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ThemeColor.brassGold.opacity(0.2),
                                ThemeColor.cardBackground.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(
            color: ThemeColor.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

/// A button style that applies to MetricCard, making it pressable with animations
struct MetricCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            // Change shadow on press for tactile feedback
            .shadow(
                color: configuration.isPressed ? 
                    ThemeColor.black.opacity(0.05) : ThemeColor.black.opacity(0.08),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            // Add subtle brightness change on press
            .brightness(configuration.isPressed ? -0.02 : 0)
    }
}

// Preview provider
struct MetricCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.cardGap) {
            HStack(spacing: Spacing.cardGap) {
                MetricCardView(
                    MetricData(
                        title: "Workouts",
                        value: 42,
                        icon: Image(systemName: "flame.fill")
                    ),
                    trend: .up
                )
                .frame(maxWidth: .infinity)
                
                MetricCardView(
                    MetricData(
                        title: "Distance", 
                        value: 8.5, 
                        unit: "km",
                        icon: Image(systemName: "figure.run")
                    ),
                    trend: .down
                )
                .frame(maxWidth: .infinity)
            }
            
            MetricCardView(
                MetricData(
                    title: "Last Activity",
                    value: "Pull-ups",
                    description: "Yesterday - 42 reps",
                    icon: Image(systemName: "clock")
                ),
                trend: .neutral
            )
        }
        .padding()
        .background(ThemeColor.background.opacity(0.5)
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(spacing: Spacing.cardGap) {
            MetricCardView(
                MetricData(
                    title: "Max Heart Rate",
                    value: 172,
                    unit: "bpm",
                    icon: Image(systemName: "heart.fill")
                ),
                trend: .up
            )
        }
        .padding()
        .background(ThemeColor.black)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
} 