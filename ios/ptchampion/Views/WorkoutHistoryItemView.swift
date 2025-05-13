import SwiftUI
import SwiftData

/// View for displaying a single workout history item with sync status
struct WorkoutHistoryItemView: View {
    // Workout data
    let workout: WorkoutHistory
    
    // View model reference
    @ObservedObject var viewModel: WorkoutHistoryViewModel
    
    // Optional SwiftData workout reference for sync status
    var swiftDataWorkout: WorkoutResultSwiftData?
    
    // Environment values
    @Environment(\.modelContext) private var modelContext
    
    // Computed properties for display
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
    
    private var formattedDuration: String {
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var exerciseIcon: String {
        switch workout.exerciseType {
        case "pushup": return "figure.strengthtraining.traditional"
        case "situp": return "figure.core.training"
        case "pullup": return "figure.strengthtraining.functional"
        case "run": return "figure.run"
        default: return "figure.mixed.cardio"
        }
    }
    
    private var exerciseDisplayName: String {
        switch workout.exerciseType {
        case "pushup": return "Push-ups"
        case "situp": return "Sit-ups"
        case "pullup": return "Pull-ups"
        case "run": return "Run"
        default: return workout.exerciseType.capitalized
        }
    }
    
    private var metricsText: String {
        if let reps = workout.reps {
            return "\(reps) reps"
        } else if let distance = workout.distance {
            return String(format: "%.2f miles", distance)
        } else {
            return formattedDuration
        }
    }
    
    // Sync status helpers
    private var syncStatusIcon: String {
        guard let swiftDataWorkout = swiftDataWorkout else {
            return "checkmark.circle.fill" // Default to synced if we don't have SwiftData reference
        }
        
        switch swiftDataWorkout.syncStatusEnum {
        case .synced:
            return "checkmark.circle.fill"
        case .pendingUpload:
            return "arrow.up.circle"
        case .pendingUpdate:
            return "arrow.triangle.2.circlepath"
        case .pendingDeletion:
            return "trash.circle"
        case .conflicted:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        guard let swiftDataWorkout = swiftDataWorkout else {
            return .green // Default to synced if we don't have SwiftData reference
        }
        
        switch swiftDataWorkout.syncStatusEnum {
        case .synced:
            return .green
        case .pendingUpload, .pendingUpdate, .pendingDeletion:
            return .orange
        case .conflicted:
            return .red
        }
    }
    
    private var syncStatusText: String {
        guard let swiftDataWorkout = swiftDataWorkout else {
            return "Synced" // Default to synced if we don't have SwiftData reference
        }
        
        switch swiftDataWorkout.syncStatusEnum {
        case .synced:
            return "Synced"
        case .pendingUpload:
            return "Pending Upload"
        case .pendingUpdate:
            return "Pending Update"
        case .pendingDeletion:
            return "Pending Deletion"
        case .conflicted:
            return "Conflict Detected"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Exercise icon and type
                Image(systemName: exerciseIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading) {
                    Text(exerciseDisplayName)
                        .heading4()
                    
                    Text(formattedDate)
                        .small()
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sync status indicator
                HStack(spacing: 4) {
                    Image(systemName: syncStatusIcon)
                        .foregroundColor(syncStatusColor)
                    
                    if swiftDataWorkout?.syncStatusEnum != .synced {
                        Text(syncStatusText)
                            .caption()
                            .foregroundColor(syncStatusColor)
                    }
                }
            }
            
            // Metrics row
            HStack {
                if let reps = workout.reps {
                    MetricView(label: "Reps", value: "\(reps)")
                }
                
                if let distance = workout.distance {
                    MetricView(label: "Distance", value: String(format: "%.2f mi", distance))
                }
                
                MetricView(label: "Duration", value: formattedDuration)
                
                Spacer()
                
                // Manual sync button for non-synced items
                if swiftDataWorkout?.syncStatusEnum != .synced {
                    Button {
                        // Manually trigger sync for this item
                        NotificationCenter.default.post(
                            name: .connectivityRestored,
                            object: nil
                        )
                    } label: {
                        Text("Sync")
                            .caption()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteWorkout(id: workout.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if swiftDataWorkout?.syncStatusEnum != .synced {
                Button {
                    // Manually trigger sync for this item
                    NotificationCenter.default.post(
                        name: .connectivityRestored,
                        object: nil
                    )
                } label: {
                    Label("Sync Now", systemImage: "arrow.up.circle")
                }
            }
        }
    }
}

/// Small view to display a metric with label and value
struct MetricView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .caption()
                .foregroundColor(.gray)
            
            Text(value)
                .small()
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct WorkoutHistoryItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Synced workout
            WorkoutHistoryItemView(
                workout: WorkoutHistory(
                    id: "1",
                    exerciseType: "pushup",
                    reps: 25,
                    distance: nil,
                    duration: 120,
                    date: Date().addingTimeInterval(-3600)
                ),
                viewModel: WorkoutHistoryViewModel()
            )
            .padding()
            .background(Color(.systemBackground)
            .cornerRadius(8)
            .shadow(radius: 1)
            
            // Pending upload workout
            WorkoutHistoryItemView(
                workout: WorkoutHistory(
                    id: "2",
                    exerciseType: "run",
                    reps: nil,
                    distance: 3.1,
                    duration: 1800,
                    date: Date().addingTimeInterval(-7200)
                ),
                viewModel: WorkoutHistoryViewModel(),
                swiftDataWorkout: createMockWorkout(status: .pendingUpload)
            )
            .padding()
            .background(Color(.systemBackground)
            .cornerRadius(8)
            .shadow(radius: 1)
            
            // Conflicted workout
            WorkoutHistoryItemView(
                workout: WorkoutHistory(
                    id: "3",
                    exerciseType: "situp",
                    reps: 30,
                    distance: nil,
                    duration: 180,
                    date: Date().addingTimeInterval(-10800)
                ),
                viewModel: WorkoutHistoryViewModel(),
                swiftDataWorkout: createMockWorkout(status: .conflicted)
            )
            .padding()
            .background(Color(.systemBackground)
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .padding()
        .background(Color(.systemGroupedBackground)
        .previewLayout(.sizeThatFits)
    }
    
    // Helper to create mock workout with specified sync status
    static func createMockWorkout(status: SyncStatus) -> WorkoutResultSwiftData {
        let workout = WorkoutResultSwiftData(
            exerciseType: "run",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            durationSeconds: 1800,
            isPublic: false
        )
        workout.syncStatusEnum = status
        return workout
    }
} 