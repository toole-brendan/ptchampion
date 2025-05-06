import Foundation
import Combine
import Vision // For VNHumanBodyPoseObservation.JointName

/// Type-erasing wrapper for any ExerciseGraderProtocol instance that is also an ObservableObject.
final class AnyExerciseGraderBox: ObservableObject, ExerciseGraderProtocol {
    // Hold the concrete grader instance
    private var concreteGrader: any ExerciseGraderProtocol
    private var cancellable: AnyCancellable? // To observe the concrete grader

    // Published properties mirroring ExerciseGraderProtocol
    @Published var currentPhaseDescription: String
    @Published var repCount: Int
    @Published var formQualityAverage: Double
    @Published var lastFormIssue: String?
    @Published var problemJoints: Set<VNHumanBodyPoseObservation.JointName>

    init<Grader: ExerciseGraderProtocol>(_ grader: Grader) where Grader: ObservableObject {
        self.concreteGrader = grader
        
        // Initialize published properties from the concrete grader's initial state
        self.currentPhaseDescription = grader.currentPhaseDescription
        self.repCount = grader.repCount
        self.formQualityAverage = grader.formQualityAverage
        self.lastFormIssue = grader.lastFormIssue
        self.problemJoints = grader.problemJoints

        // Subscribe to objectWillChange from the concrete grader and relay it
        // This ensures that when the concrete grader publishes changes, our box also publishes.
        self.cancellable = grader.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            // Manually update properties upon notification for simplicity,
            // though direct observation of concrete grader's @Published properties would be more robust
            // if those were directly accessible and guaranteed by the protocol.
            // For now, this ensures the wrapper signals a change.
            // A more complete solution might involve specific publishers for each property in the protocol.
            self?.syncPropertiesFromConcreteGrader()
        }
    }
    
    private func syncPropertiesFromConcreteGrader() {
        self.currentPhaseDescription = concreteGrader.currentPhaseDescription
        self.repCount = concreteGrader.repCount
        self.formQualityAverage = concreteGrader.formQualityAverage
        self.lastFormIssue = concreteGrader.lastFormIssue
        self.problemJoints = concreteGrader.problemJoints
    }

    // Forward protocol methods to the concrete grader
    func resetState() {
        concreteGrader.resetState()
        syncPropertiesFromConcreteGrader() // Ensure state is synced after reset
    }

    func gradePose(body: DetectedBody) -> GradingResult {
        let result = concreteGrader.gradePose(body: body)
        syncPropertiesFromConcreteGrader() // Sync state after grading
        return result
    }

    func calculateFinalScore() -> Double? {
        return concreteGrader.calculateFinalScore()
    }
    
    // Static properties - these are usually part of the protocol's static context,
    // not instance properties. The protocol should define how these are accessed if needed
    // through an instance, or they should be accessed via the concrete type directly.
    // For now, an AnyExerciseGraderBox would not typically provide these directly unless generalized.
    // static var targetFramesPerSecond: Double { return 30.0 } // Example, not ideal here
    // static var requiredJointConfidence: Float { return 0.5 } // Example
    // static var requiredStableFrames: Int { return 3 } // Example
} 