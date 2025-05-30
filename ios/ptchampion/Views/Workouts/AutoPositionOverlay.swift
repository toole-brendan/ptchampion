import SwiftUI
import PTDesignSystem

/// Enhanced overlay optimized for landscape with larger, clearer UI elements
struct AutoPositionOverlay: View {
    // TODO: Re-enable AutoPositionDetector once module compilation issues are resolved
    // @ObservedObject var autoPositionDetector: AutoPositionDetector
    let workoutState: WorkoutSessionState
    let positionHoldProgress: Float
    let countdownValue: Int?
    let onStartPressed: () -> Void
    
    // Add exercise type to know which PNG to show
    let exerciseType: ExerciseType
    let isInLandscape: Bool
    
    // Add state for overlay flip preference
    @AppStorage("overlayFlipped") private var isOverlayFlipped: Bool = false
    
    // Add computed property to determine if landscape is required
    private var requiresLandscape: Bool {
        switch exerciseType {
        case .pushup, .situp:
            return true
        case .pullup, .run, .unknown:
            return false
        }
    }
    
    // Control PNG visibility based on state
    private var showPNGOverlay: Bool {
        // Only show overlay if we're in landscape AND in the right state
        // For pull-ups, we can show it even in portrait
        guard requiresLandscape ? isInLandscape : true else { return false }
        
        switch workoutState {
        case .waitingForPosition, .positionDetected:
            return true
        case .ready, .countdown, .counting, .paused, .finished, .requestingPermission, .permissionDenied, .error:
            return false
        default:
            return false
        }
    }
    
    // Animate PNG opacity
    private var pngOpacity: Double {
        switch workoutState {
        case .waitingForPosition:
            return 0.8 // Increased from 0.5 to make it more visible
        case .positionDetected:
            return 0.5 // Increased from 0.3
        default:
            return 0.0
        }
    }
    
    // Temporary placeholder properties to replace AutoPositionDetector
    @State private var primaryInstruction: String = "Align with the overlay"
    @State private var secondaryInstruction: String = "Keep your body straight and centered"
    @State private var positionQuality: Float = 0.0
    @State private var missingRequirements: [String] = []
    @State private var detectedExercise: ExerciseType? = nil
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // PNG Overlay (behind UI elements) - now with enhanced effects
            if showPNGOverlay {
                PNGOverlayView(
                    exerciseType: exerciseType,
                    opacity: pngOpacity,
                    isFlipped: isOverlayFlipped
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: showPNGOverlay)
            }
            
            // Main content optimized for landscape
            VStack {
                // Position the instruction box at the top
                if workoutState == .waitingForPosition && (isInLandscape || !requiresLandscape) {
                    // Place instruction at very top center
                    HStack {
                        Spacer()
                        landscapeWaitingForPositionContent
                            .padding(.top, 20) // Increased from 5 for better visibility
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Add flip toggle button at bottom for pushups and situps
                    if (exerciseType == .pushup || exerciseType == .situp) {
                        HStack {
                            flipToggleButton
                                .padding(.leading, 40) // Increased from 20
                            Spacer()
                        }
                        .padding(.bottom, 40) // Increased from 20
                    }
                } else {
                    // Center other content
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 30) {
                            // Main content based on state
                            Group {
                                switch workoutState {
                                case .ready:
                                    landscapeReadyStateContent
                                case .waitingForPosition:
                                    if !isInLandscape && requiresLandscape {
                                        portraitPromptContent
                                    }
                                    // Instruction box is shown above, not here
                                case .positionDetected:
                                    landscapePositionDetectedContent
                                case .countdown:
                                    landscapeCountdownContent
                                default:
                                    EmptyView()
                                }
                            }
                        }
                        .frame(maxWidth: 600) // Constrain width for readability
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Add flip toggle button at bottom for position detected state
                    if workoutState == .positionDetected && 
                       (exerciseType == .pushup || exerciseType == .situp) && 
                       (isInLandscape || !requiresLandscape) {
                        HStack {
                            flipToggleButton
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.horizontal, 60) // More padding for landscape
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Flip Toggle Button
    private var flipToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOverlayFlipped.toggle()
            }
        }) {
            HStack(spacing: 8) {
                // Show person icon facing the current direction
                Image(systemName: isOverlayFlipped ? "person.fill.turn.left" : "person.fill.turn.right")
                    .font(.system(size: 16, weight: .medium))
                    .rotationEffect(.degrees(isOverlayFlipped ? 0 : 180), anchor: .center)
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                
                Text(isOverlayFlipped ? "Head Right" : "Head Left")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Landscape Ready State
    private var landscapeReadyStateContent: some View {
        VStack(spacing: 30) {
            // Exercise title
            Text(exerciseDisplayName.uppercased())
                .font(.system(size: 42, weight: .heavy))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .tracking(2)
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .multilineTextAlignment(.center)
            
            // Large GO button with shadow
            Button(action: onStartPressed) {
                ZStack {
                    Circle()
                        .fill(AppTheme.GeneratedColors.brassGold)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                        .shadow(color: AppTheme.GeneratedColors.brassGold.opacity(0.4), 
                                radius: pulseAnimation ? 20 : 10)
                    
                    VStack(spacing: 6) {
                        Text("GO")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.black)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Instructions
            Text("Tap GO and position yourself to match the guide")
                .font(.system(size: 20, weight: .medium))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Landscape Waiting for Position
    private var landscapeWaitingForPositionContent: some View {
        VStack(spacing: 16) {
            // Ultra-compact position guidance - just text
            Text(primaryInstruction)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            Capsule()
                                .stroke(positionColor.opacity(0.5), lineWidth: 1)
                        )
                )
            
            // Only show progress indicators below if they have values  
            // These will appear below the instruction and shouldn't overlap with pose
            if positionHoldProgress > 0 {
                LargePositionHoldIndicator(progress: positionHoldProgress)
                    .transition(.scale)
            }
        }
    }
    
    // MARK: - Landscape Position Detected
    private var landscapePositionDetectedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 90))
                .foregroundColor(.green)
                .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                .shadow(color: .green.opacity(0.5), radius: 20)
            
            Text("Perfect Position!")
                .font(.system(size: 36, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundColor(.white)
            
            Text("Get ready to start...")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Landscape Countdown
    private var landscapeCountdownContent: some View {
        VStack(spacing: 24) {
            if let countdown = countdownValue {
                ZStack {
                    Circle()
                        .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 10)
                        .frame(width: 180, height: 180)
                    
                    Text("\(countdown)")
                        .font(.system(size: 90, weight: .black))
                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                }
                .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                .shadow(color: AppTheme.GeneratedColors.brassGold.opacity(0.4), radius: 20)
            }
            
            Text("Get Ready!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Portrait Prompt
    private var portraitPromptContent: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "rotate.right")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                .rotationEffect(.degrees(-90))
            
            // Main message in a styled box like the "Align with the..." box
            VStack(spacing: 10) {
                Text("Please rotate to landscape")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(exerciseType.displayName) workouts require landscape orientation for accurate pose detection")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.GeneratedColors.brassGold.opacity(0.5), lineWidth: 2)
                    )
            )
            .frame(maxWidth: 400)
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
            return "arrow.trianglehead.2.clockwise.rotate.90"
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
            return AppTheme.GeneratedColors.brassGold
        }
    }
}

// MARK: - Enhanced Supporting Components

struct LargePositionQualityBar: View {
    let quality: Float
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Position Alignment")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [qualityColor.opacity(0.8), qualityColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(quality), height: 12)
                        .animation(.easeInOut(duration: 0.3), value: quality)
                }
            }
            .frame(height: 12)
            
            Text("\(Int(quality * 100))%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(qualityColor)
        }
        .frame(maxWidth: 350)
        .padding(.horizontal, 20)
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

struct LargePositionHoldIndicator: View {
    let progress: Float
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Hold Position")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("2 sec")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct LandscapeRequirementsCard: View {
    let requirements: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                Text("Adjust Your Position")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            ForEach(requirements, id: \.self) { requirement in
                HStack(spacing: 10) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(requirement)
                        .font(.system(size: 16))
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                )
        )
        .frame(maxWidth: 450)
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
                exerciseType: .pushup,
                isInLandscape: true
            )
            .previewDisplayName("Ready State - Landscape")
            .previewInterfaceOrientation(.landscapeRight)
            
            // Waiting for position - Portrait
            AutoPositionOverlay(
                workoutState: .waitingForPosition,
                positionHoldProgress: 0.0,
                countdownValue: nil,
                onStartPressed: {},
                exerciseType: .pushup,
                isInLandscape: false
            )
            .previewDisplayName("Waiting - Portrait Prompt")
            .previewInterfaceOrientation(.portrait)
            
            // Waiting for position - Landscape
            AutoPositionOverlay(
                workoutState: .waitingForPosition,
                positionHoldProgress: 0.3,
                countdownValue: nil,
                onStartPressed: {},
                exerciseType: .situp,
                isInLandscape: true
            )
            .previewDisplayName("Waiting - Landscape")
            .previewInterfaceOrientation(.landscapeRight)
            
            // Waiting for position - Landscape with flip toggle visible
            AutoPositionOverlay(
                workoutState: .waitingForPosition,
                positionHoldProgress: 0.0,
                countdownValue: nil,
                onStartPressed: {},
                exerciseType: .pushup,
                isInLandscape: true
            )
            .previewDisplayName("Pushup - With Flip Toggle")
            .previewInterfaceOrientation(.landscapeRight)
            
            // Countdown
            AutoPositionOverlay(
                workoutState: .countdown,
                positionHoldProgress: 1.0,
                countdownValue: 2,
                onStartPressed: {},
                exerciseType: .pullup,
                isInLandscape: true
            )
            .previewDisplayName("Countdown - Landscape")
            .previewInterfaceOrientation(.landscapeRight)
        }
        .background(Color.black)
    }
} 