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
                    
                    Text("Instruction: \(autoPositionDetector.feedback)")
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Text("Quality: \(Int(autoPositionDetector.positionQuality * 100))%")
                        .foregroundColor(.white)
                        .font(.caption)
                    
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
                    workoutState: workoutState,
                    positionHoldProgress: positionHoldProgress,
                    countdownValue: countdownValue,
                    onStartPressed: {
                        print("GO button pressed in test")
                        workoutState = .waitingForPosition
                        simulatePositionDetection()
                    },
                    exerciseType: .pushup,
                    isInLandscape: true
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
        // Simulate the position detection process using the new AutoPositionDetector
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate analyzing with nil body (not in frame)
            autoPositionDetector.analyzePosition(body: nil, exerciseType: .pushup)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate partial detection
            autoPositionDetector.positionQuality = 0.6
            autoPositionDetector.feedback = "Center your body in frame"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Simulate good position
            autoPositionDetector.positionQuality = 0.9
            autoPositionDetector.feedback = "Perfect! Hold this position"
            autoPositionDetector.positionStatus = .holding
            positionHoldProgress = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            // Simulate position confirmed
            autoPositionDetector.isInCorrectPosition = true
            autoPositionDetector.positionStatus = .correctPosition
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