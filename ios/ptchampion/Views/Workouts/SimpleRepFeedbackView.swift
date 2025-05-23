import SwiftUI
import PTDesignSystem

struct SimpleRepFeedbackView: View {
    @Binding var showFeedback: Bool
    @Binding var isSuccess: Bool
    
    var body: some View {
        if showFeedback {
            ZStack {
                // Semi-transparent background for visibility
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 200, height: 200)
                
                // Success or failure icon
                Image(systemName: isSuccess ? "checkmark" : "xmark")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(isSuccess ? .green : .red)
                    .animation(.easeInOut(duration: 0.2), value: isSuccess)
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: showFeedback)
        }
    }
}
