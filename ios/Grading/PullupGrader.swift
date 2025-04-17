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
    private let elbowAngleDownMin: CGFloat = 155.0  // Min angle to be considered fully extended ('down')
    private let elbowAngleUpMax: CGFloat = 95.0    // Max angle to be considered significantly bent ('up')
    // Vertical distance threshold: Nose Y must be *above* Wrist Y by this amount (normalized)
    // Note: In Vision coordinates (0,0 is bottom-left), smaller Y is higher.
    private let chinAboveBarMinYDiff: CGFloat = 0.04
    // Max allowed vertical hip movement relative to shoulder height (normalized) - very basic kipping check
    private let kippingMaxHipYTravel: CGFloat = 0.15
    private let requiredConfidence: Float = 0.4

    // State tracking for rep evaluation & stability
    private var maxElbowAngleThisRep: CGFloat = 0.0      // Track max angle for extension check
    private var chinWasAboveBarThisRep: Bool = false   // Track if chin cleared bar during UP phase
    private var startingHipY: CGFloat? = nil         // Initial hip Y for kipping check
    private var minHipYThisRep: CGFloat = 1.0          // Track min/max hip Y during rep
    private var maxHipYThisRep: CGFloat = 0.0
    private var stableFrameCounter: Int = 0
    private let requiredStableFrames: Int = 2 // Frames needed to confirm state change
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
        chinWasAboveBarThisRep = false
        // Don't reset startingHipY here, only on first valid frame or full reset
        minHipYThisRep = 1.0
        maxHipYThisRep = 0.0
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback

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
                missingJoints.append(jointName.rawValue.description)
                continue
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

        // --- State Machine Logic --- 
        let previousState = currentState
        var detectedState: PullupPhase

        // Determine potential state
        if avgElbowAngle >= elbowAngleDownMin {
            detectedState = .down
        } else if avgElbowAngle <= elbowAngleUpMax && chinIsAboveBar {
            detectedState = .up
        } else {
            // Could be moving up or down
            detectedState = .between
        }

        // Update stable state
        updateState(to: detectedState)

        // Start tracking rep if moving from DOWN state
        if previousState == .down && currentState != .down && !repInProgress {
            repInProgress = true
            resetRepTrackingState() // Reset tracking for the new rep attempt
             if startingHipY == nil { startingHipY = avgHipY } // Capture hip starting Y if missed
        }

        // Track angles and positions during the rep
        if repInProgress {
            maxElbowAngleThisRep = max(maxElbowAngleThisRep, avgElbowAngle)
            if chinIsAboveBar { chinWasAboveBarThisRep = true }
            minHipYThisRep = min(minHipYThisRep, avgHipY)
            maxHipYThisRep = max(maxHipYThisRep, avgHipY)
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        var gradingResult: GradingResult = .noChange
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
             if gradingResult == .inProgress(phase: currentPhaseDescription) || gradingResult == .noChange {
                  feedback = "Extend arms fully."
                  gradingResult = .incorrectForm(feedback: feedback)
             }
         } else if currentState == .up && !chinIsAboveBar {
             if gradingResult == .inProgress(phase: currentPhaseDescription) || gradingResult == .noChange {
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
}
