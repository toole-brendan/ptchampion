import SwiftUI
import PTDesignSystem

struct PositionInstructionBanner: View {
    let exercise: ExerciseType
    
    var body: some View {
        VStack(spacing: 8) {
            Text(requiredPosition)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(setupTip)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
        )
    }
    
    private var requiredPosition: String {
        switch exercise {
        case .pushup:
            return "📱 Set phone to your side"
        case .pullup:
            return "📱 Set phone in front"
        case .situp:
            return "📱 Set phone to your side"
        default:
            return "Position your device"
        }
    }
    
    private var setupTip: String {
        switch exercise {
        case .pushup:
            return "Camera should see your full body from the side"
        case .pullup:
            return "Camera should see you facing it while hanging"
        case .situp:
            return "Camera should see your full body from the side"
        default:
            return "Ensure full body is visible"
        }
    }
}

// MARK: - Preview
struct PositionInstructionBanner_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PositionInstructionBanner(exercise: .pushup)
                .previewDisplayName("Push-up Instructions")
            
            PositionInstructionBanner(exercise: .pullup)
                .previewDisplayName("Pull-up Instructions")
            
            PositionInstructionBanner(exercise: .situp)
                .previewDisplayName("Sit-up Instructions")
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 