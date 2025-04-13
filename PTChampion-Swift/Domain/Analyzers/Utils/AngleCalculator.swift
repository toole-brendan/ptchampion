import Foundation
import MediaPipeTasksVision
import simd // For vector math

/// Utility for calculating angles between 3D pose landmarks.
struct AngleCalculator {

    /// Calculates the angle between three 3D landmarks.
    ///
    /// - Parameters:
    ///   - p1: The first landmark (e.g., shoulder).
    ///   - p2: The second landmark, the vertex of the angle (e.g., elbow).
    ///   - p3: The third landmark (e.g., wrist).
    ///   - minVisibility: The minimum visibility threshold for a landmark to be considered valid (default: 0.5).
    /// - Returns: The calculated angle in degrees (0-180), or `nil` if any landmark is not sufficiently visible.
    static func calculateAngle(
        _ p1: NormalizedLandmark?,
        _ p2: NormalizedLandmark?,
        _ p3: NormalizedLandmark?,
        minVisibility: Float = 0.5
    ) -> Double? {
        guard let lm1 = p1, let lm2 = p2, let lm3 = p3,
              lm1.visibility ?? 0 >= minVisibility,
              lm2.visibility ?? 0 >= minVisibility,
              lm3.visibility ?? 0 >= minVisibility else {
            return nil // One or more landmarks are not sufficiently visible
        }

        // Create 3D vectors from the landmarks relative to the vertex (p2)
        // Note: MediaPipe landmarks are (x, y, z) where y is typically downwards.
        let vector1 = simd_double3(Double(lm1.x - lm2.x), Double(lm1.y - lm2.y), Double(lm1.z - lm2.z))
        let vector2 = simd_double3(Double(lm3.x - lm2.x), Double(lm3.y - lm2.y), Double(lm3.z - lm2.z))

        // Calculate the dot product
        let dotProduct = simd_dot(vector1, vector2)

        // Calculate the magnitudes of the vectors
        let magnitude1 = simd_length(vector1)
        let magnitude2 = simd_length(vector2)

        // Avoid division by zero if magnitudes are very small
        guard magnitude1 > 1e-6, magnitude2 > 1e-6 else {
            return 0.0 // Treat as zero angle if vectors are negligible
        }

        // Calculate the cosine of the angle
        // Clamp the value to [-1.0, 1.0] to avoid domain errors with acos due to floating-point inaccuracies
        let cosTheta = max(-1.0, min(1.0, dotProduct / (magnitude1 * magnitude2)))

        // Calculate the angle in radians
        let angleRadians = acos(cosTheta)

        // Convert the angle to degrees
        let angleDegrees = angleRadians * 180.0 / .pi

        return angleDegrees
    }
} 