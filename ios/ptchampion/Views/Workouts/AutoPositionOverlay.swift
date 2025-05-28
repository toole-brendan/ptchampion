import SwiftUI
import PTDesignSystem

/// Enhanced overlay that provides the "Just Press GO" experience with automatic position detection
struct AutoPositionOverlay: View {
    // TODO: Re-enable AutoPositionDetector once module compilation issues are resolved
    // @ObservedObject var autoPositionDetector: AutoPositionDetector
    let workoutState: WorkoutSessionState
    let positionHoldProgress: Float
    let countdownValue: Int?
    let onStartPressed: () -> Void
    
    // Add exercise type to know which PNG to show
    let exerciseType: ExerciseType
    
    // Control PNG visibility based on state
    private var showPNGOverlay: Bool {
        switch workoutState {
        case .waitingForPosition, .positionDetected:
            return true
        default:
            return false
        }
    }
    
    // Animate PNG opacity
    private var pngOpacity: Double {
        switch workoutState {
        case .waitingForPosition:
            return 0.4 // Semi-transparent while positioning
        case .positionDetected:
            return 0.2 // Fade out when detected
        default:
            return 0.0
        }
    }
    
    // Temporary placeholder properties to replace AutoPositionDetector
    @State private var primaryInstruction: String = "Get into starting position"
    @State private var positionQuality: Float = 0.0
    @State private var missingRequirements: [String] = []
    @State private var detectedExercise: ExerciseType? = nil
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // PNG Overlay (behind UI elements)
            if showPNGOverlay {
                PNGOverlayView(
                    exerciseType: exerciseType,
                    opacity: pngOpacity
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: showPNGOverlay)
            }
            
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                // Main content based on state
                Group {
                    switch workoutState {
                    case .ready:
                        readyStateContent
                    case .waitingForPosition:
                        waitingForPositionContent
                    case .positionDetected:
                        positionDetectedContent
                    case .countdown:
                        countdownContent
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Ready State (Initial "Just Press GO")
    private var readyStateContent: some View {
        VStack(spacing: 30) {
            // Exercise title
            Text(exerciseDisplayName.uppercased())
                .font(.system(size: 48, weight: .heavy))
                .tracking(2)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Press GO to begin automatic setup")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Large GO button
            Button(action: onStartPressed) {
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.brassGold)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    
                    VStack(spacing: 4) {
                        Text("GO")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Instructions
            Text("The workout will start automatically when you're in the correct position")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .italic()
        }
    }
    
    // MARK: - Waiting for Position State
    private var waitingForPositionContent: some View {
        VStack(spacing: 25) {
            // Position guidance
            VStack(spacing: 15) {
                Image(systemName: positionIcon)
                    .font(.system(size: 50))
                    .foregroundColor(positionColor)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                
                Text(primaryInstruction)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Position quality indicator
                if positionQuality > 0 {
                    PositionQualityBar(quality: positionQuality)
                }
            }
            
            // Hold progress indicator
            if positionHoldProgress > 0 {
                PositionHoldIndicator(progress: positionHoldProgress)
                    .transition(.scale)
            }
            
            // Missing requirements
            if !missingRequirements.isEmpty {
                RequirementsCard(requirements: missingRequirements)
                    .transition(.move(edge: .bottom))
            }
        }
    }
    
    // MARK: - Position Detected State
    private var positionDetectedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            
            Text("Perfect Position!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Starting workout...")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Countdown State
    private var countdownContent: some View {
        VStack(spacing: 20) {
            if let countdown = countdownValue {
                ZStack {
                    Circle()
                        .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 8)
                        .frame(width: 150, height: 150)
                    
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
            }
            
            Text("Get Ready!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Helper Properties
    private var exerciseDisplayName: String {
        // Use the provided exerciseType instead of placeholder
        return exerciseType.displayName
    }
    
    private var positionIcon: String {
        if positionQuality > 0.8 {
            return "checkmark.circle.fill"
        } else if positionQuality > 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "person.crop.circle.badge.questionmark"
        }
    }
    
    private var positionColor: Color {
        if positionQuality > 0.8 {
            return .green
        } else if positionQuality > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Components

struct PositionQualityBar: View {
    let quality: Float
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Position Quality")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(qualityColor)
                        .frame(width: geometry.size.width * CGFloat(quality), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: quality)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(quality * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(qualityColor)
        }
        .frame(maxWidth: 200)
    }
    
    private var qualityColor: Color {
        if quality > 0.8 {
            return .green
        } else if quality > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct PositionHoldIndicator: View {
    let progress: Float
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Hold Position")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text("Stay in position for 2 seconds")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

struct RequirementsCard: View {
    let requirements: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("Adjustments Needed")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            ForEach(requirements, id: \.self) { requirement in
                HStack(spacing: 8) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(requirement)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
        .frame(maxWidth: 300)
    }
}

// MARK: - Preview
struct AutoPositionOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Ready state
            AutoPositionOverlay(
                workoutState: .ready,
                positionHoldProgress: 0.0,
                countdownValue: nil,
                onStartPressed: {},
                exerciseType: .pushup
            )
            .previewDisplayName("Ready State")
            
            // Waiting for position
            AutoPositionOverlay(
                workoutState: .waitingForPosition,
                positionHoldProgress: 0.3,
                countdownValue: nil,
                onStartPressed: {},
                exerciseType: .situp
            )
            .previewDisplayName("Waiting for Position")
            
            // Countdown
            AutoPositionOverlay(
                workoutState: .countdown,
                positionHoldProgress: 1.0,
                countdownValue: 2,
                onStartPressed: {},
                exerciseType: .pullup
            )
            .previewDisplayName("Countdown")
        }
        .background(Color.black)
    }
} 