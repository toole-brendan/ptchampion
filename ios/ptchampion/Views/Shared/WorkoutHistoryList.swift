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
            if viewModel.workoutsFiltered.isEmpty {
                ContentUnavailableView(
                    emptyStateMessage,
                    systemImage: "figure.run.circle",
                    description: Text("Complete a workout to see your history here.")
                )
                .listRowBackground(ThemeColor.clear)
            } else {
                ForEach(Array(viewModel.workoutsFiltered.enumerated(), id: \.element.id) { index, workout in
                    VStack {
                        HStack {
                            WorkoutHistoryRowAdapter(workout: workout)
                                .contentShape(Rectangle()
                                .onTapGesture {
                                    if !isEditable {
                                        onSelect?(workout)
                                    }
                                }
                            
                            if isEditable {
                                Spacer()
                                
                                HStack(spacing: Spacing.small) {
                                    Button {
                                        // TODO: Add share functionality if needed
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .body(weight: .medium)
                                            .foregroundColor(ThemeColor.brassGold)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(ThemeColor.brassGold.opacity(0.1)
                                            )
                                    }
                                    
                                    Button {
                                        Task {
                                            await viewModel.deleteWorkout(id: workout.id)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .body(weight: .medium)
                                            .foregroundColor(ThemeColor.error)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(ThemeColor.error.opacity(0.1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(Spacing.small)
                    }
                    .card(variant: isEditable ? .interactive : .default)
                    .padding(.horizontal, Spacing.contentPadding)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isEditable {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteWorkout(id: workout.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                // TODO: Add share functionality if needed
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(ThemeColor.brassGold)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshWorkouts()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle()
                    .scaleEffect(1.5)
                    .tint(ThemeColor.brassGold)
            }
        }
    }
    
    private func handleDelete(at offsets: IndexSet) {
        if let onDelete = onDelete {
            onDelete(offsets)
        } else {
            // Default implementation if no external handler provided
            Task {
                for index in offsets {
                    if index < viewModel.workoutsFiltered.count {
                        let workout = viewModel.workoutsFiltered[index]
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
            score: workout.score,
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