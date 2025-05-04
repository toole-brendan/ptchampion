import SwiftUI
import SwiftData
import PTDesignSystem

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    // Query for all workout results, sorted by start time descending
    @Query(sort: [SortDescriptor<WorkoutResultSwiftData>(\WorkoutResultSwiftData.startTime, order: .reverse)])
    private var workoutResults: [WorkoutResultSwiftData]

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.GeneratedColors.background.ignoresSafeArea()
                
                List {
                    if workoutResults.isEmpty {
                        ContentUnavailableView(
                            "No Workouts Yet",
                            systemImage: "figure.run.circle",
                            description: Text("Complete a workout to see your history here.")
                                .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body))
                                .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                        )
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                    } else {
                        ForEach(workoutResults) { result in
                            WorkoutHistoryRow(result: result)
                        }
                        .onDelete(perform: deleteWorkout)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 // Add EditButton to enable swipe-to-delete
                 EditButton()
                    .tint(AppTheme.GeneratedColors.brassGold)
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

// Helper function to create a container with sample data for previews
@MainActor
private func createSampleDataContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: WorkoutResultSwiftData.self, configurations: config)

        // Add sample data
        let sampleRun = WorkoutResultSwiftData(exerciseType: "run", startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
        let samplePushups = WorkoutResultSwiftData(exerciseType: "pushup", startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-86300), durationSeconds: 100, repCount: 25, score: 85.0)
        let sampleSitups = WorkoutResultSwiftData(exerciseType: "situp", startTime: Date().addingTimeInterval(-172800), endTime: Date().addingTimeInterval(-172750), durationSeconds: 50, repCount: 30)

        container.mainContext.insert(sampleRun)
        container.mainContext.insert(samplePushups)
        container.mainContext.insert(sampleSitups)
        
        return container
    } catch {
        fatalError("Failed to create sample data container: \(error)")
    }
}

// Preview using the helper function
#Preview("Light Mode") {
    WorkoutHistoryView()
        .modelContainer(createSampleDataContainer())
        .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    WorkoutHistoryView()
        .modelContainer(createSampleDataContainer())
        .environment(\.colorScheme, .dark)
}

// Example Row Preview (Doesn't need a container)
#Preview("Workout Row") {
     let sampleRun = WorkoutResultSwiftData(exerciseType: "run", startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-100), durationSeconds: 2600, distanceMeters: 5012.5)
    WorkoutHistoryRow(result: sampleRun)
        .padding(AppTheme.GeneratedSpacing.contentPadding)
        .background(AppTheme.GeneratedColors.cardBackground)
        .cornerRadius(AppTheme.GeneratedRadius.card)
} 