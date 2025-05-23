// ios/ptchampion/Grading/APFTRepValidator+OrientationFix.swift

import Foundation
import UIKit
import Vision
import CoreGraphics
import simd

extension APFTRepValidator {
    
    // MARK: - Orientation-Aware Angle Calculation
    
    /// Get the current device orientation
    private var currentOrientation: UIInterfaceOrientation {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
    }
    
    /// Calculate body alignment angle with orientation awareness
    func getBodyAlignmentAngleWithOrientation(body: DetectedBody) -> Float? {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftAnkle = body.point(.leftAnkle),
              let rightAnkle = body.point(.rightAnkle) else {
            return nil
        }
        
        // Calculate midpoints
        let shoulderMid = CGPoint(
            x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
            y: (leftShoulder.location.y + rightShoulder.location.y) / 2
        )
        let hipMid = CGPoint(
            x: (leftHip.location.x + rightHip.location.x) / 2,
            y: (leftHip.location.y + rightHip.location.y) / 2
        )
        let ankleMid = CGPoint(
            x: (leftAnkle.location.x + rightAnkle.location.x) / 2,
            y: (leftAnkle.location.y + rightAnkle.location.y) / 2
        )
        
        // In landscape mode, the coordinate system is rotated
        // For pushups in landscape, we need to check if the body forms a straight line
        
        // Different approach: measure the distance of hip from the line between shoulder and ankle
        // This gives us a better measure of how "sagged" or "piked" the body is
        
        // Vector from shoulder to ankle
        let shoulderToAnkle = simd_float2(
            Float(ankleMid.x - shoulderMid.x),
            Float(ankleMid.y - shoulderMid.y)
        )
        
        // Vector from shoulder to hip
        let shoulderToHip = simd_float2(
            Float(hipMid.x - shoulderMid.x),
            Float(hipMid.y - shoulderMid.y)
        )
        
        // Calculate the projection of hip point onto the shoulder-ankle line
        let shoulderToAnkleLength = simd_length(shoulderToAnkle)
        guard shoulderToAnkleLength > 0 else { return 0 }
        
        // Normalized direction vector
        let shoulderToAnkleNorm = shoulderToAnkle / shoulderToAnkleLength
        
        // Project shoulder-to-hip onto the shoulder-ankle line
        let projection = simd_dot(shoulderToHip, shoulderToAnkleNorm)
        let projectionPoint = shoulderToAnkleNorm * projection
        
        // Calculate perpendicular distance from hip to the line
        let perpVector = shoulderToHip - projectionPoint
        let perpDistance = simd_length(perpVector)
        
        // Convert to angle for consistency with existing code
        // Use the ratio of perpendicular distance to body length
        let bodyLength = shoulderToAnkleLength
        let ratio = perpDistance / bodyLength
        
        // Convert ratio to approximate angle (in degrees)
        // A ratio of 0.1 (10% of body length) corresponds to about 10-15 degrees
        let angleDeviation = ratio * 100.0  // Rough conversion
        
        print("DEBUG: Body alignment - Orientation: \(currentOrientation.rawValue)")
        print("DEBUG: Shoulder: \(shoulderMid), Hip: \(hipMid), Ankle: \(ankleMid)")
        print("DEBUG: Perp distance: \(perpDistance), Body length: \(bodyLength), Ratio: \(ratio)")
        print("DEBUG: Calculated angle deviation: \(angleDeviation)°")
        
        return angleDeviation
    }
    
    /// Updated APFT Standards with more lenient thresholds for real-world use
    struct UpdatedAPFTStandards {
        // Pushup standards - slightly more lenient
        static let pushupArmExtensionAngle: Float = 150.0  // Reduced from 160
        static let pushupArmParallelAngle: Float = 100.0   // Increased from 95
        static let pushupBodyAlignmentTolerance: Float = 25.0  // Increased from 15
        static let pushupMinDescentThreshold: Float = 0.015  // Reduced from 0.02
        static let pushupPositionTolerance: Float = 0.02   // Increased from 0.01
    }
}
