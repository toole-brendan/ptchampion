// ios/ptchampion/Grading/EnhancedSitupGrader.swift

import Foundation
import Vision
import CoreGraphics
import Combine

/// Enhanced Situp Grader that integrates APFT-compliant validation
/// with military-grade situp standards including knee angle monitoring
final class EnhancedSitupGrader: ObservableObject, ExerciseGraderProtocol {
    
    // MARK: - APFT Validator Integration
    private let apftValidator = APFTRepValidator()
    
    // MARK: - Protocol Properties
    private var _repCount: Int = 0
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    private var formScores: [Double] = []
    
    // Current state for UI display
    private var currentFeedback: String = "Lie down with knees at 90 degrees."
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    var currentPhaseDescription: String {
        return apftValidator.situpPhase.capitalized
    }
    
    var repCount: Int { return _repCount }
    
    var formQualityAverage: Double {
        guard !formScores.isEmpty else { return 0.0 }
        return formScores.reduce(0.0, +) / Double(formScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }
    
    // Access to form issues for external components
    var situpFormIssues: [String] { return apftValidator.situpFormIssues }
    
    // MARK: - Form Quality Calculation
    private func calculateGraduatedFormQuality(
        formIssues: [String],
        phase: String,
        additionalData: [String: Any]
    ) -> Double {
        var score: Double = 1.0
        
        // Deduct based on severity of form issues
        for issue in formIssues {
            switch issue.lowercased() {
            // Critical issues - major deductions
            case let str where str.contains("knees") && str.contains("90"):
                score -= 0.2  // Knee angle is critical for proper form
            case let str where str.contains("vertical"):
                score -= 0.15 // Not reaching vertical position
                
            // Moderate issues
            case let str where str.contains("shoulders") && str.contains("ground"):
                score -= 0.1  // Not lowering shoulders fully
            case let str where str.contains("torso"):
                score -= 0.1
                
            // Minor issues
            case let str where str.contains("higher"):
                score -= 0.05
            case let str where str.contains("lower"):
                score -= 0.05
            default:
                score -= 0.05
            }
        }
        
        // Bonus for excellent form indicators
        if phase == "lowering" && formIssues.isEmpty {
            score = min(1.0, score + 0.05) // Small bonus for controlled lowering
        }
        
        return max(0.0, min(1.0, score))
    }
    
    // MARK: - Protocol Methods
    func resetState() {
        apftValidator.resetExercise("situp")
        _repCount = 0
        formScores = []
        _lastFormIssue = nil
        _problemJoints = []
        currentFeedback = "Lie down with knees at 90 degrees."
        print("EnhancedSitupGrader: State reset.")
    }
    
    func gradePose(body: DetectedBody) -> GradingResult {
        /* COMMENTED OUT - Sit-up replaced by plank
        // Clear previous problem joints
        _problemJoints = []
        
        // Process frame with APFT validator
        let result = apftValidator.processFrame(body: body, exerciseType: "situp")
        
        // Extract results
        let repCompleted = result["repCompleted"] as? Bool ?? false
        let totalReps = result["totalReps"] as? Int ?? 0
        let currentPhase = result["currentPhase"] as? String ?? "Unknown"
        let inValidRep = result["inValidRep"] as? Bool ?? false
        let formIssues = result["formIssues"] as? [String] ?? []
        
        // Update internal state
        _repCount = totalReps
        
        // Handle form issues and highlight problem joints
        if !formIssues.isEmpty {
            _lastFormIssue = formIssues.first
            currentFeedback = formIssues.first ?? ""
            
            // Map form issues to problem joints for UI highlighting
            for issue in formIssues {
                switch issue.lowercased() {
                case let str where str.contains("knees") || str.contains("90"):
                    _problemJoints.insert(.leftKnee)
                    _problemJoints.insert(.rightKnee)
                case let str where str.contains("shoulders") || str.contains("ground"):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                case let str where str.contains("torso") || str.contains("sit up"):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                    _problemJoints.insert(.leftHip)
                    _problemJoints.insert(.rightHip)
                case let str where str.contains("higher") || str.contains("vertical"):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                default:
                    break
                }
            }
        } else {
            // Provide phase-specific feedback when no form issues
            switch currentPhase.lowercased() {
            case "down":
                currentFeedback = "Sit up to vertical"
            case "rising":
                currentFeedback = "Keep going up"
            case "lowering":
                currentFeedback = "Lower back down"
            default:
                currentFeedback = "Continue movement"
            }
        }
        
        // Handle rep completion
        if repCompleted {
            // Calculate graduated form quality based on issues during rep
            let formQuality = calculateGraduatedFormQuality(
                formIssues: apftValidator.situpFormIssues,
                phase: currentPhase,
                additionalData: result
            )
            formScores.append(formQuality)
            
            // Provide feedback based on form quality
            if formQuality >= 0.95 {
                currentFeedback = "Excellent rep!"
            } else if formQuality >= 0.85 {
                currentFeedback = "Great rep!"
            } else if formQuality >= 0.70 {
                currentFeedback = "Rep counted - maintain knee angle"
            } else {
                currentFeedback = "Rep counted - work on form"
            }
            
            _lastFormIssue = nil
            return .repCompleted(formQuality: formQuality)
        }
        
        // Handle form issues
        if !formIssues.isEmpty {
            return .incorrectForm(feedback: currentFeedback)
        }
        
        // Return current progress
        return .inProgress(phase: currentPhaseDescription)
        */
        
        // Disabled sit-up logic - exercise replaced by plank
        _lastFormIssue = "Sit-up exercise has been replaced by plank"
        currentFeedback = "Please select plank instead of sit-ups"
        return .invalidPose(reason: "Sit-up exercise replaced by plank.")
    }
    
    func calculateFinalScore() -> Double? {
        guard repCount > 0 else { return nil }
        let score = ScoreRubrics.score(for: .situp, reps: repCount)
        return Double(score)
    }
    
    // MARK: - Additional Methods for Enhanced Functionality
    
    /// Get detailed feedback including current phase and form issues
    func getDetailedFeedback() -> String {
        let phase = currentPhaseDescription
        let issues = apftValidator.situpFormIssues
        
        if !issues.isEmpty {
            return "\(phase): \(issues.joined(separator: ", "))"
        } else {
            return "\(phase): \(currentFeedback)"
        }
    }
    
    /// Check if currently in a valid rep attempt
    var isInValidRep: Bool {
        let result = apftValidator.processFrame(body: DetectedBody(points: [:], confidence: 0), exerciseType: "situp")
        return result["inValidRep"] as? Bool ?? false
    }
    
    /// Get current rep progress as percentage (0.0 - 1.0)
    func getRepProgress() -> Double {
        switch apftValidator.situpPhase.lowercased() {
        case "down":
            return 0.0
        case "rising":
            return 0.5
        case "lowering":
            return 0.75
        default:
            return 0.0
        }
    }
    
    /// Get current knee angle for UI visualization
    func getKneeAngle(from body: DetectedBody) -> Float? {
        guard let leftHip = body.point(.leftHip),
              let leftKnee = body.point(.leftKnee),
              let leftAnkle = body.point(.leftAnkle),
              let rightHip = body.point(.rightHip),
              let rightKnee = body.point(.rightKnee),
              let rightAnkle = body.point(.rightAnkle) else { return nil }
        
        // Calculate knee angles using the same method as APFT validator
        let leftKneeAngle = calculateAngle(point1: leftHip.location, vertex: leftKnee.location, point3: leftAnkle.location)
        let rightKneeAngle = calculateAngle(point1: rightHip.location, vertex: rightKnee.location, point3: rightAnkle.location)
        
        return (leftKneeAngle + rightKneeAngle) / 2
    }
    
    /// Get current torso angle from horizontal for UI feedback
    func getTorsoAngle(from body: DetectedBody) -> Float? {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip) else { return nil }
        
        // Calculate torso angle
        let shoulderMid = CGPoint(
            x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
            y: (leftShoulder.location.y + rightShoulder.location.y) / 2
        )
        let hipMid = CGPoint(
            x: (leftHip.location.x + rightHip.location.x) / 2,
            y: (leftHip.location.y + rightHip.location.y) / 2
        )
        
        let dx = shoulderMid.x - hipMid.x
        let dy = shoulderMid.y - hipMid.y
        
        return atan2(Float(dy), Float(dx)) * 180.0 / Float.pi
    }
    
    // Helper method for angle calculation (same as APFT validator)
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let vector1 = simd_float2(Float(point1.x - vertex.x), Float(point1.y - vertex.y))
        let vector2 = simd_float2(Float(point3.x - vertex.x), Float(point3.y - vertex.y))
        
        let dotProduct = simd_dot(vector1, vector2)
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosAngle = simd_clamp(dotProduct / (magnitude1 * magnitude2), -1.0, 1.0)
        return acos(cosAngle) * 180.0 / Float.pi
    }
}

// MARK: - Integration Helper Extension
extension EnhancedSitupGrader {
    
    /// Factory method for standard APFT situps
    static func forStandardAPFT() -> EnhancedSitupGrader {
        let grader = EnhancedSitupGrader()
        return grader
    }
    
    /// Factory method for modified situps (e.g., for injured personnel)
    static func forModified() -> EnhancedSitupGrader {
        let grader = EnhancedSitupGrader()
        // Could modify standards here if needed
        return grader
    }
} 