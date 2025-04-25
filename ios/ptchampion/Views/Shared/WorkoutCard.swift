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
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                // Header with title and date
                HStack {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                        Text(title)
                            .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.lg))
                            .foregroundColor(.commandBlack)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                                .foregroundColor(.tacticalGray)
                        }
                        
                        Text(formattedDate)
                            .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                            .foregroundColor(.tacticalGray.opacity(0.8))
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
                    ], spacing: AppConstants.Spacing.md) {
                        ForEach(metrics) { metric in
                            metricView(metric)
                        }
                    }
                    .padding(.top, AppConstants.Spacing.xs)
                }
            }
            .padding(AppConstants.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(AppConstants.Radius.lg)
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func metricView(_ metric: WorkoutMetric) -> some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            if let systemName = metric.iconSystemName {
                Image(systemName: systemName)
                    .foregroundColor(.brassGold)
                    .frame(width: 18, height: 18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                    .foregroundColor(.tacticalGray)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(metric.value)
                        .font(.custom(AppFonts.mono, size: AppConstants.FontSize.md))
                        .foregroundColor(.commandBlack)
                    
                    if let unit = metric.unit {
                        Text(unit)
                            .font(.custom(AppFonts.body, size: AppConstants.FontSize.xs))
                            .foregroundColor(.tacticalGray)
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
        VStack(spacing: AppConstants.Spacing.md) {
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
        .background(Color.tacticalCream.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 