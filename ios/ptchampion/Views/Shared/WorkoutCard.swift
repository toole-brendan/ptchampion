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

// MARK: - Legacy compatibility for existing codebase
// This version supports the older API style but keeps the new styling
struct WorkoutCard: View {
    // Legacy properties
    let title: String
    let subtitle: String?
    let date: Date
    let metrics: [WorkoutMetric]
    let imageName: String?
    var onTap: (() -> Void)?
    
    // MARK: - Initializers
    
    // Legacy initializer
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
    
    // Modern initializer
    init(workout: WorkoutModel, onTap: @escaping () -> Void) {
        self.title = workout.exerciseType.rawValue
        self.subtitle = nil
        self.date = workout.date
        
        // Convert workout data to metrics
        var workoutMetrics: [WorkoutMetric] = []
        workoutMetrics.append(WorkoutMetric(title: "Reps", value: workout.repetitions, iconSystemName: "number"))
        
        // Format duration
        let minutes = Int(workout.duration / 60)
        let seconds = Int(workout.duration.truncatingRemainder(dividingBy: 60))
        let formattedDuration = String(format: "%d:%02d", minutes, seconds)
        workoutMetrics.append(WorkoutMetric(title: "Time", value: formattedDuration, unit: "min", iconSystemName: "clock"))
        
        if let hr = workout.averageHeartRate {
            workoutMetrics.append(WorkoutMetric(title: "Heart Rate", value: hr, unit: "bpm", iconSystemName: "heart.fill"))
        }
        
        self.metrics = workoutMetrics
        self.imageName = nil
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
            PTCard {
                VStack(alignment: .leading, spacing: AppTheme.GeneratedSpacing.contentPadding) {
                    // Header with title and date
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            PTLabel(title, style: .subheading)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                            
                            if let subtitle = subtitle {
                                PTLabel(subtitle, style: .body)
                                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                            }
                            
                            PTLabel(formattedDate, style: .caption)
                                .foregroundColor(AppTheme.GeneratedColors.textTertiary.opacity(0.8))
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
                        ], spacing: AppTheme.GeneratedSpacing.contentPadding) {
                            ForEach(metrics) { metric in
                                metricView(metric)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func metricView(_ metric: WorkoutMetric) -> some View {
        HStack(spacing: AppTheme.GeneratedSpacing.itemSpacing) {
            if let systemName = metric.iconSystemName {
                Image(systemName: systemName)
                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    .frame(width: 18, height: 18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                PTLabel(metric.title, style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.textTertiary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(metric.value)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                    
                    if let unit = metric.unit {
                        PTLabel(unit, style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.textTertiary)
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

// MARK: - Preview
struct WorkoutCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.GeneratedSpacing.cardGap) {
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
        .background(AppTheme.GeneratedColors.background.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
} 