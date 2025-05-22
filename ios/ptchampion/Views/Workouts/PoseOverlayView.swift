// ios/ptchampion/Views/Workouts/PoseOverlayView.swift

import SwiftUI
import Vision // Only used for VNHumanBodyPoseObservation.JointName constants - no Vision detection
import PTDesignSystem // For AppTheme

// SwiftUI view to draw detected pose landmarks over the camera feed
struct PoseOverlayView: View {
    let detectedBody: DetectedBody?
    let badJointNames: Set<VNHumanBodyPoseObservation.JointName>
    
    // Add state to track how long no body has been detected
    @State private var bodyNotDetectedCounter: Int = 0
    private let showGuidanceThreshold = 45 // About 1.5 seconds at 30fps
    
    // Initialize with default empty set for bad joints
    init(detectedBody: DetectedBody?, badJointNames: Set<VNHumanBodyPoseObservation.JointName> = []) {
        self.detectedBody = detectedBody
        self.badJointNames = badJointNames
    }
    
    // Helper function to transform coordinates based on orientation
    private func transformPoint(_ normalizedPoint: CGPoint, to viewSize: CGSize) -> CGPoint {
        let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        
        var x = normalizedPoint.x
        var y = normalizedPoint.y
        
        // Adjust coordinates based on orientation
        switch interfaceOrientation {
        case .landscapeLeft:
            let temp = x
            x = 1 - y
            y = temp
        case .landscapeRight:
            let temp = x
            x = y
            y = 1 - temp
        case .portraitUpsideDown:
            x = 1 - x
            y = 1 - y
        case .portrait:
            // No transformation needed for portrait
            break
        @unknown default:
            // Default to portrait behavior
            break
        }
        
        return CGPoint(x: x * viewSize.width, y: y * viewSize.height)
    }
    
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
        (.rightKnee, .rightAnkle),
        // Feet
        (.leftAnkle, .leftHeel),
        (.leftHeel, .leftToe),
        (.rightAnkle, .rightHeel),
        (.rightHeel, .rightToe)
    ]

    var body: some View {
        ZStack {
            // Use Canvas for efficient drawing (iOS 15+)
            Canvas { context, size in
                guard let body = detectedBody else { return }

                // Draw connections (lines)
                for (joint1Name, joint2Name) in jointPairs {
                    guard let p1 = body.point(joint1Name),
                          let p2 = body.point(joint2Name),
                          p1.confidence > 0.2, p2.confidence > 0.2 else { continue } // Min confidence for line

                    let point1 = transformPoint(p1.location, to: size)
                    let point2 = transformPoint(p2.location, to: size)

                    var path = Path()
                    path.move(to: point1)
                    path.addLine(to: point2)
                    
                    // Determine if this line connects to any bad joints
                    let isBadLine = badJointNames.contains(joint1Name) || badJointNames.contains(joint2Name)
                    
                    // Use red for bad lines, yellow for good lines
                    let lineColor = isBadLine ? 
                        Color.red.opacity(0.7) : 
                        Color.yellow.opacity(0.8)
                    
                    context.stroke(path, with: .color(lineColor), lineWidth: 5)
                }

                // Draw points (circles)
                for point in body.allPoints where point.confidence > 0.3 { // Min confidence for point
                    let location = transformPoint(point.location, to: size)
                    let circleRadius: CGFloat = 5

                    let circleRect = CGRect(x: location.x - circleRadius,
                                            y: location.y - circleRadius,
                                            width: circleRadius * 2,
                                            height: circleRadius * 2)
                    
                    // Determine if this is a bad joint
                    let isBadJoint = badJointNames.contains(point.name)
                    
                    // Use red for bad joints, white with green border for good joints
                    let circleColor = isBadJoint ? 
                        AppTheme.GeneratedColors.error : 
                        Color.white
                    
                    context.fill(Path(ellipseIn: circleRect), with: .color(circleColor))
                    
                    // Add border to the circle
                    let borderColor = isBadJoint ? 
                        AppTheme.GeneratedColors.error : 
                        AppTheme.GeneratedColors.success
                    
                    context.stroke(
                        Path(ellipseIn: circleRect),
                        with: .color(borderColor),
                        lineWidth: 1.5
                    )
                }
            }
            
            // Guidance message when no body is detected for a while
            if detectedBody == nil && bodyNotDetectedCounter > showGuidanceThreshold {
                VStack {
                    Spacer()
                    
                    Text("Position yourself in view")
                        .font(AppTheme.GeneratedTypography.bodyBold(size: nil))
                        .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(AppTheme.GeneratedRadius.medium)
                        .padding(.bottom, 200)
                }
            }
        }
        // Important: The overlay should ignore user interaction
        .allowsHitTesting(false)
        .onChange(of: detectedBody) { _, newBody in
            if newBody == nil {
                // Increment counter when body not detected
                bodyNotDetectedCounter += 1
            } else {
                // Reset counter when body is detected
                bodyNotDetectedCounter = 0
            }
        }
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
    
    // Add some mock bad joints for preview
    let badJoints: Set<VNHumanBodyPoseObservation.JointName> = [.leftElbow, .leftWrist]

    return PoseOverlayView(detectedBody: mockBody, badJointNames: badJoints)
        .background(Color.gray) // Add background for visibility
} 