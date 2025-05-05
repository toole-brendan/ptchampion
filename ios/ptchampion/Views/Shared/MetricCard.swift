import SwiftUI
import PTDesignSystem
/// A tappable metric card component that displays a key metric
/// with title, value, and optional unit, description, and trend indicators.
public struct MetricCardView: View {
    public struct MetricData {
        let title: String
        let value: String
        let description: String?
        let unit: String?
        let icon: Image?
        let trend: TrendDirection?
        
        public init(
            title: String,
            value: String,
            description: String? = nil,
            unit: String? = nil,
            icon: Image? = nil,
            trend: TrendDirection? = nil
        ) {
            self.title = title
            self.value = value
            self.description = description
            self.unit = unit
            self.icon = icon
            self.trend = trend
        }
        
        // Convenience initializers for numeric values
        public init<T: Numeric & CustomStringConvertible>(
            title: String,
            value: T,
            description: String? = nil,
            unit: String? = nil,
            icon: Image? = nil,
            trend: TrendDirection? = nil
        ) {
            self.init(
                title: title,
                value: value.description,
                description: description,
                unit: unit,
                icon: icon,
                trend: trend
            )
        }
    }
    
    public enum TrendDirection {
        case up, down, neutral
        
        var icon: Image {
            switch self {
            case .up:
                return Image(systemName: "arrow.up")
            case .down:
                return Image(systemName: "arrow.down")
            case .neutral:
                return Image(systemName: "arrow.forward")
            }
        }
        
        var color: Color {
            switch self {
            case .up:
                return AppTheme.GeneratedColors.success
            case .down:
                return AppTheme.GeneratedColors.error
            case .neutral:
                return AppTheme.GeneratedColors.textTertiary
            }
        }
    }
    
    private let metric: MetricData
    private let action: (() -> Void)?
    
    public init(
        _ metric: MetricData,
        action: (() -> Void)? = nil
    ) {
        self.metric = metric
        self.action = action
    }
    
    public var body: some View {
        Button(action: { action?() }) {
            cardContent
        }
        .buttonStyle(MetricCardButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(metric.title), \(metric.value) \(metric.unit ?? "")")
        .accessibilityHint(metric.description ?? "")
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
                Text(metric.value)
                    .font(AppTheme.GeneratedTypography.bodyBold(size: 20))
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                
                if let unit = metric.unit {
                    Text(unit)
                        .font(AppTheme.GeneratedTypography.body(size: 14))
                        .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                        .padding(.leading, -2)
                }
                
                if let trend = metric.trend {
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
            .offset(y: configuration.isPressed && !reduceMotion ? -2 : 0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// Preview provider
struct MetricCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
            HStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
                MetricCardView(
                    .init(
                        title: "TOTAL WORKOUTS",
                        value: 42,
                        icon: Image(systemName: "flame.fill"),
                        trend: .up
                    )
                )
                .frame(maxWidth: .infinity)
                
                MetricCardView(
                    .init(
                        title: "DISTANCE", 
                        value: 8.5, 
                        unit: "km",
                        icon: Image(systemName: "figure.run"),
                        trend: .down
                    )
                )
                .frame(maxWidth: .infinity)
            }
            
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
        .background(AppTheme.GeneratedColors.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
            MetricCardView(
                .init(
                    title: "MAX HEART RATE",
                    value: "172",
                    unit: "bpm",
                    icon: Image(systemName: "heart.fill"),
                    trend: .up
                )
            )
        }
        .padding()
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
} 