import SwiftUI

struct WorkoutSelectionView: View {
    // TODO: Add ViewModel for workout logic

    // Example list of exercises
    struct Exercise: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let iconName: String // System icon name for example
    }

    let exercises = [
        Exercise(name: "Push-ups", description: "Upper body strength", iconName: "figure.strengthtraining.traditional"),
        Exercise(name: "Sit-ups", description: "Core strength", iconName: "figure.core.training"),
        Exercise(name: "Pull-ups", description: "Back and bicep strength", iconName: "figure.arms.open"), // Use valid system icon
        Exercise(name: "Run", description: "Cardiovascular endurance", iconName: "figure.run")
    ]
    
    // Helper function to apply styling directly
    private func subheadingStyle(text: Text) -> some View {
        text.font(AppTheme.GeneratedTypography.subheading())
            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: subheadingStyle(text: Text("Choose Your Exercise"))) {
                    ForEach(exercises) { exercise in
                        // Conditional Navigation
                        if exercise.name == "Run" {
                            NavigationLink(destination: RunWorkoutView()) {
                                ExerciseRow(exercise: exercise)
                            }
                        } else {
                            // Use existing WorkoutSessionView for pose-based exercises
                            NavigationLink(destination: WorkoutSessionView(exerciseName: exercise.name)) {
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle()) // Use PlainListStyle for flatter look closer to Android?
            .background(AppTheme.GeneratedColors.cream.ignoresSafeArea())
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extracted Row View for reusability
struct ExerciseRow: View {
    let exercise: WorkoutSelectionView.Exercise
    
    // Helper function to apply styling directly
    private func applyLabelStyle(to text: Text) -> some View {
        text.font(AppTheme.GeneratedTypography.caption())
            .foregroundColor(AppTheme.GeneratedColors.textSecondary)
    }

    var body: some View {
        HStack {
            Image(systemName: exercise.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .padding(.trailing, AppTheme.GeneratedSpacing.itemSpacing)
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(AppTheme.GeneratedTypography.subheading())
                    .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                applyLabelStyle(to: Text(exercise.description))
            }
        }
        .padding(.vertical, AppTheme.GeneratedSpacing.itemSpacing)
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

#Preview {
    WorkoutSelectionView()
        .environment(\.colorScheme, .light) // Preview in light mode
        .previewDisplayName("Light Mode")
}

#Preview {
    WorkoutSelectionView()
        .environment(\.colorScheme, .dark) // Preview in dark mode
        .previewDisplayName("Dark Mode")
} 