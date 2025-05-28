import SwiftUI
import PTDesignSystem

struct ExerciseSelectionView: View {
    @State private var selectedExercise: ExerciseType?
    @State private var showWorkoutView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Text("Choose Your Exercise")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        ExerciseCard(
                            exercise: .pushup,
                            icon: "figure.strengthtraining.traditional",
                            title: "Push-ups",
                            description: "Upper body strength",
                            color: .orange
                        ) {
                            selectedExercise = .pushup
                            showWorkoutView = true
                        }
                        
                        ExerciseCard(
                            exercise: .situp,
                            icon: "figure.core.training",
                            title: "Sit-ups",
                            description: "Core strength",
                            color: .green
                        ) {
                            selectedExercise = .situp
                            showWorkoutView = true
                        }
                        
                        ExerciseCard(
                            exercise: .pullup,
                            icon: "figure.climbing",
                            title: "Pull-ups",
                            description: "Back and arms",
                            color: .blue
                        ) {
                            selectedExercise = .pullup
                            showWorkoutView = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $showWorkoutView) {
                if let exercise = selectedExercise {
                    UnifiedWorkoutView(exerciseType: exercise)
                }
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: ExerciseType
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSelectionView()
} 