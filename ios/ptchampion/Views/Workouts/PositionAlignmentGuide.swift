import SwiftUI
import PTDesignSystem

struct PositionAlignmentGuide: View {
    let exerciseType: ExerciseType
    let isAligned: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Alignment indicator
            HStack(spacing: 12) {
                Image(systemName: isAligned ? "checkmark.circle.fill" : "arrow.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(isAligned ? .green : .orange)
                
                Text(isAligned ? "Aligned with guide" : "Align with the overlay")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )
            
            // Position tips
            if !isAligned {
                Text(positionTip)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var positionTip: String {
        switch exerciseType {
        case .pushup:
            return "Keep your body straight from head to heels"
        case .situp:
            return "Lie flat with knees bent at 90 degrees"
        case .pullup:
            return "Hang with arms fully extended"
        case .run:
            return "Stand upright in running position"
        case .plank:
            return "Keep your body straight in plank position"
        case .unknown:
            return "Follow the exercise instructions"
        }
    }
}

// MARK: - Preview
struct PositionAlignmentGuide_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PositionAlignmentGuide(exerciseType: .pushup, isAligned: true)
                .previewDisplayName("Aligned - Push-up")
            
            PositionAlignmentGuide(exerciseType: .situp, isAligned: false)
                .previewDisplayName("Not Aligned - Sit-up")
            
            PositionAlignmentGuide(exerciseType: .pullup, isAligned: false)
                .previewDisplayName("Not Aligned - Pull-up")
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 