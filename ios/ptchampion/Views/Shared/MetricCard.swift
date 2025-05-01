import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let description: String?
    let unit: String?
    let icon: Image?
    var action: (() -> Void)?
    
    init(
        title: String,
        value: String,
        description: String? = nil,
        unit: String? = nil,
        icon: Image? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.description = description
        self.unit = unit
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: { self.action?() }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.itemSpacing) {
                // Title row with optional icon
                HStack(spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.bodySemiBold(size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    if let icon = icon {
                        icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(AppTheme.Colors.brassGold)
                    }
                }
                
                // Value with optional unit
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppTheme.Typography.bodyBold(size: 20))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(AppTheme.Typography.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.leading, -2)
                    }
                }
                
                // Optional description
                if let description = description {
                    Text(description)
                        .font(AppTheme.Typography.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(AppTheme.Spacing.contentPadding)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .withShadow(AppTheme.Shadows.card)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Convenience initializers for numeric values
    init<T: Numeric & CustomStringConvertible>(
        title: String,
        value: T,
        description: String? = nil,
        unit: String? = nil,
        icon: Image? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            value: value.description,
            description: description,
            unit: unit,
            icon: icon,
            action: action
        )
    }
}

// Preview provider
struct MetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.Spacing.cardGap) {
            HStack(spacing: AppTheme.Spacing.cardGap) {
                MetricCard(
                    title: "TOTAL WORKOUTS",
                    value: 42,
                    icon: Image(systemName: "flame.fill")
                )
                .frame(maxWidth: .infinity)
                
                MetricCard(
                    title: "DISTANCE", 
                    value: 8.5, 
                    unit: "km",
                    icon: Image(systemName: "figure.run")
                )
                .frame(maxWidth: .infinity)
            }
            
            MetricCard(
                title: "LAST ACTIVITY",
                value: "Pull-ups",
                description: "Yesterday - 42 reps",
                icon: Image(systemName: "clock")
            )
        }
        .padding()
        .background(AppTheme.Colors.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 