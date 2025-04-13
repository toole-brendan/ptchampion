import Foundation
import MediaPipeTasksVision

/// Represents the current state of the exercise being performed.
enum ExerciseState {
    case idle       // Waiting to start
    case starting   // Initial position recognized, ready for first rep
    case down       // Moving towards the lower phase of the rep
    case up         // Moving towards the upper phase of the rep
    case finished   // Session stopped
    case invalid    // Pose not suitable for analysis (e.g., out of frame)
}

/// Holds the results of a single frame analysis.
struct AnalysisResult {
    let repCount: Int
    let feedback: [String] // List of feedback messages (e.g., "Go lower", "Keep hips aligned")
    let state: ExerciseState
    let confidence: Float // Confidence score of the pose detection
    let formScore: Double // Overall form score for the rep/session (0-100)
}

/// Protocol for exercise-specific pose analysis logic.
protocol ExerciseAnalyzer {
    /// Analyzes the detected pose landmarks to count reps and assess form.
    ///
    /// - Parameter poseLandmarkerResult: The pose landmarks detected by MediaPipe.
    /// - Parameter imageSize: The size of the image the landmarks were detected in (needed for normalization/scaling if required).
    /// - Returns: An `AnalysisResult` containing the current rep count, feedback, state, and scores.
    func analyze(poseLandmarkerResult: PoseLandmarkerResult, imageSize: CGSize) -> AnalysisResult

    /// Resets the analyzer's internal state (rep count, etc.).
    func reset()

    /// Notifies the analyzer that the exercise session has started.
    func start()

    /// Notifies the analyzer that the exercise session has stopped.
    func stop()
} 