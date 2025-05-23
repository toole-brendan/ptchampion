// ios/ptchampion/Grading/EnhancedPushupGrader.swift

import Foundation
import Vision
import CoreGraphics
import Combine

/// Enhanced Pushup Grader that integrates APFT-compliant validation
/// while maintaining compatibility with the existing ExerciseGraderProtocol
final class EnhancedPushupGrader: ObservableObject, ExerciseGraderProtocol {
    
    // MARK: - APFT Validator Integration
    private let apftValidator = APFTRepValidator()
    
    // MARK: - Protocol Properties
    private var _repCount: Int = 0
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    private var formScores: [Double] = []
    
    // Current state for UI display
    private var currentFeedback: String = "Get into push-up position."
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    var currentPhaseDescription: String {
        return apftValidator.pushupPhase.capitalized
    }
    
    var repCount: Int { return _repCount }
    
    var formQualityAverage: Double {
        guard !formScores.isEmpty else { return 0.0 }
        return formScores.reduce(0.0, +) / Double(formScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }
    
    // Access to form issues for external components
    var pushupFormIssues: [String] { return apftValidator.pushupFormIssues }
    
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
            case let str where str.contains("body") && str.contains("straight"):
                score -= 0.2  // Body not straight is critical
            case let str where str.contains("extend") && str.contains("fully"):
                score -= 0.15 // Not extending arms fully
                
            // Moderate issues
            case let str where str.contains("shoulders") || str.contains("level"):
                score -= 0.1
            case let str where str.contains("lower") || str.contains("parallel"):
                score -= 0.1
                
            // Minor issues
            case let str where str.contains("go") && str.contains("lower"):
                score -= 0.05
            default:
                score -= 0.05
            }
        }
        
        // Bonus for excellent form indicators
        if phase == "ascending" && formIssues.isEmpty {
            score = min(1.0, score + 0.05) // Small bonus for perfect ascent
        }
        
        return max(0.0, min(1.0, score))
    }
    
    // MARK: - Protocol Methods
    func resetState() {
        apftValidator.resetExercise("pushup")
        _repCount = 0
        formScores = []
        _lastFormIssue = nil
        _problemJoints = []
        currentFeedback = "Get into push-up position."
        print("EnhancedPushupGrader: State reset.")
    }
    
    func gradePose(body: DetectedBody) -> GradingResult {
        // Clear previous problem joints
        _problemJoints = []
        
        // Process frame with APFT validator
        let result = apftValidator.processFrame(body: body, exerciseType: "pushup")
        
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
                case let str where str.contains("shoulders") || str.contains("level"):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                case let str where str.contains("body") && (str.contains("straight") || str.contains("alignment")):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                    _problemJoints.insert(.leftHip)
                    _problemJoints.insert(.rightHip)
                case let str where str.contains("arms") || str.contains("elbow"):
                    _problemJoints.insert(.leftElbow)
                    _problemJoints.insert(.rightElbow)
                case let str where str.contains("extend"):
                    _problemJoints.insert(.leftElbow)
                    _problemJoints.insert(.rightElbow)
                    _problemJoints.insert(.leftWrist)
                    _problemJoints.insert(.rightWrist)
                default:
                    break
                }
            }
        } else {
            // Provide phase-specific feedback when no form issues
            switch currentPhase.lowercased() {
            case "up":
                currentFeedback = "Lower your body"
            case "descending":
                currentFeedback = "Keep going down"
            case "ascending":
                currentFeedback = "Push back up"
            default:
                currentFeedback = "Continue movement"
            }
        }
        
        // Handle rep completion
        if repCompleted {
            // Calculate graduated form quality based on issues during rep
            let formQuality = calculateGraduatedFormQuality(
                formIssues: apftValidator.pushupFormIssues,
                phase: currentPhase,
                additionalData: result
            )
            formScores.append(formQuality)
            
            // Provide feedback based on form quality
            if formQuality >= 0.95 {
                currentFeedback = "Excellent rep!"
            } else if formQuality >= 0.85 {
                currentFeedback = "Good rep!"
            } else if formQuality >= 0.70 {
                currentFeedback = "Rep counted - work on form"
            } else {
                currentFeedback = "Rep counted - improve form"
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
    }
    
    func calculateFinalScore() -> Double? {
        guard repCount > 0 else { return nil }
        let score = ScoreRubrics.score(for: .pushup, reps: repCount)
        return Double(score)
    }
    
    // MARK: - Additional Methods for Enhanced Functionality
    
    /// Get detailed feedback including current phase and form issues
    func getDetailedFeedback() -> String {
        let phase = currentPhaseDescription
        let issues = apftValidator.pushupFormIssues
        
        if !issues.isEmpty {
            return "\(phase): \(issues.joined(separator: ", "))"
        } else {
            return "\(phase): \(currentFeedback)"
        }
    }
    
    /// Check if currently in a valid rep attempt
    var isInValidRep: Bool {
        let result = apftValidator.processFrame(body: DetectedBody(points: [:], confidence: 0), exerciseType: "pushup")
        return result["inValidRep"] as? Bool ?? false
    }
    
    /// Get current rep progress as percentage (0.0 - 1.0)
    func getRepProgress() -> Double {
        switch apftValidator.pushupPhase.lowercased() {
        case "up":
            return 0.0
        case "descending":
            return 0.33
        case "ascending":
            return 0.66
        default:
            return 0.0
        }
    }
}

// MARK: - Integration Helper Extension
extension EnhancedPushupGrader {
    
    /// Factory method to create grader with custom APFT standards
    static func withCustomStandards(
        armExtensionAngle: Float = 160.0,
        armParallelAngle: Float = 95.0,
        bodyAlignmentTolerance: Float = 15.0
    ) -> EnhancedPushupGrader {
        let grader = EnhancedPushupGrader()
        
        // Modify APFT standards if needed
        // Note: This would require making APFTStandards mutable or using a configuration approach
        
        return grader
    }
} 