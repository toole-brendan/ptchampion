import SwiftUI
import Vision // For JointName constants

// SwiftUI view to draw detected pose landmarks over the camera feed
struct PoseOverlayView: View {
    let detectedBody: DetectedBody?
    // Specify which joints to draw connections between
    private let jointPairs: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Torso
        (.neck, .root), // Use root (hip center) for torso line
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        // Left Arm
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        // Right Arm
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        // Left Leg
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        // Right Leg
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        // Use Canvas for efficient drawing (iOS 15+)
        Canvas { context, size in
            guard let body = detectedBody else { return }

            // Draw connections (lines)
            for (joint1Name, joint2Name) in jointPairs {
                guard let p1 = body.point(joint1Name),
                      let p2 = body.point(joint2Name),
                      p1.confidence > 0.2, p2.confidence > 0.2 else { continue } // Min confidence for line

                let point1 = CGPoint(x: p1.location.x * size.width, y: p1.location.y * size.height)
                let point2 = CGPoint(x: p2.location.x * size.width, y: p2.location.y * size.height)

                var path = Path()
                path.move(to: point1)
                path.addLine(to: point2)

                context.stroke(path, with: .color(.green.opacity(0.7)), lineWidth: 3)
            }

            // Draw points (circles)
            for point in body.allPoints where point.confidence > 0.3 { // Min confidence for point
                let location = CGPoint(x: point.location.x * size.width, y: point.location.y * size.height)
                let circleRadius: CGFloat = 5

                let circleRect = CGRect(x: location.x - circleRadius,
                                        y: location.y - circleRadius,
                                        width: circleRadius * 2,
                                        height: circleRadius * 2)
                context.fill(Path(ellipseIn: circleRect), with: .color(.blue.opacity(0.8)))
            }
        }
        // Important: The overlay should ignore user interaction
        .allowsHitTesting(false)
    }
}

// Preview helper
#Preview {
    // Create some mock data for previewing the overlay
    let mockPoints: [VNHumanBodyPoseObservation.JointName: DetectedPoint] = [
        .neck: DetectedPoint(name: .neck, location: CGPoint(x: 0.5, y: 0.2), confidence: 0.9),
        .root: DetectedPoint(name: .root, location: CGPoint(x: 0.5, y: 0.5), confidence: 0.9),
        .leftShoulder: DetectedPoint(name: .leftShoulder, location: CGPoint(x: 0.3, y: 0.25), confidence: 0.9),
        .rightShoulder: DetectedPoint(name: .rightShoulder, location: CGPoint(x: 0.7, y: 0.25), confidence: 0.9),
        .leftElbow: DetectedPoint(name: .leftElbow, location: CGPoint(x: 0.2, y: 0.4), confidence: 0.9),
        .leftWrist: DetectedPoint(name: .leftWrist, location: CGPoint(x: 0.1, y: 0.55), confidence: 0.9),
        .leftHip: DetectedPoint(name: .leftHip, location: CGPoint(x: 0.4, y: 0.5), confidence: 0.9),
        .rightHip: DetectedPoint(name: .rightHip, location: CGPoint(x: 0.6, y: 0.5), confidence: 0.9),
        .leftKnee: DetectedPoint(name: .leftKnee, location: CGPoint(x: 0.35, y: 0.7), confidence: 0.9),
        .leftAnkle: DetectedPoint(name: .leftAnkle, location: CGPoint(x: 0.3, y: 0.9), confidence: 0.9)
    ]
    let mockBody = DetectedBody(points: mockPoints, confidence: 0.9)

    return PoseOverlayView(detectedBody: mockBody)
        .background(Color.gray) // Add background for visibility
} 