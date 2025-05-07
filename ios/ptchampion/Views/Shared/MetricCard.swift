import SwiftUI
import PTDesignSystem
/// A tappable metric card component that displays a key metric
/// with title, value, and optional unit, description, and trend indicators.
public struct MetricCardView: View {
    private let metric: MetricData
    private let action: (() -> Void)?
    private let trend: TrendDirection?
    
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
        Button(action: { action?() }) {
            cardContent
        }
        .buttonStyle(MetricCardButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(metric.title), \(displayValue) \(metric.unit ?? "")")
        .accessibilityHint(metric.description ?? "")
    }
    
    // Helper to convert the Any value to a displayable string
    private var displayValue: String {
        switch metric.value {
        case let intValue as Int:
            return "\(intValue)"
        case let doubleValue as Double:
            return "\(doubleValue)"
        case let stringValue as String:
            return stringValue
        default:
            return "\(metric.value)"
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.itemSpacing) {
            // Title row with optional icon
            HStack(spacing: 4) {
                Text(metric.title)
                    .font(AppTheme.GeneratedTypography.bodySemibold(size: 13))
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if let icon = metric.icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
            }
            
            // Value with optional unit
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if displayValue == "-" || displayValue == "0" {
                    Text(displayValue)
                        .font(AppTheme.GeneratedTypography.bodyBold(size: 20))
                        .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                        .padding(.horizontal, AppTheme.GeneratedSpacing.small)
                        .padding(.vertical, AppTheme.GeneratedSpacing.extraSmall)
                        .background(
                            AppTheme.GeneratedColors.tacticalGray.opacity(0.6)
                                .clipShape(Capsule())
                        )
                } else {
                    Text(displayValue)
                        .font(AppTheme.GeneratedTypography.bodyBold(size: 20))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                }
                
                if let unit = metric.unit {
                    Text(unit)
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .padding(.leading, -2)
                }
                
                if let trend = self.trend {
                    trend.icon
                        .foregroundColor(trend.color)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            
            // Optional description
            if let description = metric.description {
                Text(description)
                    .font(AppTheme.GeneratedTypography.body(size: 13))
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
        .withShadow(AppTheme.GeneratedShadows.small)
    }
}

/// A button style that applies to MetricCard, making it pressable with animations
struct MetricCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Preview provider
struct MetricCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
            HStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
                MetricCardView(
                    MetricData(
                        title: "TOTAL WORKOUTS",
                        value: 42,
                        icon: Image(systemName: "flame.fill")
                    ),
                    trend: .up
                )
                .frame(maxWidth: .infinity)
                
                MetricCardView(
                    MetricData(
                        title: "DISTANCE", 
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
                    title: "LAST ACTIVITY",
                    value: "Pull-ups",
                    description: "Yesterday - 42 reps",
                    icon: Image(systemName: "clock")
                ),
                trend: .neutral
            )
        }
        .padding()
        .background(AppTheme.GeneratedColors.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
            MetricCardView(
                MetricData(
                    title: "MAX HEART RATE",
                    value: 172,
                    unit: "bpm",
                    icon: Image(systemName: "heart.fill")
                ),
                trend: .up
            )
        }
        .padding()
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
} 