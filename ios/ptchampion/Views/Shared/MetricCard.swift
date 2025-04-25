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
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                // Title row with optional icon
                HStack(spacing: AppConstants.Spacing.xs) {
                    Text(title)
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.sm))
                        .foregroundColor(.tacticalGray)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    if let icon = icon {
                        icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.brassGold)
                    }
                }
                
                // Value with optional unit
                HStack(alignment: .firstTextBaseline, spacing: AppConstants.Spacing.xs) {
                    Text(value)
                        .font(.custom(AppFonts.bodyBold, size: AppConstants.FontSize.xl))
                        .foregroundColor(.commandBlack)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                            .foregroundColor(.tacticalGray)
                            .padding(.leading, -AppConstants.Spacing.xs / 2)
                    }
                }
                
                // Optional description
                if let description = description {
                    Text(description)
                        .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                        .foregroundColor(.tacticalGray)
                        .lineLimit(1)
                }
            }
            .padding(AppConstants.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .background(Color.white)
            .cornerRadius(AppConstants.Radius.md)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.md) {
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
        .background(Color.tacticalCream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 