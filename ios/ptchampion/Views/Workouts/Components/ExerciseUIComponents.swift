import SwiftUI
import PTDesignSystem

// MARK: - Exercise Illustration

struct ExerciseIllustration: View {
    let exerciseType: ExerciseType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(exerciseType.color.opacity(0.2))
                .frame(width: 200, height: 200)
            
            Image(systemName: exerciseType.icon)
                .font(.system(size: 80))
                .foregroundColor(exerciseType.color)
        }
    }
}

// MARK: - Exercise Position Guide

struct ExercisePositionGuide: View {
    let exerciseType: ExerciseType
    
    var body: some View {
        VStack(spacing: 15) {
            // Exercise silhouette/guide
            exerciseGuideImage
                .frame(width: 120, height: 120)
            
            Text(positionInstructions)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.6))
        )
    }
    
    @ViewBuilder
    private var exerciseGuideImage: some View {
        ZStack {
            Circle()
                .fill(exerciseType.color.opacity(0.3))
                .frame(width: 120, height: 120)
            
            Image(systemName: exerciseType.icon)
                .font(.system(size: 50))
                .foregroundColor(.white)
        }
    }
    
    private var positionInstructions: String {
        switch exerciseType {
        case .pushup:
            return "Start in plank position\nArms straight, body aligned"
        case .situp:
            return "Lie on your back\nKnees bent, hands behind head"
        case .pullup:
            return "Hang from bar\nArms fully extended"
        case .run:
            return "Stand ready to run\nComfortable running position"
        case .unknown:
            return "Position yourself for exercise"
        }
    }
}

// MARK: - Position Quality Indicator

struct PositionQualityIndicator: View {
    let confidence: Double
    let exerciseColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Position Quality")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(Int(confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(qualityColor)
                        .frame(width: geometry.size.width * confidence, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: confidence)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var qualityColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Requirement Row

struct RequirementRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
    }
}

// MARK: - Exercise Position Tips

struct ExercisePositionTips: View {
    let exerciseType: ExerciseType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(tip)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
        )
    }
    
    private var tips: [String] {
        switch exerciseType {
        case .pushup:
            return [
                "Keep your body straight",
                "Position hands shoulder-width apart",
                "Face the camera directly"
            ]
        case .situp:
            return [
                "Lie flat on your back",
                "Bend knees at 90 degrees",
                "Keep feet flat on ground"
            ]
        case .pullup:
            return [
                "Hang with arms fully extended",
                "Use overhand grip",
                "Keep body still"
            ]
        case .run:
            return [
                "Maintain good posture",
                "Keep steady pace",
                "Stay hydrated"
            ]
        case .unknown:
            return [
                "Follow exercise guidelines",
                "Maintain proper form"
            ]
        }
    }
}

// MARK: - Position Confirmed View

struct PositionConfirmedView: View {
    let exerciseType: ExerciseType
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Large checkmark animation
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(checkmarkScale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
            
            VStack(spacing: 15) {
                Text("Perfect Position!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get ready to start your \(exerciseType.displayName.lowercased())")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
}

// MARK: - Countdown View

struct CountdownView: View {
    let value: Int
    let exerciseType: ExerciseType
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(exerciseType.color.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(exerciseType.color)
                    .frame(width: 180, height: 180)
                
                Text("\(value)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            .onChange(of: value) { _, _ in
                // Animate scale change for each countdown number
                scale = 0.8
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
            
            Text("Get Ready!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Form Score View

struct FormScoreView: View {
    let score: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "star.fill")
                .foregroundColor(scoreColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Form Score")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(Int(score * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.6))
        )
        .padding(.horizontal, 20)
    }
    
    private var scoreColor: Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Rep Counter View

struct RepCounterView: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("REPS")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ExerciseIllustration(exerciseType: .pushup)
        PositionQualityIndicator(confidence: 0.75, exerciseColor: .orange)
        FormScoreView(score: 0.85, color: .orange)
    }
    .padding()
    .background(Color.black)
} 