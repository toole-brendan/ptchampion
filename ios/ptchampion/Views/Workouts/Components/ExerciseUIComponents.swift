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
    @State private var ringScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Full screen green gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Large animated checkmark
                ZStack {
                    // Outer animated ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 15)
                        .frame(width: 250, height: 250)
                        .scaleEffect(ringScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                ringScale = 1.1
                            }
                        }
                    
                    // Main checkmark circle
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 220, height: 220)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
                .scaleEffect(checkmarkScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        checkmarkScale = 1.0
                    }
                }
                
                VStack(spacing: 20) {
                    Text("PERFECT!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text("Starting soon...")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Countdown View

struct CountdownView: View {
    let value: Int
    let exerciseType: ExerciseType
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Full screen gradient background
            LinearGradient(
                gradient: Gradient(colors: [exerciseType.color.opacity(0.8), exerciseType.color.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // Huge countdown number
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 20)
                        .frame(width: 300, height: 300)
                    
                    // Inner filled circle
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 280, height: 280)
                    
                    // The countdown number
                    Text("\(value)")
                        .font(.system(size: 180, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 20)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
                .onChange(of: value) { _, _ in
                    // Pulse animation for each countdown change
                    scale = 0.7
                    opacity = 0.7
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.1
                        opacity = 1.0
                    }
                    
                    // Return to normal size
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            scale = 1.0
                        }
                    }
                }
                
                // Large "Get Ready!" text
                Text(value == 1 ? "GET SET!" : "GET READY!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .shadow(radius: 10)
                
                Spacer()
                Spacer()
            }
        }
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