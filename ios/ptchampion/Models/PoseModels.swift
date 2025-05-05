import Foundation
import CoreGraphics // For CGPoint
import Vision // For VNRecognizedPointKey, VNHumanBodyPoseObservation.JointName

// Represents a single detected point (landmark)
struct DetectedPoint: Equatable, Hashable {
    let name: VNHumanBodyPoseObservation.JointName // Specific joint name
    let location: CGPoint // Normalized coordinates (0.0 to 1.0)
    let confidence: Float // Confidence score from Vision framework
    
    // Helper property for normalized x coordinate (0.0 to 1.0)
    var normalizedX: CGFloat {
        return location.x
    }
    
    // Helper property for normalized y coordinate (0.0 to 1.0)
    var normalizedY: CGFloat {
        return location.y
    }
    
    // Calculate distance to another point
    func distance(to otherPoint: DetectedPoint) -> CGFloat {
        let dx = location.x - otherPoint.location.x
        let dy = location.y - otherPoint.location.y
        return sqrt(dx*dx + dy*dy)
    }
    
    // Calculate angle between this point and two others (this point is the vertex)
    func angle(to point1: DetectedPoint, and point2: DetectedPoint) -> CGFloat? {
        return PTChampion.calculateAngle(point1: point1.location, centerPoint: self.location, point2: point2.location)
    }
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
    
    // Check if all the specified joints are detected with minimum confidence
    func hasRequiredJoints(_ jointNames: [VNHumanBodyPoseObservation.JointName], minConfidence: Float = 0.1) -> Bool {
        for jointName in jointNames {
            guard let point = points[jointName], point.confidence >= minConfidence else {
                return false
            }
        }
        return true
    }
    
    // Get missing joints from a required list
    func missingJoints(from jointNames: [VNHumanBodyPoseObservation.JointName], minConfidence: Float = 0.1) -> [VNHumanBodyPoseObservation.JointName] {
        return jointNames.filter { jointName in
            guard let point = points[jointName] else { return true }
            return point.confidence < minConfidence
        }
    }
    
    // Calculate angle between three joints
    func calculateAngle(first: VNHumanBodyPoseObservation.JointName, 
                         vertex: VNHumanBodyPoseObservation.JointName, 
                         second: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        guard let firstPoint = point(first),
              let vertexPoint = point(vertex),
              let secondPoint = point(second) else {
            return nil
        }
        
        return PTChampion.calculateAngle(point1: firstPoint.location, 
                              centerPoint: vertexPoint.location, 
                              point2: secondPoint.location)
    }
}

// Helper functions - making them available at model level rather than just in graders

// Utility to average two angles, handling nil values
func averageAngle(_ angle1: CGFloat?, _ angle2: CGFloat?) -> CGFloat? {
    switch (angle1, angle2) {
    case (.some(let a1), .some(let a2)): return (a1 + a2) / 2.0
    case (.some(let a1), .none): return a1
    case (.none, .some(let a2)): return a2
    case (.none, .none): return nil
    }
}

// Utility to average multiple angles, ignoring nil values
func averageAngles(_ angles: [CGFloat?]) -> CGFloat? {
    let validAngles = angles.compactMap { $0 }
    guard !validAngles.isEmpty else { return nil }
    return validAngles.reduce(0, +) / CGFloat(validAngles.count)
}

// Simple linear interpolation between two values
func linearInterpolate(from: CGFloat, to: CGFloat, factor: CGFloat) -> CGFloat {
    return from + (to - from) * factor
} 