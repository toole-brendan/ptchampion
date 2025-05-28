import SwiftUI
import PTDesignSystem

struct DevicePlacementTip: View {
    let exercise: ExerciseType
    @State private var showTip = true
    
    var body: some View {
        if showTip {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                Text(placementTip)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Got it") {
                    withAnimation {
                        showTip = false
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .padding()
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var placementTip: String {
        switch exercise {
        case .pushup, .situp:
            return "📱 Place phone to your side, 6-8 feet away"
        case .pullup:
            return "📱 Place phone in front, 6-10 feet away"
        default:
            return "📱 Ensure full body is visible"
        }
    }
}

// MARK: - Preview
struct DevicePlacementTip_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DevicePlacementTip(exercise: .pushup)
                .previewDisplayName("Push-up Tip")
            
            DevicePlacementTip(exercise: .pullup)
                .previewDisplayName("Pull-up Tip")
            
            DevicePlacementTip(exercise: .situp)
                .previewDisplayName("Sit-up Tip")
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 