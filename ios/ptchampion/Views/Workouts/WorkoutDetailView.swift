import SwiftUI
import PTDesignSystem

struct WorkoutDetailView: View {
    let exerciseType: ExerciseType
    
    var body: some View {
        VStack {
            PTLabel("\(exerciseType.displayName) Workout", style: .heading)
                .padding()
            
            PTLabel("This is a placeholder for the \(exerciseType.displayName) workout screen", style: .body)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
        .background(AppTheme.GeneratedColors.background.ignoresSafeArea())
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(exerciseType: .pushup)
    }
} 