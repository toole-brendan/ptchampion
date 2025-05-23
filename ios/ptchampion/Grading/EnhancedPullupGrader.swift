// ios/ptchampion/Grading/EnhancedPullupGrader.swift

import Foundation
import Vision
import CoreGraphics
import Combine

/// Enhanced Pullup Grader that integrates APFT-compliant validation
/// with military-grade pullup standards including swing detection
final class EnhancedPullupGrader: ObservableObject, ExerciseGraderProtocol {
    
    // MARK: - APFT Validator Integration
    private let apftValidator = APFTRepValidator()
    
    // MARK: - Pullup-Specific Configuration
    @Published var barHeightY: Float = 0.2  // Default bar height in normalized coordinates
    
    // MARK: - Protocol Properties
    private var _repCount: Int = 0
    private var _lastFormIssue: String? = nil
    private var _problemJoints: Set<VNHumanBodyPoseObservation.JointName> = []
    private var formScores: [Double] = []
    
    // Current state for UI display
    private var currentFeedback: String = "Hang from the bar with arms extended."
    
    // Public access to problem joints for UI highlighting
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> {
        return _problemJoints
    }
    
    var currentPhaseDescription: String {
        return apftValidator.pullupPhase.capitalized
    }
    
    var repCount: Int { return _repCount }
    
    var formQualityAverage: Double {
        guard !formScores.isEmpty else { return 0.0 }
        return formScores.reduce(0.0, +) / Double(formScores.count)
    }
    
    var lastFormIssue: String? { return _lastFormIssue }
    
    // Access to form issues for external components
    var pullupFormIssues: [String] { return apftValidator.pullupFormIssues }
    
    // MARK: - Bar Height Configuration
    func setBarHeight(_ height: Float) {
        barHeightY = height
        print("EnhancedPullupGrader: Bar height set to \(height)")
    }
    
    // Auto-detect bar height based on hand positions
    func autoDetectBarHeight(from body: DetectedBody) {
        guard let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist) else { return }
        
        let avgWristY = (leftWrist.location.y + rightWrist.location.y) / 2
        
        // Set bar height slightly above current wrist position
        barHeightY = Float(avgWristY) - 0.03  // 3% above wrists
        print("EnhancedPullupGrader: Auto-detected bar height: \(barHeightY)")
    }
    
    // MARK: - Protocol Methods
    func resetState() {
        apftValidator.resetExercise("pullup")
        _repCount = 0
        formScores = []
        _lastFormIssue = nil
        _problemJoints = []
        currentFeedback = "Hang from the bar with arms extended."
        print("EnhancedPullupGrader: State reset.")
    }
    
    func gradePose(body: DetectedBody) -> GradingResult {
        // Clear previous problem joints
        _problemJoints = []
        
        // Auto-detect bar if first frame and not manually set
        if barHeightY == 0.2 {  // Default value indicates not set
            autoDetectBarHeight(from: body)
        }
        
        // Process frame with APFT validator
        let result = apftValidator.processFrame(body: body, exerciseType: "pullup", barHeightY: barHeightY)
        
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
                case let str where str.contains("swing") || str.contains("body"):
                    _problemJoints.insert(.leftShoulder)
                    _problemJoints.insert(.rightShoulder)
                    _problemJoints.insert(.leftHip)
                    _problemJoints.insert(.rightHip)
                case let str where str.contains("arms") || str.contains("extend"):
                    _problemJoints.insert(.leftElbow)
                    _problemJoints.insert(.rightElbow)
                    _problemJoints.insert(.leftWrist)
                    _problemJoints.insert(.rightWrist)
                case let str where str.contains("chin") || str.contains("bar"):
                    _problemJoints.insert(.nose)
                case let str where str.contains("dead hang") || str.contains("lower"):
                    _problemJoints.insert(.leftElbow)
                    _problemJoints.insert(.rightElbow)
                case let str where str.contains("pull") && str.contains("higher"):
                    _problemJoints.insert(.leftElbow)
                    _problemJoints.insert(.rightElbow)
                default:
                    break
                }
            }
        } else {
            // Provide phase-specific feedback when no form issues
            switch currentPhase.lowercased() {
            case "down":
                currentFeedback = "Pull yourself up"
            case "pulling":
                currentFeedback = "Get chin over bar"
            case "lowering":
                currentFeedback = "Lower to dead hang"
            default:
                currentFeedback = "Continue movement"
            }
        }
        
        // Handle rep completion
        if repCompleted {
            // Perfect form for APFT-compliant reps
            let formQuality = 1.0
            formScores.append(formQuality)
            currentFeedback = "Excellent rep!"
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
        let score = ScoreRubrics.score(for: .pullup, reps: repCount)
        return Double(score)
    }
    
    // MARK: - Additional Methods for Enhanced Functionality
    
    /// Get detailed feedback including current phase and form issues
    func getDetailedFeedback() -> String {
        let phase = currentPhaseDescription
        let issues = apftValidator.pullupFormIssues
        
        if !issues.isEmpty {
            return "\(phase): \(issues.joined(separator: ", "))"
        } else {
            return "\(phase): \(currentFeedback)"
        }
    }
    
    /// Check if currently in a valid rep attempt
    var isInValidRep: Bool {
        let result = apftValidator.processFrame(body: DetectedBody(points: [:], confidence: 0), exerciseType: "pullup")
        return result["inValidRep"] as? Bool ?? false
    }
    
    /// Get current rep progress as percentage (0.0 - 1.0)
    func getRepProgress() -> Double {
        switch apftValidator.pullupPhase.lowercased() {
        case "down":
            return 0.0
        case "pulling":
            return 0.5
        case "lowering":
            return 0.75
        default:
            return 0.0
        }
    }
    
    /// Get current chin height relative to bar (for UI visualization)
    func getChinBarRelativePosition(from body: DetectedBody) -> Float? {
        guard let nose = body.point(.nose) else { return nil }
        
        let chinY = Float(nose.location.y)
        return chinY - barHeightY  // Positive means below bar, negative means above
    }
    
    /// Check for excessive swinging
    func getSwingAmount(from body: DetectedBody) -> Float? {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder) else { return nil }
        
        let shoulderMidX = (leftShoulder.location.x + rightShoulder.location.x) / 2
        
        // This would need to track position over time to calculate drift
        // For now, return current X position
        return Float(shoulderMidX)
    }
}

// MARK: - Integration Helper Extension
extension EnhancedPullupGrader {
    
    /// Factory method to create grader with custom bar height
    static func withBarHeight(_ height: Float) -> EnhancedPullupGrader {
        let grader = EnhancedPullupGrader()
        grader.setBarHeight(height)
        return grader
    }
    
    /// Factory method for outdoor pullup bars (typically higher)
    static func forOutdoorBar() -> EnhancedPullupGrader {
        return withBarHeight(0.15)  // Higher position for outdoor bars
    }
    
    /// Factory method for indoor gym bars (typically lower)
    static func forIndoorBar() -> EnhancedPullupGrader {
        return withBarHeight(0.25)  // Lower position for indoor bars
    }
} 