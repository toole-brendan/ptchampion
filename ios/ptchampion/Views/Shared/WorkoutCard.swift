import SwiftUI
import PTDesignSystem

// Define a basic WorkoutModel to maintain compatibility
struct WorkoutModel {
    let id: String
    let userId: String
    let exerciseType: WorkoutExerciseType
    let date: Date
    let repetitions: Int
    let duration: TimeInterval
    let score: Int
    let intensity: WorkoutIntensity
    let averageHeartRate: Int?
    let location: String?
    
    // Display name for exercise type
    var displayName: String {
        return exerciseType.rawValue
    }
}

// Define ExerciseType enum
enum WorkoutExerciseType: String {
    case pushup = "Push-Ups"
    case situp = "Sit-Ups"
    case pullup = "Pull-Ups"
    case running = "Running"
    case other = "Other"
}

// Define Intensity enum 
enum WorkoutIntensity: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// Workout metadata for display
struct WorkoutMetric {
    let title: String
    let value: String
    let unit: String?
    let iconSystemName: String
    
    init(title: String, value: String, unit: String? = nil, iconSystemName: String) {
        self.title = title
        self.value = value
        self.unit = unit
        self.iconSystemName = iconSystemName
    }
    
    init(title: String, value: Int, iconSystemName: String) {
        self.init(
            title: title,
            value: "\(value)",
            unit: nil,
            iconSystemName: iconSystemName
        )
    }
    
    init(title: String, value: Double, precision: Int = 1, unit: String? = nil, iconSystemName: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = precision
        
        let valueString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        
        self.init(
            title: title,
            value: valueString,
            unit: unit,
            iconSystemName: iconSystemName
        )
    }
    
    init(title: String, value: TimeInterval, unit: String = "min", iconSystemName: String) {
        let minutes = Int(value / 60)
        let seconds = Int(value.truncatingRemainder(dividingBy: 60))
        let valueString = String(format: "%d:%02d", minutes, seconds)
        
        self.init(
            title: title,
            value: valueString,
            unit: unit,
            iconSystemName: iconSystemName
        )
    }
}

/// A card displaying workout summary information
struct WorkoutCard: View {
    let title: String
    let subtitle: String?
    let date: Date
    let metrics: [WorkoutMetric]
    let onTap: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        date: Date,
        metrics: [WorkoutMetric],
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.metrics = metrics
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack {
                VStack(alignment: .leading, spacing: Spacing.contentPadding) {
                    // Header with title and date
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(ThemeColor.textPrimary)
                                .lineLimit(1)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(ThemeColor.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundColor(ThemeColor.textSecondary)
                            
                            Text(date, style: .time)
                                .font(.caption)
                                .foregroundColor(ThemeColor.textSecondary)
                        }
                    }
                    
                    // Metrics
                    HStack(spacing: 12) {
                        ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                            WorkoutMetricView(metric: metric)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
                .padding(Spacing.contentPadding)
            }
            .background(ThemeColor.cardBackground)
            .cornerRadius(CornerRadius.card)
            .shadow(color: ThemeColor.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// An individual metric display with icon
struct WorkoutMetricView: View {
    let metric: WorkoutMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: metric.iconSystemName)
                .font(.caption)
                .foregroundColor(ThemeColor.textSecondary)
                .frame(width: 20, height: 20)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(metric.value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ThemeColor.textPrimary)
                
                if let unit = metric.unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(ThemeColor.textSecondary)
                }
            }
            
            Text(metric.title)
                .font(.caption)
                .foregroundColor(ThemeColor.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview
struct WorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.cardGap) {
            WorkoutCard(
                title: "Push-ups Workout",
                subtitle: "Morning Routine",
                date: Date(),
                metrics: [
                    WorkoutMetric(title: "Reps", value: 42, iconSystemName: "flame.fill"),
                    WorkoutMetric(title: "Time", value: "2:30", unit: "min", iconSystemName: "clock")
                ],
                onTap: nil
            )
            
            WorkoutCard(
                title: "Running Session",
                date: Date().addingTimeInterval(-86400),
                metrics: [
                    WorkoutMetric(title: "Distance", value: 5.2, unit: "km", iconSystemName: "figure.run"),
                    WorkoutMetric(title: "Pace", value: "5:30", unit: "min/km", iconSystemName: "speedometer")
                ],
                onTap: nil
            )
        }
        .padding()
        .background(ThemeColor.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 