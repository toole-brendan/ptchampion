import Foundation
import Vision
import CoreGraphics

class SitupGrader: ExerciseGraderProtocol {

    private enum SitupPhase {
        case down // Back relatively flat
        case up   // Torso significantly raised, elbows near thighs
        case starting
        case invalid
        case between // Transitioning
    }

    private var currentState: SitupPhase = .starting
    private var feedback: String = "Lie down, arms crossed, knees bent."
    private var repCount: Int = 0

    // Configuration Thresholds (tune based on testing!)
    private let hipAngleDownMin: CGFloat = 140.0  // Min hip angle to be considered 'down'
    private let hipAngleUpMax: CGFloat = 90.0    // Max hip angle to be considered fully 'up'
    // Threshold for vertical distance between elbow and knee (normalized Y)
    private let elbowKneeProximityMaxY: CGFloat = 0.15
    // Threshold for wrist distance to opposite shoulder (normalized)
    private let armsCrossedMaxDist: CGFloat = 0.20
    private let requiredConfidence: Float = 0.4

    // State tracking for rep evaluation & stability
    private var maxHipAngleThisRep: CGFloat = 0.0      // Track max angle when down
    private var minHipAngleThisRep: CGFloat = 180.0    // Track min angle when up
    private var armsWereCrossedThisRep: Bool = false   // Track arm position during UP phase
    private var stableFrameCounter: Int = 0
    private let requiredStableFrames: Int = 2 // Frames needed to confirm state change

    var currentPhaseDescription: String {
        switch currentState {
        case .down: return "Down"
        case .up: return "Up"
        case .starting: return "Ready"
        case .invalid: return "Invalid Pose"
        case .between: return "Moving"
        }
    }

    func resetState() {
        currentState = .starting
        feedback = "Lie down, arms crossed, knees bent."
        repCount = 0
        resetRepTrackingState()
        stableFrameCounter = 0
        print("SitupGrader: State reset.")
    }

    private func resetRepTrackingState() {
        maxHipAngleThisRep = 0.0
        minHipAngleThisRep = 180.0
        armsWereCrossedThisRep = false // Reset arm check for new rep
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback

        // 1. Check Required Joint Confidence
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee
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
        let leftHip = body.point(.leftHip)!
        let rightHip = body.point(.rightHip)!
        let leftKnee = body.point(.leftKnee)!
        let rightKnee = body.point(.rightKnee)!

        // 2. Calculate Key Angles & Distances
        let leftHipAngle = calculateAngle(point1: leftShoulder.location, centerPoint: leftHip.location, point2: leftKnee.location)
        let rightHipAngle = calculateAngle(point1: rightShoulder.location, centerPoint: rightHip.location, point2: rightKnee.location)
        let avgHipAngle = averageAngle(leftHipAngle, rightHipAngle) ?? 180.0

        let avgElbowY = (leftElbow.location.y + rightElbow.location.y) / 2.0
        let avgKneeY = (leftKnee.location.y + rightKnee.location.y) / 2.0
        let elbowKneeYDiff = abs(avgElbowY - avgKneeY)

        // 3. Form Check: Arms Crossed (Check distance from wrist to opposite shoulder)
        let leftWristToRightShoulder = distance(leftWrist.location, rightShoulder.location)
        let rightWristToLeftShoulder = distance(rightWrist.location, leftShoulder.location)
        let armsAreCrossed = (leftWristToRightShoulder < armsCrossedMaxDist && rightWristToLeftShoulder < armsCrossedMaxDist)

        // --- State Machine Logic --- 
        let previousState = currentState
        var detectedState: SitupPhase

        // Determine potential state based on angles/proximity
        if avgHipAngle >= hipAngleDownMin {
            detectedState = .down
        } else if avgHipAngle <= hipAngleUpMax && elbowKneeYDiff <= elbowKneeProximityMaxY {
            detectedState = .up
        } else {
            detectedState = .between
        }

        // Update stable state
        updateState(to: detectedState)

        // If state is invalid now (due to failed checks), return early
        guard currentState != .invalid else {
            // Feedback is already set by checks
            return .invalidPose(reason: feedback)
        }

        // Track min/max angles during the appropriate phases
        if currentState == .down || (previousState == .up && currentState == .between) {
            maxHipAngleThisRep = max(maxHipAngleThisRep, avgHipAngle)
        }
        if currentState == .up || (previousState == .down && currentState == .between) {
            minHipAngleThisRep = min(minHipAngleThisRep, avgHipAngle)
            // Check arm position specifically when in or moving towards UP state
            if armsAreCrossed { armsWereCrossedThisRep = true }
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        var gradingResult: GradingResult = .noChange
        if previousState == .up && currentState == .down {
            var repFormIssues: [String] = []
            // Check if up position was high enough
            if minHipAngleThisRep > hipAngleUpMax {
                repFormIssues.append("Sit up higher.")
            }
            // Check if arms were crossed during the UP phase
            if !armsWereCrossedThisRep {
                 repFormIssues.append("Keep arms crossed.")
            }
            // Optional: Check if down position was flat enough (using maxHipAngle from *previous* cycle if needed)
            // This might require more complex state tracking across reps.

            if repFormIssues.isEmpty {
                repCount += 1
                feedback = "Rep Counted! (\(repCount))"
                gradingResult = .repCompleted
            } else {
                feedback = repFormIssues.joined(separator: " ")
                gradingResult = .incorrectForm(feedback: feedback)
            }
            // Reset tracking for the next rep cycle
            resetRepTrackingState()

        } else {
            // Provide general feedback if no rep completed
            gradingResult = .inProgress(phase: currentPhaseDescription)
            if feedback.isEmpty { // Avoid overwriting specific form issue feedback
                 switch currentState {
                 case .down: feedback = "Sit up."
                 case .up: feedback = "Lower down."
                 case .starting: feedback = "Begin when ready."
                 case .between: feedback = "Keep moving."
                 case .invalid: feedback = "Fix pose."
                 }
            }
        }

        // Always check basic arm crossing form, even if not counting rep yet
         if !armsAreCrossed && currentState != .down && currentState != .starting {
             // Don't override rep completion/failure feedback
             if gradingResult == .inProgress(phase: currentPhaseDescription) || gradingResult == .noChange {
                feedback = "Keep arms crossed over chest."
                return .incorrectForm(feedback: feedback)
             }
         }

        return gradingResult
    }

    // Update state only if stable for enough frames
    private func updateState(to newState: SitupPhase, stable: Bool = true) {
        if newState == currentState {
            if stable { stableFrameCounter += 1 }
        } else {
            stableFrameCounter = 0
            // Only change if required frames met OR the new state is invalid
            if !stable || stableFrameCounter >= requiredStableFrames || newState == .invalid {
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

    // Helper to calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
} 