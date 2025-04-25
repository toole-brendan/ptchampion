import SwiftUI
import SwiftData

/// A reusable component for displaying a list of workout history items
struct WorkoutHistoryList: View {
    // State
    @ObservedObject var viewModel: WorkoutHistoryViewModel
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
                    WorkoutHistoryRow(workout: workout)
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
                Spinner(size: .large, variant: .primary)
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

/// Individual row for a workout history item
struct WorkoutHistoryRow: View {
    let workout: WorkoutHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            // Exercise type and date
            HStack {
                Text(workout.exerciseType.capitalized)
                    .font(.custom(AppFonts.subheading, size: AppConstants.FontSize.md))
                    .foregroundColor(.commandBlack)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                    .foregroundColor(.tacticalGray)
            }
            
            // Metrics
            HStack(spacing: AppConstants.Spacing.xl) {
                // Display different metrics based on exercise type
                if let reps = workout.reps {
                    metricView(value: "\(reps)", unit: "reps", icon: "figure.strengthtraining.traditional")
                }
                
                if let distance = workout.distance {
                    metricView(value: String(format: "%.1f", distance), unit: "km", icon: "figure.run")
                }
                
                metricView(value: formattedDuration, unit: "", icon: "clock")
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.white)
        .cornerRadius(AppConstants.Radius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.vertical, AppConstants.Spacing.xs)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workout.date)
    }
    
    private var formattedDuration: String {
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func metricView(value: String, unit: String, icon: String) -> some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(.brassGold)
                .frame(width: 16, height: 16)
            
            Text(value)
                .font(.custom(AppFonts.mono, size: AppConstants.FontSize.md))
                .foregroundColor(.commandBlack)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.custom(AppFonts.body, size: AppConstants.FontSize.sm))
                    .foregroundColor(.tacticalGray)
            }
        }
    }
}

// MARK: - Preview
struct WorkoutHistoryList_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutHistoryList(viewModel: mockViewModel())
            .padding()
            .preferredColorScheme(.light)
            .previewDisplayName("History List")
        
        WorkoutHistoryRow(workout: sampleWorkout())
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("History Row")
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