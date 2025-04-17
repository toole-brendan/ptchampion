import Foundation
import Vision
import CoreGraphics // For CGFloat, CGPoint

class PushupGrader: ExerciseGraderProtocol {

    // States reflecting the phases of a push-up
    private enum PushupState {
        case up             // Arms extended, top position
        case down           // Arms bent, bottom position
        case starting       // Initial position, waiting for movement
        case invalid        // Pose not suitable for grading (e.g., missing landmarks)
        case between       // Transitioning between up and down
    }

    private var currentState: PushupState = .starting
    private var feedback: String = "Get into push-up position."
    private var repCount: Int = 0 // Internal counter, VM reads final result

    // Configuration Thresholds (aligned with potential Kotlin version)
    // ** IMPORTANT: These need careful tuning based on testing! **
    private let elbowAngleDownMax: CGFloat = 100.0 // Max elbow angle considered 'down' (stricter than 95?)
    private let elbowAngleUpMin: CGFloat = 155.0   // Min elbow angle considered 'up'
    private let bodyStraightnessThreshold: CGFloat = 0.15 // Max deviation of hip from shoulder-ankle line (normalized Y)
    private let shoulderAlignmentMaxYDiff: CGFloat = 0.08 // Max normalized Y diff between shoulders
    private let requiredConfidence: Float = 0.4 // Min confidence for key joints

    // State tracking for rep evaluation
    private var minElbowAngleThisRep: CGFloat = 180.0
    private var wentLowEnoughThisRep: Bool = false

    var currentPhaseDescription: String {
        // Provide a simple description for the current internal state
        switch currentState {
        case .up: return "Up"
        case .down: return "Down"
        case .starting: return "Ready"
        case .invalid: return "Invalid Pose"
        case .between: return "Moving"
        }
    }

    func resetState() {
        currentState = .starting
        feedback = "Get into push-up position."
        minElbowAngleThisRep = 180.0
        wentLowEnoughThisRep = false
        repCount = 0 // Reset internal counter as well
        print("PushupGrader: State reset.")
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback for this frame

        // 1. Check Required Joint Confidence
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftAnkle, .rightAnkle // Ankles needed for body line check
        ]

        var missingJoints: [String] = []
        for jointName in keyJoints {
            guard let point = body.point(jointName), point.confidence >= requiredConfidence else {
                missingJoints.append(jointName.rawValue.description)
                continue // Check all missing joints
            }
        }

        if !missingJoints.isEmpty {
            currentState = .invalid
            feedback = "Cannot see clearly: \(missingJoints.joined(separator: ", "))"
            return .invalidPose(reason: feedback)
        }

        // Extract validated points (we know they exist now)
        let leftShoulder = body.point(.leftShoulder)!
        let rightShoulder = body.point(.rightShoulder)!
        let leftElbow = body.point(.leftElbow)!
        let rightElbow = body.point(.rightElbow)!
        let leftWrist = body.point(.leftWrist)!
        let rightWrist = body.point(.rightWrist)!
        let leftHip = body.point(.leftHip)!
        let rightHip = body.point(.rightHip)!
        let leftAnkle = body.point(.leftAnkle)!
        let rightAnkle = body.point(.rightAnkle)!

        // 2. Calculate Key Angles & Positions
        let leftElbowAngle = calculateAngle(point1: leftWrist.location, centerPoint: leftElbow.location, point2: leftShoulder.location)
        let rightElbowAngle = calculateAngle(point1: rightWrist.location, centerPoint: rightElbow.location, point2: rightShoulder.location)
        let avgElbowAngle = averageAngle(leftElbowAngle, rightElbowAngle) ?? 180.0 // Default to straight if calculation fails

        let avgShoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0
        let avgHipY = (leftHip.location.y + rightHip.location.y) / 2.0
        let avgAnkleY = (leftAnkle.location.y + rightAnkle.location.y) / 2.0

        // 3. Form Checks
        var formIssues: [String] = []

        // a) Shoulder alignment (Y-axis difference)
        let shoulderYDiff = abs(leftShoulder.location.y - rightShoulder.location.y)
        if shoulderYDiff > shoulderAlignmentMaxYDiff {
            formIssues.append("Keep shoulders level.")
        }

        // b) Body straightness (Hip deviation from shoulder-ankle line)
        // Project hip onto the shoulder-ankle line and check vertical distance
        let shoulderAnkleVector = (x: avgAnkleY - avgShoulderY, y: 0) // Use Y diff for vertical line approx.
        let shoulderHipVector = (x: avgHipY - avgShoulderY, y: 0)
        // Simplified check: Is hip Y between shoulder Y and ankle Y (assuming normal orientation)?
        // A more robust check involves line projection.
        let expectedHipY = avgShoulderY + (avgAnkleY - avgShoulderY) * 0.5 // Midpoint approx
        let hipDeviation = abs(avgHipY - expectedHipY) / abs(avgAnkleY - avgShoulderY + 1e-6) // Normalize by body length

        if hipDeviation > bodyStraightnessThreshold {
            if avgHipY > expectedHipY { // Hips lower than expected -> Sagging
                formIssues.append("Keep hips from sagging.")
            } else { // Hips higher than expected -> Piking
                formIssues.append("Avoid raising hips too high.")
            }
        }

        if !formIssues.isEmpty {
            currentState = .invalid // Treat form issues as invalid for rep counting
            feedback = formIssues.joined(separator: " ")
            return .incorrectForm(feedback: feedback)
        }

        // --- State Machine Logic --- 
        let previousState = currentState

        // Determine potential next state based on elbow angle
        var potentialState: PushupState
        if avgElbowAngle <= elbowAngleDownMax {
            potentialState = .down
        } else if avgElbowAngle >= elbowAngleUpMin {
            potentialState = .up
        } else {
            potentialState = .between // In transition
        }

        // Update current state
        currentState = potentialState

        // Track minimum angle during the down phase or transition towards it
        if currentState == .down || (previousState == .up && currentState == .between) {
            minElbowAngleThisRep = min(minElbowAngleThisRep, avgElbowAngle)
        }

        // Check if went low enough (only relevant if currently down or moving up from down)
        if currentState == .down || (previousState == .down && (currentState == .between || currentState == .up)) {
            if minElbowAngleThisRep <= elbowAngleDownMax {
                wentLowEnoughThisRep = true
            }
        }

        // Check for Rep Completion
        if previousState == .down && currentState == .up {
            // Rep attempt: Transitioned from Down to Up
            if wentLowEnoughThisRep {
                repCount += 1 // Using internal counter for now
                feedback = "Rep Counted! (\(repCount))"
                // Reset state for next rep
                minElbowAngleThisRep = 180.0
                wentLowEnoughThisRep = false
                return .repCompleted
            } else {
                // Didn't go low enough on the previous down phase
                feedback = "Push lower for rep to count."
                // Reset state for next rep attempt
                minElbowAngleThisRep = 180.0
                wentLowEnoughThisRep = false
                return .incorrectForm(feedback: feedback)
            }
        }

        // Provide general feedback based on state
        if feedback.isEmpty { // Only if no specific form issue or rep count occurred
            switch currentState {
            case .up: feedback = "Lower body."
            case .down: feedback = "Push up."
            case .starting: feedback = "Begin when ready."
            case .between: feedback = "Keep moving."
            case .invalid: feedback = "Fix pose."
            }
        }

        // If no rep completed, return current progress/state
        return .inProgress(phase: currentPhaseDescription)
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