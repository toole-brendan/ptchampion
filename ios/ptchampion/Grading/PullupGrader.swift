import Foundation
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants
import CoreGraphics
import Combine // For ObservableObject

final class PullupGrader: ObservableObject, ExerciseGraderProtocol {

    // MARK: - Static Thresholds (Accessible for Unit Testing)
    // FPS setting - helps adjust required stable frames
    static var targetFramesPerSecond: Double = 30.0 // Target frame rate (default 30fps)
    
    // Required confidence for joint positions
    static var requiredJointConfidence: Float = 0.6
    
    // Required stable frames
    static var requiredStableFrames: Int = 5 // Increased from 3 to match push-up stability
    
    // Angle thresholds
    static let elbowAngleDownMin: CGFloat = 160.0  // Min angle to be considered fully extended ('down')
    static let elbowAngleUpRepCheckMax: CGFloat = 90.0 // Minimum bend required during UP phase for rep check
    
    // Position thresholds
    static let chinAboveBarMinYDiff: CGFloat = 0.05 // Vertical distance threshold: Nose Y must be *above* Wrist Y
    static let kippingMaxHipYTravel: CGFloat = 0.10 // Max allowed vertical hip movement for kipping check
    static let chinHeightThreshold: CGFloat = 0.05  // Wrists this much (or less) *above* shoulders counts as "up"
    static let elbowShoulderDeadHangThreshold: CGFloat = 0.20 // Wrists this much (or more) *below* shoulders is "down"
    
    // New thresholds for strict grading
    static let pauseFrameThreshold: Int = Int(2.0 * targetFramesPerSecond) // ~2 seconds pause
    static let groundContactThreshold: CGFloat = 0.05 // Threshold for detecting ground contact
    static let kneeBendingThreshold: CGFloat = 30.0 // Max angle change allowed for knees during a rep
    static let ankleYShiftThreshold: CGFloat = 0.08 // Threshold for detecting sudden ankle movement

    // MARK: - Pullup States
    private enum PullupPhase {
        case down // Arms fully extended hanging
        case up   // Chin above the bar
        case starting
        case invalid
        case between // Transitioning
    }

    // MARK: - Internal State Tracking
    private var currentState: PullupPhase = .starting
    private var previousState: PullupPhase = .starting
    private var feedback: String = "Hang from bar, arms extended."
    private(set) var repCount: Int = 0
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = [] // Track joints with issues
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    // Form quality tracking
    private var formScores: [Double] = []
    private var formIssues: [String] = []

    // State tracking for rep evaluation
    private var maxElbowAngleThisRep: CGFloat = 0.0      // Track max angle for extension check
    private var minElbowAngleThisRep: CGFloat = 180.0    // Track min angle during UP phase for rep check
    private var chinWasAboveBarThisRep: Bool = false     // Track if chin cleared bar during UP phase
    private var startingHipY: CGFloat? = nil             // Initial hip Y for kipping check
    private var minHipYThisRep: CGFloat = 1.0            // Track min/max hip Y during rep
    private var maxHipYThisRep: CGFloat = 0.0
    private var stableFrameCounter: Int = 0
    private var framesInPosition: Int = 0
    private var repInProgress: Bool = false              // Flag when moving from DOWN state
    
    // New tracking variables for form checks
    private var prevLeftKneeAngle: CGFloat? = nil
    private var prevRightKneeAngle: CGFloat? = nil
    private var prevLeftAnkleY: CGFloat? = nil
    private var prevRightAnkleY: CGFloat? = nil
    private var minKneeAngleThisRep: CGFloat = 180.0
    private var groundContactDetected: Bool = false

    // MARK: - Protocol Properties
    var currentPhaseDescription: String {
        switch currentState {
        case .down: return "Down (Hang)"
        case .up: return "Up (Chin Above)"
        case .starting: return "Ready"
        case .invalid: return "Invalid Pose"
        case .between: return "Moving"
        }
    }
    
    var formQualityAverage: Double {
        guard !formScores.isEmpty else { return 0.0 }
        return formScores.reduce(0.0, +) / Double(formScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }

    // MARK: - Protocol Methods
    func resetState() {
        currentState = .starting
        previousState = .starting
        feedback = "Hang from bar, arms extended."
        repCount = 0
        formScores = []
        formIssues = []
        _lastFormIssue = nil
        _problemJoints = [] // Reset problem joints
        resetRepTrackingState()
        stableFrameCounter = 0
        framesInPosition = 0
        repInProgress = false
        startingHipY = nil
        prevLeftKneeAngle = nil
        prevRightKneeAngle = nil
        prevLeftAnkleY = nil
        prevRightAnkleY = nil
        minKneeAngleThisRep = 180.0
        groundContactDetected = false
        print("PullupGrader: State reset.")
    }

    private func resetRepTrackingState() {
        maxElbowAngleThisRep = 0.0
        minElbowAngleThisRep = 180.0
        chinWasAboveBarThisRep = false
        // Don't reset startingHipY here, only on first valid frame or full reset
        minHipYThisRep = 1.0
        maxHipYThisRep = 0.0
        minKneeAngleThisRep = 180.0
        groundContactDetected = false
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback
        formIssues.removeAll()
        _problemJoints = [] // Reset problem joints for this frame
        
        // Keep track of previous state
        previousState = currentState

        // 1. Check Required Joint Confidence
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .nose,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        
        if !PoseValidationHelper.isFullBodyVisible(body, requiredJoints: requiredJoints, confidence: PullupGrader.requiredJointConfidence) {
            updateState(to: .invalid, stable: false)
            feedback = "Warning: Please position your entire body in the frame."
            _lastFormIssue = feedback
            return .invalidPose(reason: feedback)
        }

        // Extract validated points
        let leftShoulder = body.point(.leftShoulder)!
        let rightShoulder = body.point(.rightShoulder)!
        let leftElbow = body.point(.leftElbow)!
        let rightElbow = body.point(.rightElbow)!
        let leftWrist = body.point(.leftWrist)!
        let rightWrist = body.point(.rightWrist)!
        let nose = body.point(.nose)!
        let leftHip = body.point(.leftHip)!
        let rightHip = body.point(.rightHip)!
        let leftKnee = body.point(.leftKnee)!
        let rightKnee = body.point(.rightKnee)!
        let leftAnkle = body.point(.leftAnkle)!
        let rightAnkle = body.point(.rightAnkle)!

        // 2. Calculate Key Angles & Positions
        let leftElbowAngle = calculateAngle(point1: leftShoulder.location, centerPoint: leftElbow.location, point2: leftWrist.location)
        let rightElbowAngle = calculateAngle(point1: rightShoulder.location, centerPoint: rightElbow.location, point2: rightWrist.location)
        let avgElbowAngle = averageAngle(leftElbowAngle, rightElbowAngle) ?? 0.0 // Default bent
        
        // Calculate knee angles
        let leftKneeAngle = calculateAngle(point1: leftHip.location, centerPoint: leftKnee.location, point2: leftAnkle.location)
        let rightKneeAngle = calculateAngle(point1: rightHip.location, centerPoint: rightKnee.location, point2: rightAnkle.location)

        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2.0
        let noseY = nose.location.y
        let chinIsAboveBar = noseY < (avgWristY - PullupGrader.chinAboveBarMinYDiff) // Smaller Y is higher

        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2.0
        let avgAnkleY = (leftAnkle.location.y + rightAnkle.location.y) / 2.0

        // Set starting hip position on first valid frame in starting/down state
        if startingHipY == nil && (currentState == .starting || currentState == .down) && avgElbowAngle >= PullupGrader.elbowAngleDownMin * 0.95 {
             startingHipY = avgHipY
        }

        // Check for pausing too long
        if currentState == previousState {
            framesInPosition += 1
            if framesInPosition > PullupGrader.pauseFrameThreshold {
                formIssues.append("Paused too long")
                // No specific joint to highlight for pause
            }
        } else {
            framesInPosition = 0
        }
        
        // Check for knee bending/kicking
        if let prevLeftAngle = prevLeftKneeAngle, let prevRightAngle = prevRightKneeAngle {
            let leftKneeChange = abs(leftKneeAngle - prevLeftAngle)
            let rightKneeChange = abs(rightKneeAngle - prevRightAngle)
            
            if leftKneeChange > PullupGrader.kneeBendingThreshold || rightKneeChange > PullupGrader.kneeBendingThreshold {
                formIssues.append("Knee kicking detected")
                _problemJoints.insert(.leftKnee)
                _problemJoints.insert(.rightKnee)
            }
        }
        
        // Check for ground contact (sudden ankle movement)
        if let prevLeftY = prevLeftAnkleY, let prevRightY = prevRightAnkleY {
            let leftAnkleShift = abs(leftAnkle.location.y - prevLeftY)
            let rightAnkleShift = abs(rightAnkle.location.y - prevRightY)
            
            if leftAnkleShift > PullupGrader.ankleYShiftThreshold || rightAnkleShift > PullupGrader.ankleYShiftThreshold {
                formIssues.append("Feet touching ground")
                _problemJoints.insert(.leftAnkle)
                _problemJoints.insert(.rightAnkle)
                groundContactDetected = true
            }
        }

        // 1. Determine potential state.
        var potentialState: PullupPhase
        if chinIsAboveBar {
            potentialState = .up
            // STATE TRANSITION: Moving to UP state (chin above bar)
        } else if avgElbowAngle >= PullupGrader.elbowAngleDownMin {
            potentialState = .down
            // STATE TRANSITION: Moving to DOWN state (arms extended)
        } else {
            potentialState = .between
            // STATE TRANSITION: In between positions
        }

        // Update stable state - only change state after sufficient stable frames
        updateState(to: potentialState)

        // Start tracking rep if moving from DOWN state
        if previousState == .down && currentState != .down && !repInProgress {
            repInProgress = true
            resetRepTrackingState() // Reset tracking for the new rep attempt
            if startingHipY == nil { startingHipY = avgHipY } // Capture hip starting Y if missed
        }

        // Track angles and positions during the rep
        if repInProgress {
            // STATE TRACKING: Recording key metrics during rep
            maxElbowAngleThisRep = max(maxElbowAngleThisRep, avgElbowAngle)
            minElbowAngleThisRep = min(minElbowAngleThisRep, avgElbowAngle) // Track min angle too
            if chinIsAboveBar { chinWasAboveBarThisRep = true }
            minHipYThisRep = min(minHipYThisRep, avgHipY)
            maxHipYThisRep = max(maxHipYThisRep, avgHipY)
            minKneeAngleThisRep = min(minKneeAngleThisRep, min(leftKneeAngle, rightKneeAngle))
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        var gradingResult: GradingResult = .noChange
        
        if previousState == .up && currentState == .down && stableFrameCounter >= PullupGrader.requiredStableFrames && repInProgress {
            // STATE TRANSITION: UP to DOWN (stable) = rep completion
            var repFormIssues: [String] = []
            
            // a) Check Full Extension (using max angle achieved during rep)
            if maxElbowAngleThisRep < PullupGrader.elbowAngleDownMin {
                repFormIssues.append("Full hang between reps")
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            }
            
            // b) Check Chin Over Bar (must have been true at some point during UP)
            if !chinWasAboveBarThisRep {
                repFormIssues.append("Pull higher - chin must clear bar")
                _problemJoints.insert(.nose)
            }
            
            // c) Check Kipping (Hip Y travel)
            let hipTravel = maxHipYThisRep - minHipYThisRep
            // Estimate body height (shoulder to hip) for normalization
            let bodyHeightEstimate = abs(leftShoulder.location.y - leftHip.location.y) + abs(rightShoulder.location.y - rightHip.location.y) / 2.0
            if startingHipY != nil && bodyHeightEstimate > 0.1 && (hipTravel / bodyHeightEstimate) > PullupGrader.kippingMaxHipYTravel {
                repFormIssues.append("No kipping or swinging")
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
            }
            
            // d) Check Minimum Elbow Bend during Up phase
            if minElbowAngleThisRep > PullupGrader.elbowAngleUpRepCheckMax {
                repFormIssues.append("Arms not bent enough at top")
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            }
            
            // e) Check for knee bending during rep
            if minKneeAngleThisRep < 160.0 {
                repFormIssues.append("Keep legs straight")
                _problemJoints.insert(.leftKnee)
                _problemJoints.insert(.rightKnee)
            }
            
            // f) Check for ground contact during rep
            if groundContactDetected {
                repFormIssues.append("No ground contact during rep")
                _problemJoints.insert(.leftAnkle)
                _problemJoints.insert(.rightAnkle)
            }
            
            // Now, only count the rep if there are no form issues
            if repFormIssues.isEmpty && formIssues.isEmpty {
                repCount += 1
                formScores.append(1.0) // Perfect form
                feedback = "Good rep!"
                gradingResult = .repCompleted(formQuality: 1.0)
            } else {
                // Combine all issues, but prioritize rep-specific issues
                let allIssues = repFormIssues.isEmpty ? formIssues : repFormIssues
                feedback = allIssues.first ?? "Incorrect form"
                _lastFormIssue = feedback
                gradingResult = .incorrectForm(feedback: feedback)
            }
            
            // Reset tracking for the next rep attempt
            repInProgress = false
            resetRepTrackingState()
        } else {
            // Ongoing form checks during the rep
            // Position-specific form checks
            if currentState == .down && avgElbowAngle < PullupGrader.elbowAngleDownMin {
                formIssues.append("Full hang between reps")
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            } 
            
            if currentState == .up && !chinIsAboveBar {
                formIssues.append("Pull higher - chin must clear bar")
                _problemJoints.insert(.nose)
            }
            
            // Provide feedback on current form issues
            if !formIssues.isEmpty {
                feedback = formIssues.first ?? ""
                _lastFormIssue = feedback
                gradingResult = .incorrectForm(feedback: feedback)
            } else {
                // General guidance if no form issues
                gradingResult = .inProgress(phase: currentPhaseDescription)
                if feedback.isEmpty {
                    switch currentState {
                    case .down: feedback = "Pull up"
                    case .up: feedback = "Lower down slowly"
                    case .starting: feedback = "Begin when ready"
                    case .between:
                        if previousState == .down { feedback = "Pulling up..." }
                        else if previousState == .up { feedback = "Lowering..." }
                        else { feedback = "Keep moving"}
                    case .invalid: feedback = "Fix pose"
                    }
                }
            }
        }
        
        // Update tracking variables for next frame
        prevLeftKneeAngle = leftKneeAngle
        prevRightKneeAngle = rightKneeAngle
        prevLeftAnkleY = leftAnkle.location.y
        prevRightAnkleY = rightAnkle.location.y

        return gradingResult
    }

    // Calculate angle between three points
    private func calculateAngle(point1: CGPoint, centerPoint: CGPoint, point2: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: point1.x - centerPoint.x, y: point1.y - centerPoint.y)
        let v2 = CGPoint(x: point2.x - centerPoint.x, y: point2.y - centerPoint.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let cross = v1.x * v2.y - v1.y * v2.x
        
        let angleDegrees = atan2(cross, dot) * 180.0 / .pi
        return abs(angleDegrees)
    }

    // Update state only if stable for enough frames
    private func updateState(to newState: PullupPhase, stable: Bool = true) {
        if newState == currentState {
            if stable { stableFrameCounter += 1 }
        } else {
            stableFrameCounter = 0
            // Only change if required frames met OR the new state is invalid
            // Also allow immediate transition *out* of invalid state
            if !stable || stableFrameCounter >= PullupGrader.requiredStableFrames || newState == .invalid || currentState == .invalid || currentState == .starting {
                currentState = newState
            } // else: keep current state until stability threshold is met
        }
    }

    // Helper to average angles
    private func averageAngle(_ angle1: CGFloat?, _ angle2: CGFloat?) -> CGFloat? {
        switch (angle1, angle2) {
        case (.some(let a1), .some(let a2)): return (a1 + a2) / 2.0
        case (.some(let a1), .none): return a1
        case (.none, .some(let a2)): return a2
        case (.none, .none): return nil
        }
    }
    
    func calculateFinalScore() -> Double? {
        // If no reps completed, return nil
        guard repCount > 0 else { return nil }
        
        // Base score is rep count * 10 (max 100)
        let maxReps = 10 // 10 reps = 100 points
        let repScore = min(Double(repCount) / Double(maxReps), 1.0) * 85.0 // 85% of score is rep count
        
        // Form quality contributes up to 15% of score
        let formScore = formQualityAverage * 15.0
        
        // Total score combines rep count and form quality
        return min(repScore + formScore, 100.0)
    }
}
