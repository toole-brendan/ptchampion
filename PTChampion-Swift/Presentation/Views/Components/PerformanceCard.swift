import SwiftUI

struct PerformanceCard: View {
    let latestExercises: [String: UserExercise]?
    let overallScore: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Overall Performance")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let pushupDate = latestExercises?["pushup"]?.createdAt {
                    Text("Last updated: \(formatDate(pushupDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Overall score
            HStack(alignment: .center, spacing: 15) {
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10)
                        .opacity(0.3)
                        .foregroundColor(.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(Double(overallScore) / 100, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                    
                    VStack(spacing: 2) {
                        Text("\(overallScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                
                Spacer()
                
                // Rating
                VStack(alignment: .leading, spacing: 5) {
                    Text("Rating")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(ratingText(for: overallScore))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ratingColor(for: overallScore))
                    
                    Text(ratingDescription(for: overallScore))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Divider()
            
            // Individual exercise scores
            VStack(spacing: 12) {
                Text("Exercise Breakdown")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    exerciseScoreRow(for: type)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func exerciseScoreRow(for type: ExerciseType) -> some View {
        let userExercise = latestExercises?[type.rawValue]
        
        return HStack {
            // Exercise icon
            Image(systemName: type.iconName)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Exercise name
            Text(type.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Score
            if let grade = userExercise?.grade {
                Text("\(grade)/100")
                    .font(.subheadline)
                    .foregroundColor(scoreColor(for: grade))
            } else {
                Text("Not tested")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func ratingText(for score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent"
        case 75..<90:
            return "Good"
        case 60..<75:
            return "Satisfactory"
        case 40..<60:
            return "Marginal"
        default:
            return "Poor"
        }
    }
    
    private func ratingDescription(for score: Int) -> String {
        switch score {
        case 90...100:
            return "Outstanding performance, exceeding standards"
        case 75..<90:
            return "Above average performance, meeting standards comfortably"
        case 60..<75:
            return "Meets minimum standards, but needs improvement"
        case 40..<60:
            return "Below standards, requires significant improvement"
        default:
            return "Well below standards, requires immediate attention"
        }
    }
    
    private func ratingColor(for score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
    
    private func scoreColor(for grade: Int) -> Color {
        switch grade {
        case 90...100:
            return .green
        case 75..<90:
            return .blue
        case 60..<75:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
}

// Preview
struct PerformanceCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockExercises: [String: UserExercise] = [
            "pushup": UserExercise(
                id: 1, userId: 1, exerciseId: 1,
                repetitions: 42, formScore: 85, grade: 75,
                completed: true, createdAt: Date()
            ),
            "situp": UserExercise(
                id: 2, userId: 1, exerciseId: 2,
                repetitions: 58, formScore: 90, grade: 80,
                completed: true, createdAt: Date().addingTimeInterval(-86400)
            ),
            "pullup": UserExercise(
                id: 3, userId: 1, exerciseId: 3,
                repetitions: 12, formScore: 75, grade: 65,
                completed: true, createdAt: Date().addingTimeInterval(-172800)
            ),
            "run": UserExercise(
                id: 4, userId: 1, exerciseId: 4,
                timeInSeconds: 900, grade: 70,
                completed: true, createdAt: Date().addingTimeInterval(-259200)
            )
        ]
        
        return PerformanceCard(latestExercises: mockExercises, overallScore: 72)
            .padding()
            .background(Color(.systemGroupedBackground))
            .previewLayout(.sizeThatFits)
    }
}