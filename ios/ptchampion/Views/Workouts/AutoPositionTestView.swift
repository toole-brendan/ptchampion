import SwiftUI
import PTDesignSystem

/// Test view to verify AutoPositionDetector functionality
struct AutoPositionTestView: View {
    @StateObject private var autoPositionDetector = AutoPositionDetector()
    @State private var workoutState: WorkoutSessionState = .ready
    @State private var positionHoldProgress: Float = 0.0
    @State private var countdownValue: Int? = nil
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Auto Position Detection Test")
                    .font(.title)
                    .foregroundColor(.white)
                
                // State controls
                VStack(spacing: 10) {
                    Text("Current State: \(stateDescription)")
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        Button("Ready") {
                            workoutState = .ready
                            autoPositionDetector.reset()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Waiting") {
                            workoutState = .waitingForPosition
                            simulatePositionDetection()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Detected") {
                            workoutState = .positionDetected
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Countdown") {
                            workoutState = .countdown
                            countdownValue = 3
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Auto Position Overlay
                AutoPositionOverlay(
                    autoPositionDetector: autoPositionDetector,
                    workoutState: workoutState,
                    positionHoldProgress: positionHoldProgress,
                    countdownValue: countdownValue,
                    onStartPressed: {
                        print("GO button pressed in test")
                        workoutState = .waitingForPosition
                        simulatePositionDetection()
                    }
                )
            }
        }
    }
    
    private var stateDescription: String {
        switch workoutState {
        case .ready: return "Ready"
        case .waitingForPosition: return "Waiting for Position"
        case .positionDetected: return "Position Detected"
        case .countdown: return "Countdown"
        default: return "Other"
        }
    }
    
    private func simulatePositionDetection() {
        // Simulate the position detection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            autoPositionDetector.primaryInstruction = "Move closer to camera"
            autoPositionDetector.positionQuality = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            autoPositionDetector.primaryInstruction = "Center your body in frame"
            autoPositionDetector.positionQuality = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            autoPositionDetector.primaryInstruction = "Perfect! Hold this position"
            autoPositionDetector.positionQuality = 0.9
            positionHoldProgress = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            autoPositionDetector.isInPosition = true
            positionHoldProgress = 1.0
            workoutState = .positionDetected
        }
    }
}

struct AutoPositionTestView_Previews: PreviewProvider {
    static var previews: some View {
        AutoPositionTestView()
    }
} 