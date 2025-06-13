// ios/ptchampion/Grading/PlankGrader.swift

import Foundation
import Vision
import CoreGraphics
import Combine

/// Enhanced Plank Grader implementing USMC-compliant plank standards
/// for time-based plank exercise instead of repetition-based
final class PlankGrader: ObservableObject, ExerciseGraderProtocol {
    
    // MARK: - USMC Plank Standards
    private static let plankHipAngleMin: Float = 170.0           // Min shoulder-hip-knee angle
    private static let plankKneeAngleMin: Float = 170.0          // Min hip-knee-ankle angle (straight legs)
    private static let plankAngleTolerance: Float = 10.0         // ±10-15° tolerance around 180°
    private static let plankBodySymmetryTolerance: Float = 15.0  // Max left/right angle difference
    private static let plankElbowAlignmentTolerance: Float = 0.1 // Elbow-shoulder vertical alignment
    private static let plankStabilityFrames: Int = 3             // Frames to confirm form break
    private static let plankRequiredConfidence: Float = 0.6      // Higher confidence for plank landmarks
    
    // MARK: - Protocol Properties
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    private var currentFeedback: String = "Get into plank position."
    private var formQualityScores: [Double] = []
    private var consecutiveGoodFrames: Int = 0
    private var consecutiveBadFrames: Int = 0
    
    // Public for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    var currentPhaseDescription: String { "Holding Plank" }
    var repCount: Int { return 0 }  // Plank is time-based, not rep-based
    
    var formQualityAverage: Double {
        guard !formQualityScores.isEmpty else { return 0.0 }
        return formQualityScores.reduce(0.0, +) / Double(formQualityScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }
    
    // MARK: - Protocol Configuration
    static var targetFramesPerSecond: Double { return 30.0 }
    static var requiredJointConfidence: Float { return plankRequiredConfidence }
    static var requiredStableFrames: Int { return plankStabilityFrames }
    
    // MARK: - Protocol Methods
    func resetState() {
        _lastFormIssue = nil
        _problemJoints = []
        currentFeedback = "Get into plank position."
        formQualityScores = []
        consecutiveGoodFrames = 0
        consecutiveBadFrames = 0
        print("PlankGrader: State reset.")
    }
    
    func gradePose(body: DetectedBody) -> GradingResult {
        _problemJoints = []
        
        // Verify required joints have sufficient confidence
        let requiredJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
            .leftElbow, .rightElbow
        ]
        
        for joint in requiredJoints {
            guard let point = body.point(joint), point.confidence >= Self.plankRequiredConfidence else {
                currentFeedback = "Position yourself so camera can see your full body"
                return .invalidPose(reason: "Cannot clearly see required body parts")
            }
        }
        
        // Run all form validations
        let hipValidation = validateHipAlignment(body: body)
        let legValidation = validateLegStraightness(body: body)
        let symmetryValidation = validateBodySymmetry(body: body)
        let elbowValidation = validateElbowPlacement(body: body)
        
        // Combine problem joints and feedback
        var allProblems: Set<VNHumanBodyPoseObservation.JointName> = []
        var feedbackMessages: [String] = []
        
        if !hipValidation.isValid {
            allProblems.formUnion(hipValidation.problemJoints)
            feedbackMessages.append(hipValidation.feedback)
        }
        if !legValidation.isValid {
            allProblems.formUnion(legValidation.problemJoints)
            feedbackMessages.append(legValidation.feedback)
        }
        if !symmetryValidation.isValid {
            allProblems.formUnion(symmetryValidation.problemJoints)
            feedbackMessages.append(symmetryValidation.feedback)
        }
        if !elbowValidation.isValid {
            allProblems.formUnion(elbowValidation.problemJoints)
            feedbackMessages.append(elbowValidation.feedback)
        }
        
        // Update problem joints
        _problemJoints = allProblems
        
        // Calculate form quality for this frame
        let formQuality = calculateFormQuality(validations: [
            hipValidation.isValid,
            legValidation.isValid,
            symmetryValidation.isValid,
            elbowValidation.isValid
        ])
        formQualityScores.append(formQuality)
        
        // Return appropriate result
        if feedbackMessages.isEmpty {
            consecutiveGoodFrames += 1
            consecutiveBadFrames = 0
            currentFeedback = consecutiveGoodFrames > 30 ? "Excellent hold - keep going!" : "Good form"
            _lastFormIssue = nil
            return .inProgress(phase: currentPhaseDescription)
        } else {
            consecutiveBadFrames += 1
            consecutiveGoodFrames = 0
            currentFeedback = feedbackMessages.first ?? "Adjust form"
            _lastFormIssue = feedbackMessages.first
            
            // Minor trembling is allowed - only fail after sustained issues
            if consecutiveBadFrames > Self.plankStabilityFrames {
                return .incorrectForm(feedback: currentFeedback)
            } else {
                return .inProgress(phase: currentPhaseDescription) // Allow temporary form issues
            }
        }
    }
    
    func calculateFinalScore() -> Double? {
        return nil  // No scoring for plank (handled externally via time)
    }
    
    // MARK: - Form Validation Functions
    
    private func validateHipAlignment(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
        // Calculate shoulder-hip-knee angle for both sides
        guard let leftAngle = body.calculateAngle(first: .leftShoulder, vertex: .leftHip, second: .leftKnee),
              let rightAngle = body.calculateAngle(first: .rightShoulder, vertex: .rightHip, second: .rightKnee) else {
            return (false, "Cannot detect body alignment", [])
        }
        
        let avgAngle = (leftAngle + rightAngle) / 2
        
        // Check if both angles are within acceptable range (170-190°)
        if avgAngle < CGFloat(Self.plankHipAngleMin) {
            return (false, "Hips are dropping – raise your core", [.leftHip, .rightHip])
        }
        
        // Check for excessive piking (angles too large)
        if avgAngle > 190.0 {
            return (false, "Lower your hips – avoid piking", [.leftHip, .rightHip])
        }
        
        return (true, "", [])
    }
    
    private func validateLegStraightness(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
        // Calculate hip-knee-ankle angle for both legs
        guard let leftKneeAngle = body.calculateAngle(first: .leftHip, vertex: .leftKnee, second: .leftAnkle),
              let rightKneeAngle = body.calculateAngle(first: .rightHip, vertex: .rightKnee, second: .rightAnkle) else {
            return (false, "Cannot detect leg position", [])
        }
        
        if leftKneeAngle < CGFloat(Self.plankKneeAngleMin) || rightKneeAngle < CGFloat(Self.plankKneeAngleMin) {
            return (false, "Keep legs straight", [.leftKnee, .rightKnee])
        }
        
        return (true, "", [])
    }
    
    private func validateBodySymmetry(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
        // Compare left vs right hip angles for body symmetry
        guard let leftHipAngle = body.calculateAngle(first: .leftShoulder, vertex: .leftHip, second: .leftKnee),
              let rightHipAngle = body.calculateAngle(first: .rightShoulder, vertex: .rightHip, second: .rightKnee) else {
            return (false, "Cannot detect body symmetry", [])
        }
        
        if abs(leftHipAngle - rightHipAngle) > CGFloat(Self.plankBodySymmetryTolerance) {
            return (false, "Keep shoulders level", [.leftShoulder, .rightShoulder, .leftHip, .rightHip])
        }
        
        return (true, "", [])
    }
    
    private func validateElbowPlacement(body: DetectedBody) -> (isValid: Bool, feedback: String, problemJoints: Set<VNHumanBodyPoseObservation.JointName>) {
        // Check vertical alignment: elbows under shoulders
        guard let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow),
              let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder) else {
            return (false, "Cannot detect elbow position", [])
        }
        
        let leftOffset = abs(leftElbow.location.x - leftShoulder.location.x)
        let rightOffset = abs(rightElbow.location.x - rightShoulder.location.x)
        
        if leftOffset > CGFloat(Self.plankElbowAlignmentTolerance) || rightOffset > CGFloat(Self.plankElbowAlignmentTolerance) {
            return (false, "Elbows under shoulders", [.leftElbow, .rightElbow, .leftShoulder, .rightShoulder])
        }
        
        return (true, "", [])
    }
    
    private func calculateFormQuality(validations: [Bool]) -> Double {
        let validCount = validations.filter { $0 }.count
        return Double(validCount) / Double(validations.count)
    }
    
    // MARK: - Additional Helper Methods
    
    /// Get detailed feedback for current plank form
    func getDetailedFeedback() -> String {
        if let issue = _lastFormIssue {
            return "Form Issue: \(issue)"
        } else {
            return "Good form - \(currentFeedback)"
        }
    }
    
    /// Check if currently maintaining good form
    var isHoldingGoodForm: Bool {
        return consecutiveGoodFrames > consecutiveBadFrames && _problemJoints.isEmpty
    }
    
    /// Get form stability as percentage (0.0 - 1.0)
    func getFormStability() -> Double {
        let totalFrames = consecutiveGoodFrames + consecutiveBadFrames
        guard totalFrames > 0 else { return 1.0 }
        return Double(consecutiveGoodFrames) / Double(totalFrames)
    }
}

// MARK: - Integration Helper Extension
extension PlankGrader {
    
    /// Factory method to create grader with custom USMC standards
    static func withCustomStandards(
        hipAngleMin: Float = 170.0,
        kneeAngleMin: Float = 170.0,
        symmetryTolerance: Float = 15.0,
        elbowTolerance: Float = 0.1
    ) -> PlankGrader {
        let grader = PlankGrader()
        // Note: For now, standards are static. Could be made configurable if needed.
        return grader
    }
} 