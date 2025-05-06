import Foundation
import Vision // For JointName

// Enum representing the result of grading a single pose frame
enum GradingResult {
    case repCompleted(formQuality: Double = 1.0) // A valid repetition was completed with optional quality score (0-1)
    case inProgress(phase: String?) // Repetition is in progress (optional phase info)
    case invalidPose(reason: String) // Pose is unsuitable for grading (e.g., out of frame, bad angle)
    case incorrectForm(feedback: String) // Form needs correction
    case noChange // No significant change in state from the last frame
}

// Enum representing form quality classifications
enum FormQuality: String {
    case perfect = "Perfect Form!"
    case good = "Good Form"
    case fair = "Form Needs Improvement"
    case poor = "Poor Form"
    
    // Convert to numeric score 0-1
    var score: Double {
        switch self {
        case .perfect: return 1.0
        case .good: return 0.85
        case .fair: return 0.6
        case .poor: return 0.3
        }
    }
}

// Protocol defining the interface for an exercise-specific grader
protocol ExerciseGraderProtocol: AnyObject, ObservableObject {
    // MARK: - Static Configuration
    // FPS baseline - used to adjust stability thresholds
    static var targetFramesPerSecond: Double { get }
    
    // Confidence required for joints before we attempt grading
    static var requiredJointConfidence: Float { get }
    
    // How many frames needed in a position to be considered stable
    static var requiredStableFrames: Int { get }
    
    // MARK: - Required Methods
    // Resets the grader's internal state (e.g., for a new workout)
    func resetState()

    // Grades the current detected body pose
    // - Parameter body: The detected body landmarks
    // - Returns: A GradingResult indicating the outcome
    func gradePose(body: DetectedBody) -> GradingResult
    
    // Calculate the final score based on rep count and form quality
    // - Returns: A score (0-100) representing overall performance, or nil if not applicable
    func calculateFinalScore() -> Double?

    // MARK: - State Properties
    // Current phase description (e.g., "Up", "Down", etc.)
    var currentPhaseDescription: String { get }
    
    // Current rep count
    var repCount: Int { get }
    
    // Average form quality 0-1 (can be converted to 0-100)
    var formQualityAverage: Double { get }
    
    // Last form issue detected (if any)
    var lastFormIssue: String? { get }
    
    // Problem joints for UI highlighting (optional)
    var problemJoints: Set<VNHumanBodyPoseObservation.JointName> { get }
}

// Default implementation for some protocol requirements
extension ExerciseGraderProtocol {
    // Default FPS target - can be overridden by specific graders
    static var targetFramesPerSecond: Double { return 30.0 }
    
    // Default confidence threshold - can be overridden by specific graders
    static var requiredJointConfidence: Float { return 0.5 }
    
    // Default stable frames requirement - can be overridden
    static var requiredStableFrames: Int { return 5 }
    
    // Calculate actual required stable frames based on current FPS (frame rate)
    static func getRequiredStableFrames(actualFPS: Double) -> Int {
        // Scale the required frames based on actual vs target FPS
        guard actualFPS > 0 && targetFramesPerSecond > 0 else { return requiredStableFrames }
        let scaleFactor = actualFPS / targetFramesPerSecond
        return max(2, Int(Double(requiredStableFrames) * scaleFactor))
    }
}

// Helper function for calculating angle between three points (Common need in grading)
func calculateAngle(point1: CGPoint, centerPoint: CGPoint, point2: CGPoint) -> CGFloat? {
    let v1 = (x: point1.x - centerPoint.x, y: point1.y - centerPoint.y)
    let v2 = (x: point2.x - centerPoint.x, y: point2.y - centerPoint.y)

    let dotProduct = v1.x * v2.x + v1.y * v2.y
    let magnitude1 = sqrt(v1.x * v1.x + v1.y * v1.y)
    let magnitude2 = sqrt(v2.x * v2.x + v2.y * v2.y)

    // Avoid division by zero if magnitudes are zero
    guard magnitude1 > 0 && magnitude2 > 0 else { return nil }

    let cosTheta = dotProduct / (magnitude1 * magnitude2)

    // Clamp cosTheta to avoid domain errors with acos due to floating point inaccuracies
    let clampedCosTheta = max(-1.0, min(1.0, cosTheta))

    let angleRad = acos(clampedCosTheta)
    let angleDeg = angleRad * 180.0 / .pi

    return angleDeg
} 