import Foundation
import Vision
import CoreGraphics

class PullupGrader: ExerciseGraderProtocol {

    private enum PullupPhase {
        case down // Arms fully extended hanging
        case up   // Chin above the bar
        case starting
        case invalid
        case between // Transitioning
    }

    private var currentState: PullupPhase = .starting
    private var feedback: String = "Hang from bar, arms extended."
    private var repCount: Int = 0

    // Configuration Thresholds (tune based on testing!)
    private let elbowAngleDownMin: CGFloat = 160.0  // Min angle to be considered fully extended ('down') (Aligned w/ Android)
    // Removed elbowAngleUpMax - UP state depends on chin height (Aligned w/ Android)
    // Vertical distance threshold: Nose Y must be *above* Wrist Y by this amount (normalized)
    // Note: In Vision coordinates (0,0 is bottom-left), smaller Y is higher.
    private let chinAboveBarMinYDiff: CGFloat = 0.05 // Aligned w/ Android
    // Max allowed vertical hip movement relative to shoulder height (normalized) - basic kipping check
    private let kippingMaxHipYTravel: CGFloat = 0.10 // Aligned w/ Android
    private let requiredConfidence: Float = 0.6 // Aligned w/ Android
    // Minimum bend required during UP phase for rep check
    private let elbowAngleUpRepCheckMax: CGFloat = 90.0 // Aligned w/ Android MIN_BEND_THRESHOLD

    // Additional thresholds that were referenced but not previously declared
    // Relative scale (multiplicative) factors applied to shoulder Y reference when classifying states.
    // Tuned empirically; feel free to adjust during real‑world testing.
    private let chinHeightThreshold: CGFloat = 0.05          // wrists this much (or less) *above* shoulders counts as "up"
    private let elbowShoulderDeadHangThreshold: CGFloat = 0.20 // wrists this much (or more) *below* shoulders counts as "down"

    // Form‑tracking helpers that were referenced but never declared
    private var formIssues: [String] = []
    private var formScore: Int = 100

    // State tracking for rep evaluation & stability
    private var maxElbowAngleThisRep: CGFloat = 0.0      // Track max angle for extension check
    private var minElbowAngleThisRep: CGFloat = 180.0    // Track min angle during UP phase for rep check
    private var chinWasAboveBarThisRep: Bool = false   // Track if chin cleared bar during UP phase
    private var startingHipY: CGFloat? = nil         // Initial hip Y for kipping check
    private var minHipYThisRep: CGFloat = 1.0          // Track min/max hip Y during rep
    private var maxHipYThisRep: CGFloat = 0.0
    private var stableFrameCounter: Int = 0
    private let requiredStableFrames: Int = 3 // Frames needed to confirm state change (Aligned w/ Android)
    private var repInProgress: Bool = false // Flag when moving from DOWN state

    var currentPhaseDescription: String {
        switch currentState {
        case .down: return "Down (Hang)"
        case .up: return "Up (Chin Above)"
        case .starting: return "Ready"
        case .invalid: return "Invalid Pose"
        case .between: return "Moving"
        }
    }

    func resetState() {
        currentState = .starting
        feedback = "Hang from bar, arms extended."
        repCount = 0
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
        var missingJoints: [String] = []
        for jointName in keyJoints {
            guard let point = body.point(jointName), point.confidence >= requiredConfidence else {
                missingJoints.append(jointName.rawValue.rawValue)
                continue // Check all missing joints
            }
        }
        if !missingJoints.isEmpty {
            updateState(to: .invalid, stable: false)
            feedback = "Cannot see clearly: \(missingJoints.joined(separator: ", "))"
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
        let chinIsAboveBar = noseY < (avgWristY - chinAboveBarMinYDiff) // Smaller Y is higher

        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2.0

        // Set starting hip position on first valid frame in starting/down state
        if startingHipY == nil && (currentState == .starting || currentState == .down) && avgElbowAngle >= elbowAngleDownMin * 0.95 {
             startingHipY = avgHipY
        }

        // Establish a shoulder‑level reference for relative Y‑position checks
        let shoulderReferenceY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0

        // 1. Determine potential state.
        // We consider "up" when the chin clears the bar (chinIsAboveBar).
        // We consider "down" when the elbows are almost fully extended.
        var potentialState: PullupPhase = currentState
        if chinIsAboveBar {
            potentialState = .up
        } else if avgElbowAngle >= elbowAngleDownMin {
            potentialState = .down
        } else {
            potentialState = .between
        }

        currentState = potentialState

        // 2. Check for Rep Completion: Transitioned from Down to Up
        if previousState == .down && currentState == .up {
            repCount += 1
            gradingResult = .repCompleted
            feedback = "Rep Counted! (\(repCount))"
        } else {
            // Provide feedback based on state if no rep was just counted
            switch currentState {
            case .up: feedback = "Lower yourself."
            case .down: feedback = "Pull up."
            case .starting: feedback = "Begin pull-ups."
            case .between: feedback = "Keep moving."
            case .invalid: feedback = "Fix pose."
            }
            // Use if-case to check GradingResult without needing Equatable conformance
            if case .inProgress(let phase) = gradingResult {
                 print("Still in progress: \(phase)") // Example placeholder
            } else if case .noChange = gradingResult {
                 gradingResult = .inProgress(phase: currentPhaseDescription) // Update if still just in progress
            }

        }
        // Update form score (simple pass/fail for now)
        formScore = formIssues.isEmpty ? 100 : 0 // Penalize fully for any form issue

        // Add specific form feedback if issues exist
        if !formIssues.isEmpty {
            feedback = formIssues.joined(separator: " ")
            // Use if-case to check GradingResult without needing Equatable conformance
            if case .inProgress(let phase) = gradingResult {
                 print("Still in progress with form issues: \(phase)") // Example placeholder
            } else if case .noChange = gradingResult {
                 gradingResult = .incorrectForm(feedback: feedback)
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
            maxElbowAngleThisRep = max(maxElbowAngleThisRep, avgElbowAngle)
            minElbowAngleThisRep = min(minElbowAngleThisRep, avgElbowAngle) // Track min angle too
            if chinIsAboveBar { chinWasAboveBarThisRep = true }
            minHipYThisRep = min(minHipYThisRep, avgHipY)
            maxHipYThisRep = max(maxHipYThisRep, avgHipY)
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        if previousState == .up && currentState == .down && repInProgress {
            var repFormIssues: [String] = []

            // a) Check Full Extension (using max angle achieved during rep)
            if maxElbowAngleThisRep < elbowAngleDownMin {
                repFormIssues.append("Extend arms fully at bottom.")
            }
            // b) Check Chin Over Bar (must have been true at some point during UP)
            if !chinWasAboveBarThisRep {
                 repFormIssues.append("Chin did not clear bar.")
            }
            // c) Check Kipping (Hip Y travel)
            let hipTravel = maxHipYThisRep - minHipYThisRep
            // Estimate body height (shoulder to hip) for normalization - crude approximation
            let bodyHeightEstimate = abs(leftShoulder.location.y - leftHip.location.y) + abs(rightShoulder.location.y - rightHip.location.y) / 2.0
            if startingHipY != nil && bodyHeightEstimate > 0.1 && (hipTravel / bodyHeightEstimate) > kippingMaxHipYTravel {
                 repFormIssues.append("Excessive hip movement (kipping).")
            }
            // d) Check Minimum Elbow Bend during Up phase (Aligned w/ Android)
            if minElbowAngleThisRep > elbowAngleUpRepCheckMax {
                 repFormIssues.append("Arms not bent enough at top.")
            }

            if repFormIssues.isEmpty {
                repCount += 1
                feedback = "Rep Counted! (\(repCount))"
                gradingResult = .repCompleted
            } else {
                feedback = repFormIssues.joined(separator: " ")
                gradingResult = .incorrectForm(feedback: feedback)
            }
            // Reset tracking for the next rep attempt, mark rep as no longer in progress
            repInProgress = false
            resetRepTrackingState()
            // Don't reset startingHipY unless fully resetting

        } else {
            // Provide general feedback if no rep completed
            gradingResult = .inProgress(phase: currentPhaseDescription)
             if feedback.isEmpty { // Avoid overwriting specific form issue feedback
                 switch currentState {
                 case .down: feedback = "Pull up."
                 case .up: feedback = "Lower down slowly."
                 case .starting: feedback = "Begin when ready."
                 case .between:
                     if previousState == .down { feedback = "Pulling up..." }
                     else if previousState == .up { feedback = "Lowering..." }
                     else { feedback = "Keep moving."}
                 case .invalid: feedback = "Fix pose."
                 }
            }
        }

         // Immediate feedback on current position if needed
         if currentState == .down && avgElbowAngle < elbowAngleDownMin {
             // Use if-case for comparison
             if case .inProgress = gradingResult {
                 feedback = "Extend arms fully."
                 gradingResult = .incorrectForm(feedback: feedback)
             } else if case .noChange = gradingResult {
                 feedback = "Extend arms fully."
                 gradingResult = .incorrectForm(feedback: feedback)
             }
         } else if currentState == .up && !chinIsAboveBar {
             // Use if-case for comparison
             if case .inProgress = gradingResult {
                 feedback = "Pull higher!"
                 gradingResult = .incorrectForm(feedback: feedback)
             } else if case .noChange = gradingResult {
                 feedback = "Pull higher!"
                 gradingResult = .incorrectForm(feedback: feedback)
             }
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
            if !stable || stableFrameCounter >= requiredStableFrames || newState == .invalid || currentState == .invalid {
                 // Reset counter only if the state *actually* changes
                 if currentState != newState { stableFrameCounter = 0 }
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
         // Simple score implementation based on form quality
         return Double(formScore)
     }
}
