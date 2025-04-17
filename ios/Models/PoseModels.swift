import Foundation
import CoreGraphics // For CGPoint
import Vision // For VNRecognizedPointKey, VNHumanBodyPoseObservation.JointName

// Represents a single detected point (landmark)
struct DetectedPoint: Equatable, Hashable {
    let name: VNHumanBodyPoseObservation.JointName // Specific joint name
    let location: CGPoint // Normalized coordinates (0.0 to 1.0)
    let confidence: Float // Confidence score from Vision framework
}

// Represents the entire detected body pose
struct DetectedBody: Equatable, Hashable {
    let points: [VNHumanBodyPoseObservation.JointName: DetectedPoint] // Dictionary mapping joint name to point
    let confidence: Float // Overall confidence of the detected body pose

    // Convenience accessor for specific points
    func point(_ name: VNHumanBodyPoseObservation.JointName) -> DetectedPoint? {
        return points[name]
    }

    // Get all available points as an array
    var allPoints: [DetectedPoint] {
        return Array(points.values)
    }
} 