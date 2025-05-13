import Foundation
import Vision
import CoreGraphics
import Combine // For ObservableObject

final class PullupGrader: ObservableObject, ExerciseGraderProtocol {

    // MARK: - Static Thresholds (Accessible for Unit Testing)
    // FPS setting - helps adjust required stable frames
    static var targetFramesPerSecond: Double = 30.0 // Target frame rate (default 30fps)
    
    // Required confidence for joint positions
    static var requiredJointConfidence: Float = 0.6
    
    // Required stable frames
    static var requiredStableFrames: Int = 3
    
    // Angle thresholds
    static let elbowAngleDownMin: CGFloat = 160.0  // Min angle to be considered fully extended ('down')
    static let elbowAngleUpRepCheckMax: CGFloat = 90.0 // Minimum bend required during UP phase for rep check
    
    // Position thresholds
    static let chinAboveBarMinYDiff: CGFloat = 0.05 // Vertical distance threshold: Nose Y must be *above* Wrist Y
    static let kippingMaxHipYTravel: CGFloat = 0.10 // Max allowed vertical hip movement for kipping check
    static let chinHeightThreshold: CGFloat = 0.05  // Wrists this much (or less) *above* shoulders counts as "up"
    static let elbowShoulderDeadHangThreshold: CGFloat = 0.20 // Wrists this much (or more) *below* shoulders is "down"

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
    private var repInProgress: Bool = false              // Flag when moving from DOWN state

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
        feedback = "Hang from bar, arms extended."
        repCount = 0
        formScores = []
        formIssues = []
        _lastFormIssue = nil
        _problemJoints = [] // Reset problem joints
        resetRepTrackingState()
        stableFrameCounter = 0
        repInProgress = false
        startingHipY = nil
        print("PullupGrader: State reset.")
    }

    private func resetRepTrackingState() {
        maxElbowAngleThisRep = 0.0
        minElbowAngleThisRep = 180.0
        chinWasAboveBarThisRep = false
        // Don't reset startingHipY here, only on first valid frame or full reset
        minHipYThisRep = 1.0
        maxHipYThisRep = 0.0
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback
        formIssues.removeAll()
        _problemJoints = [] // Reset problem joints for this frame

        // Keep a snapshot of the state before analysing this frame
        let previousState = currentState
        // Default grading outcome; will be updated below
        var gradingResult: GradingResult = .noChange

        // 1. Check Required Joint Confidence
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip, // Needed for kipping check
            .nose // Needed for chin height check
        ]
        
        // Use body's helper method to check missing joints
        let missingJoints = body.missingJoints(from: keyJoints, minConfidence: PullupGrader.requiredJointConfidence)
        
        if !missingJoints.isEmpty {
            updateState(to: .invalid, stable: false)
            
            #if DEBUG
            let missingJointNames = missingJoints.map { 
                String(describing: $0).replacingOccurrences(of: "VNHumanBodyPoseObservation.JointName.", with: "") 
            }
            feedback = "Cannot see clearly: \(missingJointNames.joined(separator: ", "))"
            #else
            feedback = "Cannot detect full body - adjust position or camera angle"
            #endif
            
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

        // 2. Calculate Key Angles & Positions
        let leftElbowAngle = calculateAngle(point1: leftShoulder.location, centerPoint: leftElbow.location, point2: leftWrist.location)
        let rightElbowAngle = calculateAngle(point1: rightShoulder.location, centerPoint: rightElbow.location, point2: rightWrist.location)
        let avgElbowAngle = averageAngle(leftElbowAngle, rightElbowAngle) ?? 0.0 // Default bent

        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2.0
        let noseY = nose.location.y
        let chinIsAboveBar = noseY < (avgWristY - PullupGrader.chinAboveBarMinYDiff) // Smaller Y is higher

        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2.0

        // Set starting hip position on first valid frame in starting/down state
        if startingHipY == nil && (currentState == .starting || currentState == .down) && avgElbowAngle >= PullupGrader.elbowAngleDownMin * 0.95 {
             startingHipY = avgHipY
        }

        // Establish a shoulder‑level reference for relative Y‑position checks
        let shoulderReferenceY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0

        // 1. Determine potential state.
        // STATE TRANSITION: We consider "up" when the chin clears the bar (chinIsAboveBar).
        // STATE TRANSITION: We consider "down" when the elbows are almost fully extended.
        var potentialState: PullupPhase = currentState
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

        // Update current state
        currentState = potentialState

        // 2. Check for Rep Completion: Transitioned from Down to Up
        if previousState == .down && currentState == .up {
            // STATE TRANSITION: DOWN to UP = potential rep start
            repCount += 1
            
            // Default to perfect form for now, will calculate more precisely at end of rep
            let formQuality = 1.0
            
            gradingResult = .repCompleted(formQuality: formQuality)
            feedback = "Rep started! Pull complete. (\(repCount))"
            print("⚙️ Pullup rep \(repCount) scored \(formQuality * 100)%")
        } else {
            // Provide feedback based on state if no rep was just counted
            switch currentState {
            case .up: feedback = "Lower yourself"
            case .down: feedback = "Pull up"
            case .starting: feedback = "Begin pull-ups"
            case .between: feedback = "Keep moving"
            case .invalid: feedback = "Fix pose"
            }
            
            // Update grading result if still in progress
            if case .noChange = gradingResult {
                gradingResult = .inProgress(phase: currentPhaseDescription)
            }
        }

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
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        if previousState == .up && currentState == .down && repInProgress {
            // STATE TRANSITION: UP to DOWN = rep completion
            var repFormIssues: [String] = []
            var formQuality: Double = 1.0 // Start with perfect score

            // a) Check Full Extension (using max angle achieved during rep)
            if maxElbowAngleThisRep < PullupGrader.elbowAngleDownMin {
                repFormIssues.append("Extend arms fully at bottom")
                formQuality -= 0.2
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            }
            
            // b) Check Chin Over Bar (must have been true at some point during UP)
            if !chinWasAboveBarThisRep {
                 repFormIssues.append("Chin did not clear bar")
                 formQuality -= 0.3
                 _problemJoints.insert(.nose)
                 _problemJoints.insert(.neck)
            }
            
            // c) Check Kipping (Hip Y travel)
            let hipTravel = maxHipYThisRep - minHipYThisRep
            // Estimate body height (shoulder to hip) for normalization - crude approximation
            let bodyHeightEstimate = abs(leftShoulder.location.y - leftHip.location.y) + abs(rightShoulder.location.y - rightHip.location.y) / 2.0
            if startingHipY != nil && bodyHeightEstimate > 0.1 && (hipTravel / bodyHeightEstimate) > PullupGrader.kippingMaxHipYTravel {
                 repFormIssues.append("Excessive hip movement (kipping)")
                 formQuality -= 0.3
                 _problemJoints.insert(.leftHip)
                 _problemJoints.insert(.rightHip)
            }
            
            // d) Check Minimum Elbow Bend during Up phase
            if minElbowAngleThisRep > PullupGrader.elbowAngleUpRepCheckMax {
                 repFormIssues.append("Arms not bent enough at top")
                 formQuality -= 0.2
                 _problemJoints.insert(.leftElbow)
                 _problemJoints.insert(.rightElbow)
            }
            
            // Apply minimum quality floor and add to form tracking
            formQuality = max(0.3, formQuality)
            formScores.append(formQuality)

            if repFormIssues.isEmpty {
                feedback = "Good rep! (\(repCount))"
                gradingResult = .repCompleted(formQuality: formQuality)
            } else {
                feedback = repFormIssues.joined(separator: ". ")
                _lastFormIssue = feedback
                gradingResult = .repCompleted(formQuality: formQuality)
            }
            
            // Reset tracking for the next rep attempt, mark rep as no longer in progress
            repInProgress = false
            resetRepTrackingState()
            // Don't reset startingHipY unless fully resetting

        } else {
            // Provide general feedback if no rep completed
            if case .noChange = gradingResult {
                gradingResult = .inProgress(phase: currentPhaseDescription)
            }
            
            if feedback.isEmpty { // Avoid overwriting specific form issue feedback
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

         // Immediate feedback on current position if needed
         if currentState == .down && avgElbowAngle < PullupGrader.elbowAngleDownMin {
             // Form issue while in DOWN position
             feedback = "Extend arms fully"
             _lastFormIssue = feedback
             _problemJoints.insert(.leftElbow)
             _problemJoints.insert(.rightElbow)
             gradingResult = .incorrectForm(feedback: feedback)
         } else if currentState == .up && !chinIsAboveBar {
             // Form issue while in UP position
             feedback = "Pull higher!"
             _lastFormIssue = feedback
             _problemJoints.insert(.nose)
             _problemJoints.insert(.neck)
             gradingResult = .incorrectForm(feedback: feedback)
         }

        return gradingResult
    }

    // Update state only if stable for enough frames
    private func updateState(to newState: PullupPhase, stable: Bool = true) {
        if newState == currentState {
            if stable { stableFrameCounter += 1 }
        } else {
            // Only change if required frames met OR the new state is invalid
            // Also allow immediate transition *out* of invalid state
            if !stable || stableFrameCounter >= PullupGrader.requiredStableFrames || newState == .invalid || currentState == .invalid {
                 // Reset counter only if the state *actually* changes
                 if currentState != newState { stableFrameCounter = 0 }
                 currentState = newState
            } // else: keep current state until stability threshold is met
        }
    }

    // Helper to average angles
     private func averageAngle(_ angle1: CGFloat?, _ angle2: CGFloat?) -> CGFloat? {
         switch (angle1, angle2) {
         case (.some(let a1), .some(let a2): return (a1 + a2) / 2.0
         case (.some(let a1), .none): return a1
         case (.none, .some(let a2): return a2
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
