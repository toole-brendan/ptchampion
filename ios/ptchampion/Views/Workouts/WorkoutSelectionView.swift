import SwiftUI
import PTDesignSystem

struct WorkoutSelectionView: View {
    // TODO: Add ViewModel for workout logic

    // Example list of exercises
    struct Exercise: Identifiable {
        let id = UUID()
        let name: String // Display name
        let rawValue: String // Raw value for enum/storage
        let description: String
        let iconName: String // System icon name for example
    }

    let exercises = [
        Exercise(name: "Push-ups", rawValue: "pushup", description: "Upper body strength", iconName: "pushup"),
        Exercise(name: "Sit-ups", rawValue: "situp", description: "Core strength", iconName: "situp"),
        Exercise(name: "Pull-ups", rawValue: "pullup", description: "Back and bicep strength", iconName: "pullup"),
        Exercise(name: "Run", rawValue: "run", description: "Cardiovascular endurance", iconName: "running")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: PTLabel("Choose Your Exercise", style: .subheading)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)) {
                    ForEach(exercises) { exercise in
                        // Conditional Navigation
                        if exercise.name == "Run" {
                            NavigationLink(destination: RunWorkoutView()) {
                                ExerciseRow(exercise: exercise)
                            }
                        } else {
                            // Use existing WorkoutSessionView for pose-based exercises
                            NavigationLink(destination: WorkoutSessionView(exerciseName: exercise.rawValue)) {
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle()) // Use PlainListStyle for flatter look closer to Android?
            .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extracted Row View for reusability
struct ExerciseRow: View {
    let exercise: WorkoutSelectionView.Exercise

    var body: some View {
        HStack {
            Image(exercise.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(AppTheme.GeneratedColors.primary)
                .padding(.trailing, AppTheme.GeneratedSpacing.small)
            VStack(alignment: .leading) {
                PTLabel(exercise.name, style: .subheading)
                    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                PTLabel(exercise.description, style: .caption)
                    .foregroundColor(AppTheme.GeneratedColors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.small)
    }
}

// Placeholder for the actual workout session view
// struct WorkoutSessionView: View { // Remove old placeholder
//     let exerciseName: String
//     var body: some View {
//         Text("Starting \(exerciseName) Session...")
//             .navigationTitle(exerciseName)
//             // This view will contain the camera feed, pose detection, etc.
//     }
// }

#Preview("Light Mode") {
    WorkoutSelectionView()
        .environment(\.colorScheme, .light) // Preview in light mode
}

#Preview("Dark Mode") {
    WorkoutSelectionView()
        .environment(\.colorScheme, .dark) // Preview in dark mode
} 