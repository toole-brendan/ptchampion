import SwiftUI
import SwiftData

// Helper Row View for displaying a single workout result
struct WorkoutHistoryRow: View {
    let result: WorkoutResultSwiftData

    // Formatter for date
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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

    var body: some View {
        HStack {
            // TODO: Replace placeholder icon logic with actual Exercise lookup if needed
            Image(systemName: "figure.run") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .foregroundColor(.brassGold)
                .padding(.trailing, 8)

            VStack(alignment: .leading) {
                 // TODO: Display actual exercise name
                Text(result.exerciseId.description) // Placeholder - Show Exercise Name
                    .font(.headline)
                    .foregroundColor(.commandBlack)
                Text("\(result.createdAt, formatter: Self.dateFormatter)") // Use createdAt from SwiftData model
                    .labelStyle()
            }

            Spacer()

            VStack(alignment: .trailing) {
                 // TODO: Format duration based on timeInSeconds from SwiftData model
                 Text(formatDuration(result.timeInSeconds))
                     .font(.headline)
                     .foregroundColor(.commandBlack)
                // Display reps/score or distance based on type
                if let reps = result.repetitions {
                    Text("\(reps) reps")
                        .labelStyle()
                } else if let distance = result.metadata?.extractDistanceMeters(), distance > 0 { // Example: Extract from metadata
                     let distanceMiles = distance * 0.000621371
                     Text(String(format: "%.2f mi", distanceMiles))
                         .labelStyle()
                 } else if let score = result.formScore {
                     Text("Score: \(score)%") // Use formScore
                        .labelStyle()
                 }
            }
        }
        .padding(.vertical, 6)
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
#Preview {
    // Create an in-memory container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

    // Add sample data (adjust based on WorkoutResultSwiftData initializer)
    let sampleRun = WorkoutResultSwiftData(userId: 1, exerciseId: 4, timeInSeconds: 2600, completed: true, metadata: "{\"distanceMeters\": 5012.5}", createdAt: Date().addingTimeInterval(-3600))
    let samplePushups = WorkoutResultSwiftData(userId: 1, exerciseId: 1, repetitions: 25, formScore: 85, timeInSeconds: 100, completed: true, createdAt: Date().addingTimeInterval(-86400))
    let sampleSitups = WorkoutResultSwiftData(userId: 1, exerciseId: 2, repetitions: 30, timeInSeconds: 50, completed: true, createdAt: Date().addingTimeInterval(-172800))

    container.mainContext.insert(sampleRun)
    container.mainContext.insert(samplePushups)
    container.mainContext.insert(sampleSitups)

    // Return the Row within a List for context
    return List {
        WorkoutHistoryRow(result: sampleRun)
        WorkoutHistoryRow(result: samplePushups)
        WorkoutHistoryRow(result: sampleSitups)
    }
    .modelContainer(container)
} 