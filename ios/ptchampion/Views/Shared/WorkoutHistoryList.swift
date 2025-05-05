import SwiftUI
import SwiftData
import PTDesignSystem

/// A reusable component for displaying a list of workout history items
struct WorkoutHistoryList: View {
    // State - use direct property since WorkoutHistoryViewModel uses @Observable
    var viewModel: WorkoutHistoryViewModel
    let onDelete: ((IndexSet) -> Void)?
    let onSelect: ((WorkoutHistory) -> Void)?
    let isEditable: Bool
    let emptyStateMessage: String
    
    /// Default initializer
    init(
        viewModel: WorkoutHistoryViewModel,
        onDelete: ((IndexSet) -> Void)? = nil,
        onSelect: ((WorkoutHistory) -> Void)? = nil,
        isEditable: Bool = true,
        emptyStateMessage: String = "No Workouts Yet"
    ) {
        self.viewModel = viewModel
        self.onDelete = onDelete
        self.onSelect = onSelect
        self.isEditable = isEditable
        self.emptyStateMessage = emptyStateMessage
    }
    
    var body: some View {
        List {
            if viewModel.workouts.isEmpty {
                ContentUnavailableView(
                    emptyStateMessage,
                    systemImage: "figure.run.circle",
                    description: Text("Complete a workout to see your history here.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.workouts) { workout in
                    WorkoutHistoryRowAdapter(workout: workout)
                        .contentShape(Rectangle()) // Make the entire row tappable
                        .onTapGesture {
                            onSelect?(workout)
                        }
                }
                .onDelete(perform: handleDelete)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshWorkouts()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .tint(AppTheme.GeneratedColors.brassGold)
            }
        }
        .task {
            await viewModel.fetchWorkouts()
        }
    }
    
    private func handleDelete(at offsets: IndexSet) {
        if let onDelete = onDelete {
            onDelete(offsets)
        } else {
            // Default implementation if no external handler provided
            Task {
                for index in offsets {
                    if index < viewModel.workouts.count {
                        let workout = viewModel.workouts[index]
                        await viewModel.deleteWorkout(id: workout.id)
                    }
                }
            }
        }
    }
}

// Adapter to convert WorkoutHistory to WorkoutResultSwiftData for use with the existing WorkoutHistoryRow
struct WorkoutHistoryRowAdapter: View {
    let workout: WorkoutHistory
    
    var body: some View {
        // Create a pseudo WorkoutResultSwiftData for display purposes
        let workoutResult = createWorkoutResult()
        WorkoutHistoryRow(result: workoutResult)
    }
    
    private func createWorkoutResult() -> WorkoutResultSwiftData {
        let workoutResult = WorkoutResultSwiftData(
            exerciseType: workout.exerciseType,
            startTime: workout.date,
            endTime: workout.date.addingTimeInterval(workout.duration),
            durationSeconds: Int(workout.duration),
            repCount: workout.reps,
            distanceMeters: workout.distance
        )
        return workoutResult
    }
}

// MARK: - Preview
struct WorkoutHistoryList_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutHistoryList(viewModel: mockViewModel())
            .padding()
            .preferredColorScheme(.light)
            .previewDisplayName("History List")
    }
    
    // Helper to create sample data
    static func mockViewModel() -> WorkoutHistoryViewModel {
        let viewModel = WorkoutHistoryViewModel()
        viewModel.workouts = [
            sampleWorkout(),
            WorkoutHistory(
                id: "2",
                exerciseType: "situp",
                reps: 30,
                distance: nil,
                duration: 120,
                date: Date().addingTimeInterval(-172800)
            ),
            WorkoutHistory(
                id: "3",
                exerciseType: "running",
                reps: nil,
                distance: 5.0,
                duration: 1800,
                date: Date().addingTimeInterval(-259200)
            )
        ]
        return viewModel
    }
    
    static func sampleWorkout() -> WorkoutHistory {
        WorkoutHistory(
            id: "1",
            exerciseType: "pushup",
            reps: 25,
            distance: nil,
            duration: 60,
            date: Date().addingTimeInterval(-86400)
        )
    }
} 