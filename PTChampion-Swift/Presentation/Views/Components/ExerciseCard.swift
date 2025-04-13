import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    let latestScore: UserExercise?
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and title
                HStack {
                    Image(systemName: exercise.type.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(exercise.goal)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                // Description
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Latest score (if available)
                if let latestScore = latestScore {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Latest Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            displayScore(for: latestScore)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Grade")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            displayGrade(for: latestScore)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func displayScore(for userExercise: UserExercise) -> some View {
        let score: String
        
        switch exercise.type {
        case .pushup, .situp, .pullup:
            score = "\(userExercise.repetitions ?? 0) reps"
        case .run:
            if let seconds = userExercise.timeInSeconds {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                score = "\(minutes):\(String(format: "%02d", remainingSeconds))"
            } else {
                score = "N/A"
            }
        }
        
        return Text(score)
    }
    
    private func displayGrade(for userExercise: UserExercise) -> some View {
        if let grade = userExercise.grade {
            let scoreColor: Color
            
            if grade >= 90 {
                scoreColor = .green
            } else if grade >= 70 {
                scoreColor = .blue
            } else if grade >= 50 {
                scoreColor = .orange
            } else {
                scoreColor = .red
            }
            
            return Text("\(grade)/100")
                .font(.subheadline)
                .foregroundColor(scoreColor)
        } else {
            return Text("Not graded")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
struct ExerciseCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // With score
            ExerciseCard(
                exercise: Exercise(
                    id: 1,
                    name: "Push-ups",
                    description: "Upper body exercise to build chest, shoulder, and arm strength.",
                    type: .pushup,
                    imageUrl: nil
                ),
                latestScore: UserExercise(
                    id: 1,
                    userId: 1,
                    exerciseId: 1,
                    repetitions: 42,
                    formScore: 85,
                    timeInSeconds: nil,
                    grade: 75,
                    completed: true,
                    metadata: nil,
                    createdAt: Date()
                ),
                onTap: {}
            )
            
            // Without score
            ExerciseCard(
                exercise: Exercise(
                    id: 4,
                    name: "2-Mile Run",
                    description: "Cardio exercise measuring endurance and aerobic fitness.",
                    type: .run,
                    imageUrl: nil
                ),
                latestScore: nil,
                onTap: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}