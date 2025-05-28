import SwiftUI
import PTDesignSystem

struct EnhancedExerciseOverlay: View {
    let exerciseType: ExerciseType
    let workoutState: WorkoutSessionState
    let detectedBody: DetectedBody?
    let positionHoldProgress: Float
    let countdownValue: Int?
    let onStartPressed: () -> Void
    
    @State private var showAlignmentGrid = false
    @State private var isUserAligned = false
    
    var body: some View {
        ZStack {
            // Layer 1: Alignment grid (optional)
            if showAlignmentGrid && workoutState == .waitingForPosition {
                AlignmentGridView()
                    .opacity(0.3)
            }
            
            // Layer 2: PNG overlay
            if shouldShowPNGOverlay {
                PNGOverlayView(
                    exerciseType: exerciseType,
                    opacity: pngOpacity
                )
            }
            
            // Layer 3: Pose overlay (skeleton)
            if let body = detectedBody {
                PoseOverlayView(
                    detectedBody: body,
                    badJointNames: [] // Calculate based on alignment
                )
            }
            
            // Layer 4: UI overlay
            AutoPositionOverlay(
                workoutState: workoutState,
                positionHoldProgress: positionHoldProgress,
                countdownValue: countdownValue,
                exerciseType: exerciseType,
                onStartPressed: onStartPressed
            )
            
            // Layer 5: Alignment guide (top)
            if workoutState == .waitingForPosition {
                VStack {
                    PositionAlignmentGuide(
                        exerciseType: exerciseType,
                        isAligned: isUserAligned
                    )
                    .padding(.top, 100)
                    
                    Spacer()
                }
            }
        }
        .onChange(of: detectedBody) { _, newBody in
            // Update alignment status based on pose detection
            updateAlignmentStatus(body: newBody)
        }
    }
    
    private var shouldShowPNGOverlay: Bool {
        switch workoutState {
        case .ready, .waitingForPosition, .positionDetected:
            return true
        default:
            return false
        }
    }
    
    private var pngOpacity: Double {
        switch workoutState {
        case .ready:
            return 0.6
        case .waitingForPosition:
            return 0.4
        case .positionDetected:
            return 0.2
        default:
            return 0.0
        }
    }
    
    private func updateAlignmentStatus(body: DetectedBody?) {
        // Simple alignment check - can be enhanced with more sophisticated logic
        if let body = body {
            // Check if key joints are visible and roughly aligned
            let hasKeyJoints = body.point(.leftShoulder) != nil &&
                              body.point(.rightShoulder) != nil &&
                              body.point(.leftHip) != nil &&
                              body.point(.rightHip) != nil
            
            isUserAligned = hasKeyJoints && body.confidence > 0.7
        } else {
            isUserAligned = false
        }
    }
}

// Helper view for alignment grid
struct AlignmentGridView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical center line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Horizontal guide lines
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height * CGFloat(index + 1) / 6)
                }
            }
        }
    }
}

// MARK: - Preview
struct EnhancedExerciseOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnhancedExerciseOverlay(
                exerciseType: .pushup,
                workoutState: .waitingForPosition,
                detectedBody: nil,
                positionHoldProgress: 0.5,
                countdownValue: nil,
                onStartPressed: {}
            )
            .previewDisplayName("Waiting for Position")
            
            EnhancedExerciseOverlay(
                exerciseType: .situp,
                workoutState: .positionDetected,
                detectedBody: nil,
                positionHoldProgress: 1.0,
                countdownValue: nil,
                onStartPressed: {}
            )
            .previewDisplayName("Position Detected")
            
            EnhancedExerciseOverlay(
                exerciseType: .pullup,
                workoutState: .countdown,
                detectedBody: nil,
                positionHoldProgress: 1.0,
                countdownValue: 3,
                onStartPressed: {}
            )
            .previewDisplayName("Countdown")
        }
        .background(Color.black)
    }
} 