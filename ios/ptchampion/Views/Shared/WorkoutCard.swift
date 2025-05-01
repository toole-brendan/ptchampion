import SwiftUI

struct WorkoutCard: View {
    let title: String
    let subtitle: String?
    let date: Date
    let metrics: [WorkoutMetric]
    let imageName: String?
    var onTap: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        date: Date,
        metrics: [WorkoutMetric] = [],
        imageName: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.metrics = metrics
        self.imageName = imageName
        self.onTap = onTap
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.contentPadding) {
                // Header with title and date
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppTheme.Typography.bodySemiBold(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(AppTheme.Typography.body(size: 14))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        
                        Text(formattedDate)
                            .font(AppTheme.Typography.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if let imageName = imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                }
                
                // Metrics grid
                if !metrics.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.Spacing.contentPadding) {
                        ForEach(metrics) { metric in
                            metricView(metric)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(AppTheme.Spacing.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .withShadow(AppTheme.Shadows.cardMd)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func metricView(_ metric: WorkoutMetric) -> some View {
        HStack(spacing: AppTheme.Spacing.itemSpacing) {
            if let systemName = metric.iconSystemName {
                Image(systemName: systemName)
                    .foregroundColor(AppTheme.Colors.brassGold)
                    .frame(width: 18, height: 18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(AppTheme.Typography.body(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(metric.value)
                        .font(AppTheme.Typography.mono(size: 14))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let unit = metric.unit {
                        Text(unit)
                            .font(AppTheme.Typography.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// Model for workout metrics
struct WorkoutMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String?
    let iconSystemName: String?
    
    init(title: String, value: String, unit: String? = nil, iconSystemName: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
        self.iconSystemName = iconSystemName
    }
    
    // Convenience initializer for numeric values
    init<T: CustomStringConvertible>(title: String, value: T, unit: String? = nil, iconSystemName: String? = nil) {
        self.init(title: title, value: value.description, unit: unit, iconSystemName: iconSystemName)
    }
}

// Preview provider
struct WorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.Spacing.cardGap) {
            WorkoutCard(
                title: "Push-ups Workout",
                subtitle: "Morning Routine",
                date: Date(),
                metrics: [
                    WorkoutMetric(title: "Reps", value: 42, iconSystemName: "flame.fill"),
                    WorkoutMetric(title: "Time", value: "2:30", unit: "min", iconSystemName: "clock")
                ],
                imageName: nil // In real app, use image name from assets
            )
            
            WorkoutCard(
                title: "Running Session",
                date: Date().addingTimeInterval(-86400),
                metrics: [
                    WorkoutMetric(title: "Distance", value: 5.2, unit: "km", iconSystemName: "figure.run"),
                    WorkoutMetric(title: "Pace", value: "5:30", unit: "min/km", iconSystemName: "speedometer")
                ]
            )
        }
        .padding()
        .background(AppTheme.Colors.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 