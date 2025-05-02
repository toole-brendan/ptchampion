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
    
    // Simple style for labels - inline instead of extension
    private func applyLabelStyle(to text: Text) -> some View {
        text.font(.subheadline)
            .foregroundColor(Color.gray)
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
                Text(result.exerciseType.capitalized) // Show exercise type
                    .font(.headline)
                    .foregroundColor(.commandBlack)
                applyLabelStyle(to: Text("\(result.startTime, formatter: Self.dateFormatter)"))
            }

            Spacer()

            VStack(alignment: .trailing) {
                 // TODO: Format duration based on timeInSeconds from SwiftData model
                 Text(formatDuration(result.durationSeconds))
                     .font(.headline)
                     .foregroundColor(.commandBlack)
                // Display reps/score or distance based on type
                if let reps = result.repCount {
                    applyLabelStyle(to: Text("\(reps) reps"))
                } else if let distance = result.distanceMeters, distance > 0 {
                     let distanceMiles = distance * 0.000621371
                     applyLabelStyle(to: Text(String(format: "%.2f mi", distanceMiles)))
                 } else if let score = result.score {
                     applyLabelStyle(to: Text("Score: \(Int(score))%"))
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
} 