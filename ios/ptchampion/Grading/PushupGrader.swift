import Foundation
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants
import CoreGraphics // For CGFloat, CGPoint
import Combine // For ObservableObject

final class PushupGrader: ObservableObject, ExerciseGraderProtocol {

    // MARK: - Static Thresholds (Accessible for Unit Testing)
    // FPS setting - helps adjust required stable frames
    static var targetFramesPerSecond: Double = 30.0 // Target frame rate (default 30fps)
    
    // Required confidence for joint positions
    static var requiredJointConfidence: Float = 0.5
    
    // Required stable frames
    static var requiredStableFrames: Int = 5
    
    // Elbow angle thresholds
    static let elbowAngleDownMax: CGFloat = 90.0   // Max elbow angle considered 'down'
    static let elbowAngleUpMin: CGFloat = 160.0    // Min elbow angle considered 'up'
    
    // Body alignment thresholds
    static let hipSagThreshold: CGFloat = 0.10     // Max deviation for hip sagging
    static let hipPikeThreshold: CGFloat = 0.12    // Max deviation for hip piking/raising
    static let shoulderAlignmentMaxXDiff: CGFloat = 0.10 // Max normalized X diff between shoulders
    
    // New thresholds for strict grading
    static let pauseFrameThreshold: Int = Int(2.0 * targetFramesPerSecond) // ~2 seconds pause
    static let wormingThreshold: CGFloat = 0.03 // 3% threshold for differential movement
    static let groundTouchThreshold: CGFloat = 0.02 // 2% threshold for ground contact
    static let liftThreshold: CGFloat = 0.05 // 5% threshold for limb lift-off

    // MARK: - States reflecting the phases of a push-up
    private enum PushupState: Equatable {
        case up             // Arms extended, top position
        case down           // Arms bent, bottom position
        case starting       // Initial position, waiting for movement
        case invalid        // Pose not suitable for grading (e.g., missing landmarks)
        case between        // Transitioning between up and down
    }

    // MARK: - Internal State Tracking
    private var currentState: PushupState = .starting
    private var feedback: String = "Get into push-up position."
    private var _repCount: Int = 0 // Internal counter, exposed via protocol
    private var _lastFormIssue: String? = nil // Track last form issue
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = [] // Track joints with issues
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    // Form quality tracking
    private var formScores: [Double] = [] // Track form quality of each rep
    
    // State tracking for rep evaluation
    private var minElbowAngleThisRep: CGFloat = 180.0
    private var wentLowEnoughThisRep: Bool = false
    private var stableFramesInState: Int = 0
    private var consecutiveInvalidFrames: Int = 0
    private var inRepTransition: Bool = false
    
    // New state tracking for additional checks
    private var framesInPosition: Int = 0
    private var prevAvgShoulderY: CGFloat?
    private var prevAvgHipY: CGFloat?
    private var prevLeftWristY: CGFloat?
    private var prevRightWristY: CGFloat?
    private var prevLeftAnkleY: CGFloat?
    private var prevRightAnkleY: CGFloat?

    // MARK: - Protocol Properties
    var currentPhaseDescription: String {
        // Provide a simple description for the current internal state
        switch currentState {
        case .up: return "Up"
        case .down: return "Down"
        case .starting: return "Ready"
        case .invalid: return "Invalid Pose"
        case .between: return inRepTransition ? "Transitioning" : "Moving"
        }
    }
    
    var repCount: Int { return _repCount }
    
    var formQualityAverage: Double {
        guard !formScores.isEmpty else { return 0.0 }
        return formScores.reduce(0.0, +) / Double(formScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }

    // MARK: - Protocol Methods
    func resetState() {
        currentState = .starting
        feedback = "Get into push-up position."
        minElbowAngleThisRep = 180.0
        wentLowEnoughThisRep = false
        _repCount = 0 // Reset internal counter
        formScores = [] // Reset form scores
        stableFramesInState = 0
        consecutiveInvalidFrames = 0
        inRepTransition = false
        _lastFormIssue = nil
        _problemJoints = [] // Reset problem joints
        
        // Reset new state variables
        framesInPosition = 0
        prevAvgShoulderY = nil
        prevAvgHipY = nil
        prevLeftWristY = nil
        prevRightWristY = nil
        prevLeftAnkleY = nil
        prevRightAnkleY = nil
        
        print("PushupGrader: State reset.")
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback for this frame
        _problemJoints = [] // Reset problem joints for this frame
        
        let previousState = currentState // Remember the previous state for transition logic

        // 1. Check Required Joint Confidence
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        // Check if all required joints are visible using the helper
        if !PoseValidationHelper.isFullBodyVisible(body, requiredJoints: keyJoints, confidence: PushupGrader.requiredJointConfidence) {
            // Increment invalid frame counter
            consecutiveInvalidFrames += 1
            
            // Only change state to invalid after a few consecutive invalid frames
            // This helps avoid flickering due to momentary occlusions
            if consecutiveInvalidFrames >= 3 {
                stableFramesInState = 0
                currentState = .invalid
                
                feedback = "Warning: Please position your entire body in the frame."
                _lastFormIssue = feedback
                return .invalidPose(reason: feedback)
            }
            
            // Return no change if we're below the invalid threshold
            return .noChange
        }
        
        // Reset invalid counter since we have a valid frame
        consecutiveInvalidFrames = 0

        // Extract validated points (we know they exist with sufficient confidence now)
        let leftShoulder = body.point(.leftShoulder)!
        let rightShoulder = body.point(.rightShoulder)!
        let leftHip = body.point(.leftHip)!
        let rightHip = body.point(.rightHip)!
        let leftAnkle = body.point(.leftAnkle)!
        let rightAnkle = body.point(.rightAnkle)!
        let leftKnee = body.point(.leftKnee)!
        let rightKnee = body.point(.rightKnee)!
        let leftWrist = body.point(.leftWrist)!
        let rightWrist = body.point(.rightWrist)!

        // 2. Calculate Key Angles & Positions
        // Use the DetectedBody helper to calculate the elbow angles
        let leftElbowAngle = body.calculateAngle(first: .leftWrist, vertex: .leftElbow, second: .leftShoulder)
        let rightElbowAngle = body.calculateAngle(first: .rightWrist, vertex: .rightElbow, second: .rightShoulder)
        let avgElbowAngle = averageAngle(leftElbowAngle, rightElbowAngle) ?? 180.0 // Default to straight if calculation fails

        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2.0
        let avgAnkleY = (leftAnkle.location.y + rightAnkle.location.y) / 2.0
        let leftKneeY = leftKnee.location.y
        let rightKneeY = rightKnee.location.y
        let leftHipY = leftHip.location.y
        let rightHipY = rightHip.location.y

        // 3. Form Checks
        var formIssues: [String] = []

        // a) Shoulder alignment (X-axis difference)
        let shoulderXDiff = abs(leftShoulder.location.x - rightShoulder.location.x)
        if shoulderXDiff > PushupGrader.shoulderAlignmentMaxXDiff {
            formIssues.append("Keep shoulders level")
            _problemJoints.insert(.leftShoulder)
            _problemJoints.insert(.rightShoulder)
        }

        // b) Body straightness checks
        // Calculate deviation of hip relative to the shoulder-ankle line
        let shoulderAnkleLineYatHipX = interpolateY(
            point1: CGPoint(x: avgShoulderY, y: 0), // Use Y as X for vertical check
            point2: CGPoint(x: avgAnkleY, y: 0),
            x: avgHipY
        )
        
        // Estimate body "length" (shoulder to ankle Y difference) for normalization
        let bodyLengthY = abs(avgAnkleY - avgShoulderY) + 1e-6 // Add epsilon to avoid division by zero

        // Calculate hip deviation (positive = sagging, negative = piking relative to straight line)
        let hipDeviationRatio = (avgHipY - shoulderAnkleLineYatHipX) / bodyLengthY

        // Check for Sagging (Hips too low)
        if hipDeviationRatio > PushupGrader.hipSagThreshold {
             formIssues.append("Body sagging")
             _problemJoints.insert(.leftHip)
             _problemJoints.insert(.rightHip)
        }

        // Check for Piking (Hips too high)
        if hipDeviationRatio < -PushupGrader.hipPikeThreshold { // Check against negative threshold for piking
             formIssues.append("Body piking")
             _problemJoints.insert(.leftHip)
             _problemJoints.insert(.rightHip)
        }
        
        // c) Check for worming (shoulders and hips moving asynchronously)
        if let prevShoulderY = prevAvgShoulderY, let prevHipY = prevAvgHipY {
            let shoulderMove = abs(avgShoulderY - prevShoulderY)
            let hipMove = abs(avgHipY - prevHipY)
            
            if abs(shoulderMove - hipMove) > PushupGrader.wormingThreshold {
                formIssues.append("Worming detected")
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
            }
        }
        
        // d) Check for ground contact (knees or body)
        // Knees touching ground if knees close to hip height
        if abs(leftKneeY - leftHipY) < PushupGrader.groundTouchThreshold ||
            abs(rightKneeY - rightHipY) < PushupGrader.groundTouchThreshold {
            formIssues.append("Knees touching ground")
            _problemJoints.insert(.leftKnee)
            _problemJoints.insert(.rightKnee)
        }
        
        // Body touching ground if shoulders almost level with hips
        if abs(avgShoulderY - avgHipY) < PushupGrader.groundTouchThreshold {
            formIssues.append("Body touching ground")
            _problemJoints.insert(.leftShoulder)
            _problemJoints.insert(.rightShoulder)
            _problemJoints.insert(.leftHip)
            _problemJoints.insert(.rightHip)
        }
        
        // e) Check for hand/foot lift-off
        if let prevLW = prevLeftWristY, let prevRW = prevRightWristY {
            // If wrist is higher (y decreased) by threshold from last frame, hand was lifted
            if prevLW - leftWrist.location.y > PushupGrader.liftThreshold ||
                prevRW - rightWrist.location.y > PushupGrader.liftThreshold {
                formIssues.append("Hands lifted off ground")
                _problemJoints.insert(.leftWrist)
                _problemJoints.insert(.rightWrist)
            }
        }
        
        if let prevLA = prevLeftAnkleY, let prevRA = prevRightAnkleY {
            // If ankle is higher (y decreased) by threshold from last frame, foot was lifted
            if prevLA - leftAnkle.location.y > PushupGrader.liftThreshold ||
                prevRA - rightAnkle.location.y > PushupGrader.liftThreshold {
                formIssues.append("Feet lifted off ground")
                _problemJoints.insert(.leftAnkle)
                _problemJoints.insert(.rightAnkle)
            }
        }

        // Check for Elbow angle issues during DOWN state
        if currentState == .down && avgElbowAngle > PushupGrader.elbowAngleDownMax {
            formIssues.append("Bend elbows more")
            _problemJoints.insert(.leftElbow)
            _problemJoints.insert(.rightElbow)
        }
        
        // f) Check for pausing too long
        if currentState == previousState {
            framesInPosition += 1
            if framesInPosition > PushupGrader.pauseFrameThreshold {
                formIssues.append("Paused too long")
                // No specific joint to highlight for pause
            }
        } else {
            framesInPosition = 0
        }

        // Update tracking variables for the next frame
        prevAvgShoulderY = avgShoulderY
        prevAvgHipY = avgHipY
        prevLeftWristY = leftWrist.location.y
        prevRightWristY = rightWrist.location.y
        prevLeftAnkleY = leftAnkle.location.y
        prevRightAnkleY = rightAnkle.location.y

        // Record form issues if any
        if !formIssues.isEmpty {
            feedback = formIssues.first ?? ""  // Take the first issue as the primary feedback
            _lastFormIssue = feedback
        }

        // --- State Machine Logic --- 
        // Determine potential next state based on elbow angle
        var potentialState: PushupState
        
        if avgElbowAngle <= PushupGrader.elbowAngleDownMax {
            potentialState = .down
            // STATE TRANSITION: Moving into DOWN position (arms bent)
        } else if avgElbowAngle >= PushupGrader.elbowAngleUpMin {
            potentialState = .up
            // STATE TRANSITION: Moving into UP position (arms extended)
        } else {
            potentialState = .between // In transition
        }

        // Check if state actually changed from previous frame
        if potentialState != previousState {
            // State change detected - reset stability counter
            stableFramesInState = 0
            
            // Set transition flag if we're moving between meaningful positions
            if (previousState == .up && potentialState == .between) || 
               (previousState == .down && potentialState == .between) {
                inRepTransition = true
            }
            else if previousState == .between && (potentialState == .up || potentialState == .down) {
                inRepTransition = false
            }
        } else {
            // Same state as last frame - increment stability counter
            stableFramesInState += 1
        }

        // Update current state only if we've met stability threshold or it's the first frame
        if stableFramesInState >= PushupGrader.requiredStableFrames || previousState == .starting {
            // Stable new state - commit the change
            currentState = potentialState
        }

        // Track minimum angle during the down phase or transition towards it
        if currentState == .down || (previousState == .up && currentState == .between) {
            minElbowAngleThisRep = min(minElbowAngleThisRep, avgElbowAngle)
        }

        // Check if went low enough (only relevant if currently down or moving up from down)
        if currentState == .down || (previousState == .down && (currentState == .between || currentState == .up)) {
            if minElbowAngleThisRep <= PushupGrader.elbowAngleDownMax {
                wentLowEnoughThisRep = true
            }
        }

        // Check for Rep Completion - require a stable UP state after a DOWN state
        if previousState == .down && currentState == .up && stableFramesInState >= PushupGrader.requiredStableFrames {
            // STATE TRANSITION: DOWN -> UP (Stable) = Potential Rep Completion
            
            // Rep attempt: Transitioned from Down to Up
            if wentLowEnoughThisRep && formIssues.isEmpty {
                // STATE TRANSITION: Valid Rep Completed
                _repCount += 1 
                
                // All counted reps have perfect form
                let formQuality = 1.0
                formScores.append(formQuality)
                
                feedback = "Good rep!"
                
                // Reset state for next rep
                minElbowAngleThisRep = 180.0
                wentLowEnoughThisRep = false
                
                return .repCompleted(formQuality: formQuality)
            } else {
                // Either didn't go low enough or had form issues
                let issueMsg = formIssues.first ?? "Push lower for rep to count"
                feedback = issueMsg
                _lastFormIssue = issueMsg
                
                // Reset state for next rep attempt
                minElbowAngleThisRep = 180.0
                wentLowEnoughThisRep = false
                
                // Return incorrect form to provide immediate feedback
                return .incorrectForm(feedback: feedback)
            }
        }

        // Provide general feedback based on state if no specific feedback yet
        if feedback.isEmpty { 
            switch currentState {
            case .up: 
                feedback = "Lower body"
            case .down: 
                feedback = "Push up"
            case .starting: 
                feedback = "Begin push-up"
            case .between: 
                feedback = inRepTransition ? "Keep going" : "Continue movement"
            case .invalid: 
                feedback = "Fix pose"
            }
        }

        // Return current progress state
        return .inProgress(phase: currentPhaseDescription)
    }

    // Helper to interpolate Y value on a line defined by two points at a given X
    // NOTE: We swap X and Y here because we are checking vertical alignment based on Y coordinates
    private func interpolateY(point1: CGPoint, point2: CGPoint, x: CGFloat) -> CGFloat {
        // Avoid division by zero if points have the same X (Y-coordinate in this context)
        guard abs(point2.x - point1.x) > 1e-6 else {
            return point1.y
        }
        let slope = (point2.y - point1.y) / (point2.x - point1.x)
        return point1.y + slope * (x - point1.x)
    }
    
    func calculateFinalScore() -> Double? {
        // Calculate a score based on rep count and form quality
        // If no reps completed, return nil
        guard _repCount > 0 else { return nil }
        
        // Base score is rep count * 10 (max 100)
        let maxReps = 10 // 10 reps = 100 points
        let repScore = min(Double(_repCount) / Double(maxReps), 1.0) * 85.0 // 85% of score is rep count
        
        // Form quality contributes up to 15% of score
        let formScore = formQualityAverage * 15.0
        
        // Total score combines rep count and form quality
        return min(repScore + formScore, 100.0)
    }

    // Helper to average angles, ignoring nil values
    private func averageAngle(_ angle1: CGFloat?, _ angle2: CGFloat?) -> CGFloat? {
        switch (angle1, angle2) {
        case (.some(let a1), .some(let a2)): return (a1 + a2) / 2.0
        case (.some(let a1), .none): return a1
        case (.none, .some(let a2)): return a2
        case (.none, .none): return nil
        }
    }
} 