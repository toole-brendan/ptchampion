import Foundation
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants
import CoreGraphics
import Combine // For ObservableObject

final class SitupGrader: ObservableObject, ExerciseGraderProtocol {

    // MARK: - Static Thresholds (Accessible for Unit Testing)
    // FPS setting - helps adjust required stable frames
    static var targetFramesPerSecond: Double = 30.0 // Target frame rate (default 30fps)
    
    // Required confidence for joint positions
    static var requiredJointConfidence: Float = 0.6
    
    // Required stable frames
    static var requiredStableFrames: Int = 5 // Increased from 3 to match Push-up stability
    
    // Angle thresholds
    static let hipAngleDownMin: CGFloat = 150.0  // Min hip angle to be considered 'down' (Aligned w/ Android)
    static let hipAngleUpMax: CGFloat = 70.0    // Max hip angle to be considered fully 'up' (Aligned w/ Android)
    
    // Position thresholds
    static let elbowKneeProximityMaxY: CGFloat = 0.10 // Threshold for elbow-knee proximity (Aligned w/ Android)
    static let armsCrossedMaxDist: CGFloat = 0.15 // Threshold for wrist-opposite shoulder dist (Aligned w/ Android)
    
    // New thresholds for strict grading
    static let pauseFrameThreshold: Int = Int(2.0 * targetFramesPerSecond) // ~2 seconds pause

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
    private var framesInPosition: Int = 0
    private var previousState: SitupPhase = .starting

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
        previousState = .starting
        feedback = "Lie down, arms crossed, knees bent."
        repCount = 0
        formScores = []
        resetRepTrackingState()
        stableFrameCounter = 0
        framesInPosition = 0
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
        
        previousState = currentState // Remember previous state for transitions

        // 1. Check Required Joint Confidence
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .nose // Added Nose (Aligned w/ Android)
        ]
        
        // Check if all required joints are visible using the helper
        if !PoseValidationHelper.isFullBodyVisible(body, requiredJoints: requiredJoints, confidence: SitupGrader.requiredJointConfidence) {
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

        // Form Issues Collection
        var formIssues: [String] = []

        // 3. Form Check: Arms Crossed (Check distance from wrist to opposite shoulder)
        let leftWristToRightShoulder = distance(leftWrist.location, rightShoulder.location)
        let rightWristToLeftShoulder = distance(rightWrist.location, leftShoulder.location)
        let armsAreCrossed = (leftWristToRightShoulder < SitupGrader.armsCrossedMaxDist && 
                              rightWristToLeftShoulder < SitupGrader.armsCrossedMaxDist)
        
        // If arms aren't crossed, add to form issues
        if !armsAreCrossed {
            formIssues.append("Keep arms crossed over chest")
            _problemJoints.insert(.leftWrist)
            _problemJoints.insert(.rightWrist)
            _problemJoints.insert(.leftElbow)
            _problemJoints.insert(.rightElbow)
        }

        // Check for pausing too long
        if currentState == previousState {
            framesInPosition += 1
            if framesInPosition > SitupGrader.pauseFrameThreshold {
                formIssues.append("Paused too long")
                // No specific joint to highlight for pause
            }
        } else {
            framesInPosition = 0
        }

        // --- State Machine Logic --- 
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

        // Position-specific form checks
        if currentState == .down && avgHipAngle < SitupGrader.hipAngleDownMin {
            formIssues.append("Go all the way down")
            _problemJoints.insert(.leftHip)
            _problemJoints.insert(.rightHip)
        } 
        
        if currentState == .up && avgHipAngle > SitupGrader.hipAngleUpMax {
            formIssues.append("Go higher - elbows not close to knees")
            _problemJoints.insert(.leftShoulder)
            _problemJoints.insert(.rightShoulder)
            _problemJoints.insert(.leftElbow)
            _problemJoints.insert(.rightElbow)
        }

        // Check for Rep Completion (Transition UP -> DOWN)
        var gradingResult: GradingResult = .noChange
        
        if previousState == .up && currentState == .down && stableFrameCounter >= SitupGrader.requiredStableFrames {
            var repFormIssues: [String] = []
            
            // Check if up position was high enough
            if minHipAngleThisRep > SitupGrader.hipAngleUpMax {
                repFormIssues.append("Go higher - elbows not close to knees")
                _problemJoints.insert(.leftShoulder)
                _problemJoints.insert(.rightShoulder)
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            }
            
            // Check if arms were crossed during the UP phase
            if !armsWereCrossedThisRep {
                repFormIssues.append("Keep arms crossed over chest")
                _problemJoints.insert(.leftWrist)
                _problemJoints.insert(.rightWrist)
                _problemJoints.insert(.leftElbow)
                _problemJoints.insert(.rightElbow)
            }
            
            // Check if down position was fully reached in previous reps
            if maxHipAngleThisRep < SitupGrader.hipAngleDownMin {
                repFormIssues.append("Go all the way down")
                _problemJoints.insert(.leftHip)
                _problemJoints.insert(.rightHip)
            }
            
            // Now, only count the rep if there are no form issues
            if repFormIssues.isEmpty {
                repCount += 1
                feedback = "Good rep!"
                formScores.append(1.0) // Perfect form
                gradingResult = .repCompleted(formQuality: 1.0)
            } else {
                // Rep not counted due to form issues
                feedback = repFormIssues.first ?? "Incorrect form"
                _lastFormIssue = feedback
                gradingResult = .incorrectForm(feedback: feedback)
            }
            
            // Reset tracking for the next rep cycle
            resetRepTrackingState()
        } else {
            // Provide general feedback if no rep completed
            if !formIssues.isEmpty {
                feedback = formIssues.first ?? ""
                _lastFormIssue = feedback
                gradingResult = .incorrectForm(feedback: feedback)
            } else {
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
        }

        return gradingResult
    }

    // Calculate angle between three points (used for hip angle)
    private func calculateAngle(point1: CGPoint, centerPoint: CGPoint, point2: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: point1.x - centerPoint.x, y: point1.y - centerPoint.y)
        let v2 = CGPoint(x: point2.x - centerPoint.x, y: point2.y - centerPoint.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let cross = v1.x * v2.y - v1.y * v2.x
        
        let angleDegrees = atan2(cross, dot) * 180.0 / .pi
        return abs(angleDegrees)
    }

    // Update state only if stable for enough frames
    private func updateState(to newState: SitupPhase, stable: Bool = true) {
        if newState == currentState {
            if stable { stableFrameCounter += 1 }
        } else {
            stableFrameCounter = 0
            // Only change if required frames met OR the new state is invalid
            if !stable || stableFrameCounter >= SitupGrader.requiredStableFrames || newState == .invalid || currentState == .starting {
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
    
    func calculateFinalScore() -> Double? {
        guard repCount > 0 else { return nil }
        let score = ScoreRubrics.score(for: .situp, reps: repCount)
        return Double(score)
    }
} 