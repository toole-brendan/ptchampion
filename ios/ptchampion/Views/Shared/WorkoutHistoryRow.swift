import SwiftUI
import SwiftData
import PTDesignSystem

// Enhanced Row View for displaying a single workout result
struct WorkoutHistoryRow: View {
    let result: WorkoutResultSwiftData
    
    // Formatter for date
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Alternate date formatter for more compact display
    private static var shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    // Formatter for duration
    private func formatDuration(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Computed property to get the correct icon based on exercise type
    private var exerciseIcon: Image {
        let type = result.exerciseType.lowercased()
        switch type {
        case "pushup":
            return Image("pushup")
        case "situp":
            return Image("situp")
        case "pullup":
            return Image("pullup")
        case "run":
            return Image("running")
        default:
            return Image(systemName: "figure.strengthtraining.traditional")
        }
    }
    
    // Get the performance metric details based on exercise type
    private var performanceMetric: (value: String, label: String) {
        if let reps = result.repCount {
            return ("\(reps)", "reps")
        } else if let distance = result.distanceMeters, distance > 0 {
            let distanceMiles = distance * 0.000621371
            return (String(format: "%.2f", distanceMiles), "mi")
        } else if let score = result.score {
            return ("\(Int(score))%", "score")
        } else {
            return ("--", "")
        }
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Exercise icon in a circular background
            exerciseIcon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(10)
                .background(
                    Circle()
                        .fill(ThemeColor.brassGold.opacity(0.1))
                )
                .foregroundColor(ThemeColor.brassGold)
            
            // Workout details
            VStack(alignment: .leading, spacing: 4) {
                Text(result.exerciseType.capitalized)
                    .body(weight: .semibold)
                    .foregroundColor(ThemeColor.textPrimary)
                
                Text(result.startTime, formatter: Self.shortDateFormatter)
                    .small()
                    .foregroundColor(ThemeColor.textSecondary)
            }
            
            Spacer()
            
            // Performance metrics with visual styling
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(performanceMetric.value)
                    .heading3(weight: .bold, design: .rounded)
                    .monospacedDigit()
                    .foregroundColor(ThemeColor.textPrimary)
                
                Text(performanceMetric.label)
                    .small()
                    .foregroundColor(ThemeColor.textSecondary)
                    .padding(.leading, 2)
            }
            
            // Duration badge
            VStack(spacing: 2) {
                Text("Duration")
                    .caption()
                    .foregroundColor(ThemeColor.textTertiary)
                
                Text(formatDuration(result.durationSeconds))
                    .small(weight: .medium, design: .monospaced)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ThemeColor.tacticalGray.opacity(0.1))
                    )
                    .foregroundColor(ThemeColor.textSecondary)
            }
        }
        .padding(Spacing.medium)
    }
}

// Standalone preview
struct WorkoutHistoryRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for pushup workout
            WorkoutHistoryRow(
                result: WorkoutResultSwiftData(
                    exerciseType: "pushup", 
                    startTime: Date().addingTimeInterval(-86400), 
                    endTime: Date().addingTimeInterval(-86300), 
                    durationSeconds: 100, 
                    repCount: 25, 
                    score: 85
                )
            )
            .previewDisplayName("Pushup Workout")
            
            // Preview for run workout
            WorkoutHistoryRow(
                result: WorkoutResultSwiftData(
                    exerciseType: "run", 
                    startTime: Date(), 
                    endTime: Date().addingTimeInterval(3600), 
                    durationSeconds: 3600, 
                    distanceMeters: 5280
                )
            )
            .previewDisplayName("Run Workout")
            
            // Preview for dark mode
            WorkoutHistoryRow(
                result: WorkoutResultSwiftData(
                    exerciseType: "situp", 
                    startTime: Date(), 
                    endTime: Date().addingTimeInterval(600), 
                    durationSeconds: 600, 
                    repCount: 42
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(ThemeColor.cardBackground)
    }
}

// Helper extension (assuming moved to a shared location or defined here if only used here)
extension String {
    // Example helper if distance is stored in metadata JSON
    func extractDistanceMeters() -> Double? {
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let distance = json["distanceMeters"] as? Double else {
            return nil
        }
        return distance
    }
}

// Preview requires a ModelContainer setup
#Preview("Light Mode") {
    // Create an in-memory container and sample data
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

        // Add sample data using current model init
        let sampleRun = WorkoutResultSwiftData(exerciseType: "run", startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
        let samplePushups = WorkoutResultSwiftData(exerciseType: "pushup", startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-86300), durationSeconds: 100, repCount: 25, score: 85)
        let sampleSitups = WorkoutResultSwiftData(exerciseType: "situp", startTime: Date().addingTimeInterval(-172800), endTime: Date().addingTimeInterval(-172750), durationSeconds: 50, repCount: 30)

        // Insert the sample data
        container.mainContext.insert(sampleRun)
        container.mainContext.insert(samplePushups)
        container.mainContext.insert(sampleSitups)
        
        return container
    }()
    
    // Return the preview view
    return List {
        WorkoutHistoryRow(result: try! previewContainer.mainContext.fetch(FetchDescriptor<WorkoutResultSwiftData>()).first ?? WorkoutResultSwiftData(exerciseType: "fallback", startTime: Date(), endTime: Date(), durationSeconds: 0))
    }
    .modelContainer(previewContainer)
    .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    // Create an in-memory container and sample data
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

        // Add sample data
        let samplePushups = WorkoutResultSwiftData(exerciseType: "pushup", startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-86300), durationSeconds: 100, repCount: 25, score: 85)
        container.mainContext.insert(samplePushups)
        
        return container
    }()
    
    // Return the preview view
    return List {
        WorkoutHistoryRow(result: try! previewContainer.mainContext.fetch(FetchDescriptor<WorkoutResultSwiftData>()).first ?? WorkoutResultSwiftData(exerciseType: "fallback", startTime: Date(), endTime: Date(), durationSeconds: 0))
    }
    .modelContainer(previewContainer)
    .environment(\.colorScheme, .dark)
} 
