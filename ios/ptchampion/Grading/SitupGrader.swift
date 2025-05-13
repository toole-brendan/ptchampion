import Foundation
import Vision
import CoreGraphics
import Combine // For ObservableObject

final class SitupGrader: ObservableObject, ExerciseGraderProtocol {

    // MARK: - Static Thresholds (Accessible for Unit Testing)
    // FPS setting - helps adjust required stable frames
    static var targetFramesPerSecond: Double = 30.0 // Target frame rate (default 30fps)
    
    // Required confidence for joint positions
    static var requiredJointConfidence: Float = 0.6
    
    // Required stable frames
    static var requiredStableFrames: Int = 3
    
    // Angle thresholds
    static let hipAngleDownMin: CGFloat = 150.0  // Min hip angle to be considered 'down' (Aligned w/ Android)
    static let hipAngleUpMax: CGFloat = 70.0    // Max hip angle to be considered fully 'up' (Aligned w/ Android)
    
    // Position thresholds
    static let elbowKneeProximityMaxY: CGFloat = 0.10 // Threshold for elbow-knee proximity (Aligned w/ Android)
    static let armsCrossedMaxDist: CGFloat = 0.15 // Threshold for wrist-opposite shoulder dist (Aligned w/ Android)

    // MARK: - Situp States
    private enum SitupPhase {
        case down // Back relatively flat
        case up   // Torso significantly raised, elbows near thighs
        case starting
        case invalid
        case between // Transitioning
    }

    // MARK: - Internal State Tracking
    private var currentState: SitupPhase = .starting
    private var feedback: String = "Lie down, arms crossed, knees bent."
    private(set) var repCount: Int = 0
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = [] // Track joints with issues
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    // Form quality tracking
    private var formScores: [Double] = []

    // State tracking for rep evaluation & stability
    private var maxHipAngleThisRep: CGFloat = 0.0      // Track max angle when down
    private var minHipAngleThisRep: CGFloat = 180.0    // Track min angle when up
    private var armsWereCrossedThisRep: Bool = false   // Track arm position during UP phase
    private var stableFrameCounter: Int = 0

    // MARK: - Protocol Properties
    var currentPhaseDescription: String {
        switch currentState {
        case .down: return "Down"
        case .up: return "Up"
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
        feedback = "Lie down, arms crossed, knees bent."
        repCount = 0
        formScores = []
        resetRepTrackingState()
        stableFrameCounter = 0
        _lastFormIssue = nil
        _problemJoints = [] // Reset problem joints
        print("SitupGrader: State reset.")
    }

    private func resetRepTrackingState() {
        maxHipAngleThisRep = 0.0
        minHipAngleThisRep = 180.0
        armsWereCrossedThisRep = false // Reset arm check for new rep
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        feedback = "" // Reset feedback
        _problemJoints = [] // Reset problem joints for this frame

        // 1. Check Required Joint Confidence
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .nose // Added Nose (Aligned w/ Android)
        ]
        
        // Use body's helper method to check missing joints
        let missingJoints = body.missingJoints(from: keyJoints, minConfidence: SitupGrader.requiredJointConfidence)
        
        if !missingJoints.isEmpty {
            updateState(to: .invalid, stable: false)
            
            #if DEBUG
            let missingJointNames = missingJoints.map { 
                String(describing: $0).replacingOccurrences(of: "VNHumanBodyPoseObservation.JointName.", with: "") 
            }
            feedback = "Cannot see clearly: \(missingJointNames.joined(separator: ", "))"
            #else
            feedback = "Cannot detect full body - adjust camera position"
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
        let armsAreCrossed = (leftWristToRightShoulder < SitupGrader.armsCrossedMaxDist && 
                              rightWristToLeftShoulder < SitupGrader.armsCrossedMaxDist)
        
        // If arms aren't crossed, mark problem joints
        if !armsAreCrossed {
            _problemJoints.insert(.leftWrist)
            _problemJoints.insert(.rightWrist)
            _problemJoints.insert(.leftElbow)
            _problemJoints.insert(.rightElbow)
        }

        // --- State Machine Logic --- 
        let previousState = currentState
        var detectedState: SitupPhase

        // Determine potential state based on angles/proximity
        if avgHipAngle >= SitupGrader.hipAngleDownMin {
            detectedState = .down
            // STATE TRANSITION: Moving/staying in DOWN position (back flat)
        } else if avgHipAngle <= SitupGrader.hipAngleUpMax && 
                  elbowKneeYDiff <= SitupGrader.elbowKneeProximityMaxY {
            detectedState = .up
            // STATE TRANSITION: Moving/staying in UP position (torso raised)
        } else {
            detectedState = .between
            // STATE TRANSITION: In between positions
        }

        // Update stable state
        updateState(to: detectedState)

        // If state is invalid now (due to failed checks), return early
        guard currentState != .invalid else {
            // Feedback is already set by checks
            _lastFormIssue = feedback
            return .invalidPose(reason: feedback)
        }

        // Track min/max angles during the appropriate phases
        if currentState == .down || (previousState == .up && currentState == .between) {
            maxHipAngleThisRep = max(maxHipAngleThisRep, avgHipAngle)
            // STATE TRACKING: Recording maximum hip angle during down position
        }
        if currentState == .up || (previousState == .down && currentState == .between) {
            minHipAngleThisRep = min(minHipAngleThisRep, avgHipAngle)
            // STATE TRACKING: Recording minimum hip angle during up position
            
            // Check arm position specifically when in or moving towards UP state
            if armsAreCrossed { armsWereCrossedThisRep = true }
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        var gradingResult: GradingResult = .noChange
        if previousState == .up && currentState == .down {
            var repFormIssues: [String] = []
            var formQuality: Double = 1.0 // Start with perfect score
            
            // Check if up position was high enough
            if minHipAngleThisRep > SitupGrader.hipAngleUpMax {
                repFormIssues.append("Sit up higher")
                formQuality -= 0.3 // Reduce score for not going high enough
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
            }
            
            // Check if arms were crossed during the UP phase
            if !armsWereCrossedThisRep {
                 repFormIssues.append("Keep arms crossed")
                 formQuality -= 0.3 // Reduce score for not crossing arms
                 _problemJoints.insert(.leftWrist)
                 _problemJoints.insert(.rightWrist)
            }
            
            // Apply minimum quality floor
            formQuality = max(0.3, formQuality)
            
            // Add to form quality tracking
            formScores.append(formQuality)

            if repFormIssues.isEmpty {
                repCount += 1
                feedback = "Good rep! (\(repCount))"
                gradingResult = .repCompleted(formQuality: formQuality)
            } else {
                repCount += 1 // Still count the rep even with issues
                feedback = repFormIssues.joined(separator: ". ")
                _lastFormIssue = feedback
                gradingResult = .repCompleted(formQuality: formQuality)
            }
            // Reset tracking for the next rep cycle
            resetRepTrackingState()

            print("⚙️ Situp rep \(repCount) scored \(formQuality)%")

        } else {
            // Provide general feedback if no rep completed
            gradingResult = .inProgress(phase: currentPhaseDescription)
            if feedback.isEmpty { // Avoid overwriting specific form issue feedback
                 switch currentState {
                 case .down: feedback = "Sit up"
                 case .up: feedback = "Lower down"
                 case .starting: feedback = "Begin when ready"
                 case .between: feedback = "Keep moving"
                 case .invalid: feedback = "Fix pose"
                 }
            }
        }

        // Always check basic arm crossing form, even if not counting rep yet
         if !armsAreCrossed && currentState != .down && currentState != .starting {
             // Don't override rep completion/failure feedback
             switch gradingResult {
             case .inProgress, .noChange:
                 feedback = "Keep arms crossed over chest"
                 _lastFormIssue = feedback
                 _problemJoints.insert(.leftWrist)
                 _problemJoints.insert(.rightWrist)
                 _problemJoints.insert(.leftElbow)
                 _problemJoints.insert(.rightElbow)
                 return .incorrectForm(feedback: feedback)
             default:
                 break
             }
         }

        // Immediate feedback on current position if needed
        if currentState == .down && avgHipAngle < SitupGrader.hipAngleDownMin {
            // Use if-case for comparison
            if case .inProgress = gradingResult {
                feedback = "Lower further"
                _lastFormIssue = feedback
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
                gradingResult = .incorrectForm(feedback: feedback)
            } else if case .noChange = gradingResult {
                feedback = "Lower further"
                _lastFormIssue = feedback
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
                gradingResult = .incorrectForm(feedback: feedback)
            }
        } else if currentState == .up && avgHipAngle > SitupGrader.hipAngleUpMax {
            // Use if-case for comparison
            if case .inProgress = gradingResult {
                feedback = "Sit up higher"
                _lastFormIssue = feedback
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
                gradingResult = .incorrectForm(feedback: feedback)
            } else if case .noChange = gradingResult {
                feedback = "Sit up higher"
                _lastFormIssue = feedback
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
                gradingResult = .incorrectForm(feedback: feedback)
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
            if !stable || stableFrameCounter >= SitupGrader.requiredStableFrames || newState == .invalid {
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

    // Helper to calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
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