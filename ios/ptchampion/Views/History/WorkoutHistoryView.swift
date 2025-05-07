import SwiftUI
import SwiftData
import PTDesignSystem
import Foundation

enum WorkoutFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pushup = "Push-Ups"
    case situp = "Sit-Ups"
    case pullup = "Pull-Ups"
    case run = "Run"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .all: return "figure.run.circle.fill"
        case .pushup: return "figure.strengthtraining.traditional"
        case .situp: return "figure.core.training"
        case .pullup: return "figure.strengthtraining.upper.body"
        case .run: return "figure.run"
        }
    }
    
    // Convert to exercise type string used in database
    var exerciseTypeString: String? {
        switch self {
        case .all: return nil
        case .pushup: return "pushup"
        case .situp: return "situp"
        case .pullup: return "pullup"
        case .run: return "run"
        }
    }
}

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    // Query for all workout results, sorted by start time descending
    @Query(sort: [SortDescriptor<WorkoutResultSwiftData>(\WorkoutResultSwiftData.startTime, order: .reverse)])
    private var allWorkoutResults: [WorkoutResultSwiftData]
    
    @State private var filter: WorkoutFilter = .all
    @State private var isShowingShareSheet = false
    @State private var shareText = ""

    // Filter workout results based on selected filter
    private var workoutResults: [WorkoutResultSwiftData] {
        if filter == .all {
            return allWorkoutResults
        } else {
            return allWorkoutResults.filter { $0.exerciseType == filter.exerciseTypeString }
        }
    }
    
    // Prepare chart data using the shared WorkoutDataPoint model
    private var chartData: [WorkoutDataPoint] {
        // If filter is .all, return empty data as metrics are too varied for a single chart
        guard filter != .all else { return [] }

        let filteredResults = workoutResults // Already filtered by exercise type (unless .all)
        
        return filteredResults.prefix(30) // Show more data points, e.g., last 30
            .compactMap { result -> WorkoutDataPoint? in
                let date = result.startTime
                var value: Double?
                
                switch filter {
                case .run:
                    if let distance = result.distanceMeters, distance > 0 {
                        // Potentially convert to preferred unit (e.g., km or miles) if stored consistently as meters
                        value = distance / 1000 // Example: convert meters to km
                    }
                case .pushup, .situp, .pullup:
                    if let score = result.score, score > 0 { // Prioritize score
                        value = score
                    } else if let reps = result.repCount, reps > 0 {
                        value = Double(reps)
                    }
                default: // .all is handled above, this case shouldn't be hit for chartData
                    return nil
                }
                
                if let val = value {
                    return WorkoutDataPoint(date: date, value: val)
                }
                return nil
            }
            .sorted { $0.date < $1.date } // Sort by date ascending for chart
    }
    
    private var yAxisChartLabel: String { // <-- ADDED helper for Y-Axis label
        switch filter {
        case .all:
            return "N/A" // No chart shown for .all
        case .run:
            return "Distance (km)" // Assuming km for now
        case .pushup, .situp, .pullup:
            // This is a bit tricky if we mix score and reps. 
            // For simplicity, if the chart can show either, we might need a more dynamic label
            // or decide on one primary metric if filter is specific.
            // Let's assume if we are plotting scores, we label it Score, else Reps.
            // This requires chartData to be consistent for that filter.
            // Based on current chartData logic: if pushups/situps/pullups have scores, it plots score, else reps.
            // We can check if the first item in chartData came from a score or rep to decide the label.
            if let firstDataPoint = chartData.first,
               let correspondingResult = workoutResults.first(where: { $0.startTime == firstDataPoint.date }) {
                if correspondingResult.score != nil && correspondingResult.score! > 0 {
                    return "Score"
                }
            }
            return "Reps"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.GeneratedColors.background.ignoresSafeArea()
                
                VStack(spacing: AppTheme.GeneratedSpacing.contentPadding) {
                    // 4-9: Filters / Segmented Control
                    Picker("Filter", selection: $filter) {
                        ForEach(WorkoutFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    
                    // Workout history list
                    List {
                        if workoutResults.isEmpty {
                            // 4-12: Empty State Improvements
                            ContentUnavailableView(
                                "No \(filter == .all ? "Workouts" : filter.rawValue) Yet",
                                systemImage: filter.systemImage,
                                description: Text("Complete a workout to see your history here.")
                                    .font(AppTheme.GeneratedTypography.body(size: AppTheme.GeneratedTypography.body))
                                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
                            )
                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        } else {
                            ForEach(workoutResults) { result in
                                // 4-8: History List Polish
                                WorkoutHistoryRow(result: result)
                                    .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteWorkout(result: result)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            shareWorkout(result: result)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                        .tint(AppTheme.GeneratedColors.brassGold)
                                    }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    
                    // 4-10: Progress Analytics
                    if !workoutResults.isEmpty && filter != .all { // <-- MODIFIED: Don't show chart for .all
                        WorkoutProgressChart(
                            dataPoints: chartData,
                            title: "Progress Over Time - \(filter.rawValue)", // <-- MODIFIED: More specific title
                            yAxisLabel: yAxisChartLabel // <-- MODIFIED
                        )
                        .padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)
                    }
                }
                .sheet(isPresented: $isShowingShareSheet) {
                    ActivityView(activityItems: [shareText])
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
                    .tint(AppTheme.GeneratedColors.brassGold)
            }
        }
    }

    // Function to delete a specific workout result
    private func deleteWorkout(result: WorkoutResultSwiftData) {
        modelContext.delete(result)
    }
    
    // Old function to delete workout by offset (keeping for compatibility)
    private func deleteWorkout(at offsets: IndexSet) {
        offsets.forEach { index in
            let resultToDelete = workoutResults[index]
            modelContext.delete(resultToDelete)
        }
    }
    
    // Share workout function
    private func shareWorkout(result: WorkoutResultSwiftData) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var text = "PT Champion Workout: \(result.exerciseType.capitalized)\n"
        text += "Date: \(formatter.string(from: result.startTime))\n"
        text += "Duration: \(formatDuration(result.durationSeconds))\n"
        
        if let reps = result.repCount {
            text += "Reps: \(reps)\n"
        }
        
        if let score = result.score {
            text += "Score: \(Int(score))%\n"
        }
        
        if let distance = result.distanceMeters {
            let distanceMiles = distance * 0.000621371
            text += "Distance: \(String(format: "%.2f mi", distanceMiles))\n"
        }
        
        shareText = text
        isShowingShareSheet = true
    }
    
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