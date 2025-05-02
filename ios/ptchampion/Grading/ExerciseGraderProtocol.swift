import Foundation
import Vision // For JointName

// Enum representing the result of grading a single pose frame
enum GradingResult {
    case repCompleted // A valid repetition was completed
    case inProgress(phase: String?) // Repetition is in progress (optional phase info)
    case invalidPose(reason: String) // Pose is unsuitable for grading (e.g., out of frame, bad angle)
    case incorrectForm(feedback: String) // Form needs correction
    case noChange // No significant change in state from the last frame
}

// Protocol defining the interface for an exercise-specific grader
protocol ExerciseGraderProtocol {
    // Resets the grader's internal state (e.g., for a new workout)
    func resetState()

    // Grades the current detected body pose
    // - Parameter body: The detected body landmarks
    // - Returns: A GradingResult indicating the outcome
    func gradePose(body: DetectedBody) -> GradingResult
    
    // Calculate the final score based on rep count and form quality
    // - Returns: A score (0-100) representing overall performance, or nil if not applicable
    func calculateFinalScore() -> Double?

    // Optional: Property to get the current state/phase description
    var currentPhaseDescription: String { get }
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