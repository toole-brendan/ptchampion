import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    // Query for all workout results, sorted by start time descending
    @Query(sort: [SortDescriptor<WorkoutResultSwiftData>(\WorkoutResultSwiftData.startTime, order: .reverse)])
    private var workoutResults: [WorkoutResultSwiftData]

    var body: some View {
        NavigationView {
            List {
                if workoutResults.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "figure.run.circle",
                        description: Text("Complete a workout to see your history here.")
                    )
                } else {
                    ForEach(workoutResults) { result in
                        WorkoutHistoryRow(result: result)
                    }
                    .onDelete(perform: deleteWorkout)
                }
            }
            .navigationTitle("Workout History")
            .toolbar {
                 // Add EditButton to enable swipe-to-delete
                 EditButton()
            }
        }
    }

    // Function to delete workout results from SwiftData
    private func deleteWorkout(at offsets: IndexSet) {
        offsets.forEach { index in
            let resultToDelete = workoutResults[index]
            modelContext.delete(resultToDelete)
        }
        // Try saving the context after deletion (optional, often autosaves)
        // do {
        //     try modelContext.save()
        // } catch {
        //     print("Error saving context after deletion: \(error)")
        // }
    }
}

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
            Image(systemName: result.exercise?.iconName ?? "questionmark.circle.fill") // Use computed property
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .foregroundColor(.brassGold)
                .padding(.trailing, 8)

            VStack(alignment: .leading) {
                Text(result.exercise?.displayName ?? result.exerciseType)
                    .font(.headline)
                    .foregroundColor(.commandBlack)
                Text("\(result.startTime, formatter: Self.dateFormatter)")
                    .labelStyle()
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(formatDuration(result.durationSeconds))
                     .font(.headline)
                     .foregroundColor(.commandBlack)
                // Display reps/score or distance based on type
                if let reps = result.repCount {
                    Text("\(reps) reps")
                        .labelStyle()
                } else if let distance = result.distanceMeters, distance > 0 {
                     let distanceMiles = distance * 0.000621371
                     Text(String(format: "%.2f mi", distanceMiles))
                         .labelStyle()
                 } else if let score = result.score {
                     Text("Score: \(Int(score))%")
                        .labelStyle()
                 }
            }
        }
        .padding(.vertical, 6)
    }
}

// Preview with sample data
#Preview {
    // Create an in-memory container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

    // Add sample data
    let sampleRun = WorkoutResultSwiftData(exerciseType: ExerciseType.run.rawValue, startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
    let samplePushups = WorkoutResultSwiftData(exerciseType: ExerciseType.pushups.rawValue, startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-86300), durationSeconds: 100, repCount: 25, score: 85.0)
    let sampleSitups = WorkoutResultSwiftData(exerciseType: ExerciseType.situps.rawValue, startTime: Date().addingTimeInterval(-172800), endTime: Date().addingTimeInterval(-172750), durationSeconds: 50, repCount: 30)

    container.mainContext.insert(sampleRun)
    container.mainContext.insert(samplePushups)
    container.mainContext.insert(sampleSitups)

    return WorkoutHistoryView()
        .modelContainer(container)
} 