import SwiftUI
import PTDesignSystem

struct PositionFeedbackBar: View {
    let framingStatus: FullBodyFramingValidator.FramingStatus
    let feedback: String
    let confidence: Float
    
    var body: some View {
        VStack(spacing: 12) {
            // Confidence indicator
            if confidence > 0 {
                ConfidenceIndicator(confidence: confidence)
            }
            
            // Feedback message
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(feedback)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(statusColor.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private var statusIcon: String {
        switch framingStatus {
        case .perfect:
            return "checkmark.circle.fill"
        case .needsAdjustment:
            return "exclamationmark.triangle.fill"
        case .notDetected:
            return "person.crop.circle.badge.questionmark"
        }
    }
    
    private var statusColor: Color {
        switch framingStatus {
        case .perfect:
            return .green
        case .needsAdjustment:
            return .orange
        case .notDetected:
            return .red
        }
    }
}

struct ConfidenceIndicator: View {
    let confidence: Float
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Detection Quality")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: confidence)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
        .frame(maxWidth: 120)
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview
struct PositionFeedbackBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PositionFeedbackBar(
                framingStatus: .perfect,
                feedback: "Perfect positioning!",
                confidence: 0.95
            )
            .previewDisplayName("Perfect Position")
            
            PositionFeedbackBar(
                framingStatus: .needsAdjustment,
                feedback: "Move closer to camera",
                confidence: 0.7
            )
            .previewDisplayName("Needs Adjustment")
            
            PositionFeedbackBar(
                framingStatus: .notDetected,
                feedback: "Position yourself in frame",
                confidence: 0.0
            )
            .previewDisplayName("Not Detected")
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 