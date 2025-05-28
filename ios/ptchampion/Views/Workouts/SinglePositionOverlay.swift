import SwiftUI
import PTDesignSystem

struct SinglePositionOverlay: View {
    let exercise: ExerciseType
    @ObservedObject var framingValidator: FullBodyFramingValidator
    @ObservedObject var positionValidator: StartingPositionValidator
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            // Single PNG for the exercise
            Image("\(exercise.rawValue)_position")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(overlayColor)
                .opacity(0.7)
                .padding(uniformPadding)
                .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // Position instructions
            VStack {
                // Device placement tip
                DevicePlacementTip(exercise: exercise)
                
                // Top instruction banner
                PositionInstructionBanner(exercise: exercise)
                    .padding(.top, 50)
                
                Spacer()
                
                // Bottom feedback bar
                PositionFeedbackBar(
                    framingStatus: framingValidator.framingStatus,
                    feedback: framingValidator.guideFeedback,
                    confidence: positionValidator.detectedPoseConfidence
                )
            }
            
            // Directional arrows (if needed)
            if framingValidator.framingStatus == .needsAdjustment {
                DirectionalArrows(adjustment: framingValidator.requiredAdjustment)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var overlayColor: Color {
        switch (framingValidator.framingStatus, positionValidator.isInPosition) {
        case (.perfect, true):
            return .green
        case (.perfect, false):
            return .yellow
        case (.needsAdjustment, _):
            return .orange
        default:
            return .white
        }
    }
    
    private var uniformPadding: EdgeInsets {
        // Same padding regardless of orientation
        EdgeInsets(top: 100, leading: 60, bottom: 180, trailing: 60)
    }
}

// MARK: - Preview
struct SinglePositionOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SinglePositionOverlay(
                exercise: .pushup,
                framingValidator: FullBodyFramingValidator(),
                positionValidator: StartingPositionValidator()
            )
            .previewDisplayName("Push-up Position")
            
            SinglePositionOverlay(
                exercise: .pullup,
                framingValidator: FullBodyFramingValidator(),
                positionValidator: StartingPositionValidator()
            )
            .previewDisplayName("Pull-up Position")
            
            SinglePositionOverlay(
                exercise: .situp,
                framingValidator: FullBodyFramingValidator(),
                positionValidator: StartingPositionValidator()
            )
            .previewDisplayName("Sit-up Position")
        }
        .background(Color.black)
    }
} 