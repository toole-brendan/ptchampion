import SwiftUI
import PTDesignSystem

struct EnhancedExerciseOverlay: View {
    let exerciseType: ExerciseType
    let workoutState: WorkoutSessionState
    let detectedBody: DetectedBody?
    let positionHoldProgress: Float
    let countdownValue: Int?
    let onStartPressed: () -> Void
    let isInLandscape: Bool
    
    @State private var showAlignmentGrid = false
    @State private var isUserAligned = false
    
    var body: some View {
        ZStack {
            // Single combined overlay instead of multiple layers
            if shouldShowPNGOverlay && isInLandscape {
                PNGOverlayView(
                    exerciseType: exerciseType,
                    opacity: pngOpacity
                )
                .allowsHitTesting(false) // Don't block touches
            }
            
            // Simplified UI overlay with all controls
            if workoutState != .counting {
                AutoPositionOverlay(
                    workoutState: workoutState,
                    positionHoldProgress: positionHoldProgress,
                    countdownValue: countdownValue,
                    onStartPressed: onStartPressed,
                    exerciseType: exerciseType,
                    isInLandscape: isInLandscape
                )
            }
        }
        .onChange(of: detectedBody) { _, newBody in
            // Update alignment status based on pose detection
            updateAlignmentStatus(body: newBody)
        }
    }
    
    private var shouldShowPNGOverlay: Bool {
        switch workoutState {
        case .waitingForPosition, .positionDetected:
            return true
        case .ready, .countdown, .counting, .paused, .finished, .requestingPermission, .permissionDenied, .error:
            return false
        default:
            return false
        }
    }
    
    private var pngOpacity: Double {
        switch workoutState {
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

// Helper view for alignment grid - removed to simplify
// struct AlignmentGridView removed

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
                onStartPressed: {},
                isInLandscape: false
            )
            .previewDisplayName("Waiting for Position")
            
            EnhancedExerciseOverlay(
                exerciseType: .situp,
                workoutState: .positionDetected,
                detectedBody: nil,
                positionHoldProgress: 1.0,
                countdownValue: nil,
                onStartPressed: {},
                isInLandscape: false
            )
            .previewDisplayName("Position Detected")
            
            EnhancedExerciseOverlay(
                exerciseType: .pullup,
                workoutState: .countdown,
                detectedBody: nil,
                positionHoldProgress: 1.0,
                countdownValue: 3,
                onStartPressed: {},
                isInLandscape: false
            )
            .previewDisplayName("Countdown")
        }
        .background(Color.black)
    }
} 