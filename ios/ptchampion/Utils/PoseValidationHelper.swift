import Vision

struct PoseValidationHelper {
    /// Checks if all required joints are visible with sufficient confidence.
    static func isFullBodyVisible(_ body: DetectedBody,
                                  requiredJoints: [VNHumanBodyPoseObservation.JointName],
                                  confidence minConfidence: Float) -> Bool
    {
        let missing = body.missingJoints(from: requiredJoints, minConfidence: minConfidence)
        return missing.isEmpty
    }
} 