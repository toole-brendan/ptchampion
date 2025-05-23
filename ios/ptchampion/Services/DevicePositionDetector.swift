import Foundation
import CoreMotion
import simd

/// Detects device positioning to support flexible device placement during calibration
struct DevicePositionDetector {
    
    // MARK: - Position Types
    enum Position: Equatable {
        case ground(angle: Float)
        case elevated(height: Float, angle: Float)
        case handheld
        case tripod(height: Float, angle: Float)
        case unknown
        
        var isStable: Bool {
            switch self {
            case .ground, .elevated, .tripod:
                return true
            case .handheld, .unknown:
                return false
            }
        }
        
        var description: String {
            switch self {
            case .ground(let angle):
                return "Ground level (\(Int(angle))°)"
            case .elevated(let height, let angle):
                return "Elevated \(String(format: "%.1f", height))m (\(Int(angle))°)"
            case .tripod(let height, let angle):
                return "Tripod mount \(String(format: "%.1f", height))m (\(Int(angle))°)"
            case .handheld:
                return "Handheld"
            case .unknown:
                return "Unknown position"
            }
        }
    }
    
    // MARK: - Detection Configuration
    private struct DetectionConstants {
        static let stabilityThreshold: Float = 0.8
        static let handshakeThreshold: Float = 0.3
        static let groundAngleThreshold: Float = 30.0
        static let elevatedHeightMin: Float = 0.5
        static let tripodStabilityThreshold: Float = 0.95
        static let poseVariabilityThreshold: Float = 0.05
        static let analysisWindow: Int = 30 // frames
    }
    
    // MARK: - Public Detection Methods
    static func detectPosition(
        from frames: [CalibrationFrame],
        motionData: CMDeviceMotion?
    ) -> Position {
        guard !frames.isEmpty else { return .unknown }
        
        // Use most recent frames for analysis
        let analysisFrames = Array(frames.suffix(DetectionConstants.analysisWindow))
        
        if let motion = motionData {
            return analyzeWithMotionData(frames: analysisFrames, motion: motion)
        } else {
            return analyzeFromPoseOnly(frames: analysisFrames)
        }
    }
    
    static func detectPositionContinuous(
        recentFrames: [CalibrationFrame],
        motionHistory: [DeviceMotionData]
    ) -> Position {
        guard !recentFrames.isEmpty else { return .unknown }
        
        let stability = calculateStabilityFromMotion(motionHistory)
        let poseConsistency = calculatePoseConsistency(recentFrames)
        let deviceAngles = extractDeviceAngles(motionHistory)
        
        return classifyPosition(
            stability: stability,
            poseConsistency: poseConsistency,
            deviceAngles: deviceAngles,
            poseFrames: recentFrames
        )
    }
    
    // MARK: - Motion-Based Analysis
    private static func analyzeWithMotionData(
        frames: [CalibrationFrame],
        motion: CMDeviceMotion
    ) -> Position {
        // Extract motion characteristics
        let pitch = Float(motion.attitude.pitch * 180 / .pi)
        let roll = Float(motion.attitude.roll * 180 / .pi)
        let acceleration = motion.userAcceleration
        
        // Calculate stability from acceleration
        let accelerationMagnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        let stability = 1.0 - min(Float(accelerationMagnitude), 1.0)
        
        // Calculate rotation stability
        let rotationRate = motion.rotationRate
        let rotationMagnitude = sqrt(
            rotationRate.x * rotationRate.x +
            rotationRate.y * rotationRate.y +
            rotationRate.z * rotationRate.z
        )
        let rotationStability = 1.0 - min(Float(rotationMagnitude / 2.0), 1.0)
        
        // Combined stability
        let overallStability = (stability + rotationStability) / 2.0
        
        // Analyze pose characteristics
        let poseMetrics = analyzePoseMetrics(frames)
        
        return classifyPositionFromMotion(
            pitch: pitch,
            roll: roll,
            stability: overallStability,
            poseMetrics: poseMetrics
        )
    }
    
    private static func classifyPositionFromMotion(
        pitch: Float,
        roll: Float,
        stability: Float,
        poseMetrics: PoseMetrics
    ) -> Position {
        // Very high stability suggests tripod or secure mounting
        if stability > DetectionConstants.tripodStabilityThreshold {
            let estimatedHeight = estimateDeviceHeight(from: poseMetrics)
            return .tripod(height: estimatedHeight, angle: abs(pitch))
        }
        
        // High stability suggests stable placement
        if stability > DetectionConstants.stabilityThreshold {
            if abs(pitch) < DetectionConstants.groundAngleThreshold {
                return .ground(angle: pitch)
            } else {
                let estimatedHeight = estimateDeviceHeight(from: poseMetrics)
                if estimatedHeight > DetectionConstants.elevatedHeightMin {
                    return .elevated(height: estimatedHeight, angle: pitch)
                } else {
                    return .ground(angle: pitch)
                }
            }
        }
        
        // Low stability suggests handheld
        if stability < DetectionConstants.handshakeThreshold {
            return .handheld
        }
        
        // Medium stability - analyze further
        let estimatedHeight = estimateDeviceHeight(from: poseMetrics)
        if estimatedHeight > DetectionConstants.elevatedHeightMin && abs(pitch) > 20 {
            return .elevated(height: estimatedHeight, angle: pitch)
        } else {
            return .ground(angle: pitch)
        }
    }
    
    // MARK: - Pose-Only Analysis
    private static func analyzeFromPoseOnly(frames: [CalibrationFrame]) -> Position {
        let poseMetrics = analyzePoseMetrics(frames)
        
        // Calculate pose stability indicators
        let scaleVariability = calculateScaleVariability(frames)
        let positionDrift = calculatePositionDrift(frames)
        
        // Estimate stability from pose consistency
        let poseStability = 1.0 - min(scaleVariability + positionDrift, 1.0)
        
        if poseStability > DetectionConstants.stabilityThreshold {
            // Stable placement - determine type from pose characteristics
            return classifyFromPoseCharacteristics(poseMetrics, poseStability)
        } else if scaleVariability > DetectionConstants.poseVariabilityThreshold * 3 {
            return .handheld
        } else {
            // Medium stability
            let estimatedHeight = estimateDeviceHeight(from: poseMetrics)
            let estimatedAngle = estimateDeviceAngle(from: poseMetrics)
            
            if estimatedHeight > DetectionConstants.elevatedHeightMin {
                return .elevated(height: estimatedHeight, angle: estimatedAngle)
            } else {
                return .ground(angle: estimatedAngle)
            }
        }
    }
    
    private static func classifyFromPoseCharacteristics(
        _ metrics: PoseMetrics,
        _ stability: Float
    ) -> Position {
        let estimatedHeight = estimateDeviceHeight(from: metrics)
        let estimatedAngle = estimateDeviceAngle(from: metrics)
        
        // Very high stability suggests tripod
        if stability > DetectionConstants.tripodStabilityThreshold {
            return .tripod(height: estimatedHeight, angle: estimatedAngle)
        }
        
        // Classify based on height and viewing angle
        if estimatedHeight > DetectionConstants.elevatedHeightMin {
            return .elevated(height: estimatedHeight, angle: estimatedAngle)
        } else {
            return .ground(angle: estimatedAngle)
        }
    }
    
    // MARK: - Continuous Analysis Support
    private static func calculateStabilityFromMotion(_ motionHistory: [DeviceMotionData]) -> Float {
        guard !motionHistory.isEmpty else { return 0.0 }
        
        var totalStability: Float = 0.0
        
        for motion in motionHistory {
            let accelerationMagnitude = sqrt(
                Float(motion.userAcceleration.x * motion.userAcceleration.x +
                     motion.userAcceleration.y * motion.userAcceleration.y +
                     motion.userAcceleration.z * motion.userAcceleration.z)
            )
            
            let rotationMagnitude = sqrt(
                Float(motion.rotationRate.x * motion.rotationRate.x +
                     motion.rotationRate.y * motion.rotationRate.y +
                     motion.rotationRate.z * motion.rotationRate.z)
            )
            
            let frameStability = 1.0 - min(accelerationMagnitude + rotationMagnitude / 2.0, 1.0)
            totalStability += frameStability
        }
        
        return totalStability / Float(motionHistory.count)
    }
    
    private static func calculatePoseConsistency(_ frames: [CalibrationFrame]) -> Float {
        guard frames.count > 1 else { return 1.0 }
        
        let scaleVariability = calculateScaleVariability(frames)
        let positionDrift = calculatePositionDrift(frames)
        
        return 1.0 - min(scaleVariability + positionDrift, 1.0)
    }
    
    private static func extractDeviceAngles(_ motionHistory: [DeviceMotionData]) -> (pitch: Float, roll: Float) {
        guard !motionHistory.isEmpty else { return (0, 0) }
        
        let avgPitch = motionHistory.map { Float($0.attitude.pitch * 180 / .pi) }.reduce(0, +) / Float(motionHistory.count)
        let avgRoll = motionHistory.map { Float($0.attitude.roll * 180 / .pi) }.reduce(0, +) / Float(motionHistory.count)
        
        return (avgPitch, avgRoll)
    }
    
    private static func classifyPosition(
        stability: Float,
        poseConsistency: Float,
        deviceAngles: (pitch: Float, roll: Float),
        poseFrames: [CalibrationFrame]
    ) -> Position {
        let combinedStability = (stability + poseConsistency) / 2.0
        let poseMetrics = analyzePoseMetrics(poseFrames)
        
        if combinedStability > DetectionConstants.tripodStabilityThreshold {
            let height = estimateDeviceHeight(from: poseMetrics)
            return .tripod(height: height, angle: abs(deviceAngles.pitch))
        } else if combinedStability > DetectionConstants.stabilityThreshold {
            if abs(deviceAngles.pitch) < DetectionConstants.groundAngleThreshold {
                return .ground(angle: deviceAngles.pitch)
            } else {
                let height = estimateDeviceHeight(from: poseMetrics)
                return .elevated(height: height, angle: deviceAngles.pitch)
            }
        } else {
            return .handheld
        }
    }
    
    // MARK: - Pose Analysis Helpers
    private struct PoseMetrics {
        let averageScale: Float
        let bodyCenter: (x: Float, y: Float)
        let bodyBounds: (width: Float, height: Float)
        let headPosition: Float // Y coordinate of head relative to frame
        let averageConfidence: Float
    }
    
    private static func analyzePoseMetrics(_ frames: [CalibrationFrame]) -> PoseMetrics {
        guard !frames.isEmpty else {
            return PoseMetrics(
                averageScale: 0.5,
                bodyCenter: (0.5, 0.5),
                bodyBounds: (0.3, 0.8),
                headPosition: 0.2,
                averageConfidence: 0.0
            )
        }
        
        var totalScale: Float = 0.0
        var totalCenterX: Float = 0.0
        var totalCenterY: Float = 0.0
        var totalWidth: Float = 0.0
        var totalHeight: Float = 0.0
        var totalHeadY: Float = 0.0
        var totalConfidence: Float = 0.0
        var validFrames = 0
        
        for frame in frames {
            let body = frame.poseData
            
            // Calculate body center
            if let leftShoulder = body.point(.leftShoulder),
               let rightShoulder = body.point(.rightShoulder),
               let leftHip = body.point(.leftHip),
               let rightHip = body.point(.rightHip) {
                
                let centerX = (leftShoulder.location.x + rightShoulder.location.x + leftHip.location.x + rightHip.location.x) / 4.0
                let centerY = (leftShoulder.location.y + rightShoulder.location.y + leftHip.location.y + rightHip.location.y) / 4.0
                
                totalCenterX += Float(centerX)
                totalCenterY += Float(centerY)
                
                // Calculate body dimensions
                let shoulderWidth = leftShoulder.distance(to: rightShoulder)
                let hipWidth = leftHip.distance(to: rightHip)
                let bodyHeight = abs(leftShoulder.location.y - leftHip.location.y)
                
                totalWidth += Float(max(shoulderWidth, hipWidth))
                totalHeight += Float(bodyHeight)
                totalScale += Float(shoulderWidth + bodyHeight) / 2.0
                
                // Head position
                if let nose = body.point(.nose) {
                    totalHeadY += Float(nose.location.y)
                }
                
                // Confidence
                let confidence = body.allPoints.map(\.confidence).reduce(0, +) / Float(body.allPoints.count)
                totalConfidence += confidence
                
                validFrames += 1
            }
        }
        
        guard validFrames > 0 else {
            return PoseMetrics(
                averageScale: 0.5,
                bodyCenter: (0.5, 0.5),
                bodyBounds: (0.3, 0.8),
                headPosition: 0.2,
                averageConfidence: 0.0
            )
        }
        
        return PoseMetrics(
            averageScale: totalScale / Float(validFrames),
            bodyCenter: (totalCenterX / Float(validFrames), totalCenterY / Float(validFrames)),
            bodyBounds: (totalWidth / Float(validFrames), totalHeight / Float(validFrames)),
            headPosition: totalHeadY / Float(validFrames),
            averageConfidence: totalConfidence / Float(validFrames)
        )
    }
    
    private static func calculateScaleVariability(_ frames: [CalibrationFrame]) -> Float {
        guard frames.count > 1 else { return 0.0 }
        
        let scales = frames.compactMap { frame -> Float? in
            let body = frame.poseData
            guard let leftShoulder = body.point(.leftShoulder),
                  let rightShoulder = body.point(.rightShoulder) else { return nil }
            return Float(leftShoulder.distance(to: rightShoulder))
        }
        
        guard scales.count > 1 else { return 0.0 }
        
        let mean = scales.reduce(0, +) / Float(scales.count)
        let variance = scales.map { pow($0 - mean, 2) }.reduce(0, +) / Float(scales.count)
        return sqrt(variance) / mean // Coefficient of variation
    }
    
    private static func calculatePositionDrift(_ frames: [CalibrationFrame]) -> Float {
        guard frames.count > 1 else { return 0.0 }
        
        let positions = frames.compactMap { frame -> (Float, Float)? in
            let body = frame.poseData
            guard let leftShoulder = body.point(.leftShoulder),
                  let rightShoulder = body.point(.rightShoulder) else { return nil }
            
            let centerX = Float((leftShoulder.location.x + rightShoulder.location.x) / 2.0)
            let centerY = Float((leftShoulder.location.y + rightShoulder.location.y) / 2.0)
            return (centerX, centerY)
        }
        
        guard positions.count > 1 else { return 0.0 }
        
        var totalDrift: Float = 0.0
        for i in 1..<positions.count {
            let dx = positions[i].0 - positions[i-1].0
            let dy = positions[i].1 - positions[i-1].1
            totalDrift += sqrt(dx * dx + dy * dy)
        }
        
        return totalDrift / Float(positions.count - 1)
    }
    
    // MARK: - Height and Angle Estimation
    private static func estimateDeviceHeight(from metrics: PoseMetrics) -> Float {
        // Estimate device height based on pose scale and head position
        // This is a simplified estimation - in practice, you might use more sophisticated methods
        
        let normalizedScale = metrics.averageScale
        let headY = metrics.headPosition
        
        // Lower head position suggests higher camera
        // Larger pose scale suggests closer/lower camera
        let heightFactor = (1.0 - headY) * 2.0 + (1.0 - normalizedScale)
        
        // Map to reasonable height range (0.3m to 2.5m)
        return 0.3 + heightFactor * 2.2
    }
    
    private static func estimateDeviceAngle(from metrics: PoseMetrics) -> Float {
        // Estimate viewing angle based on body proportions and head position
        let headY = metrics.headPosition
        let bodyHeight = metrics.bodyBounds.height
        
        // Higher head position suggests lower angle
        // Shorter apparent body height suggests higher angle
        let angleIndicator = (0.5 - headY) * 2.0 + (0.8 - bodyHeight) * 0.5
        
        // Map to angle range (-60° to +60°)
        return angleIndicator * 60.0
    }
}

// MARK: - Extensions for Array calculations
private extension Array where Element == Float {
    func average() -> Float {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Float(count)
    }
    
    func standardDeviation() -> Float {
        guard count > 1 else { return 0 }
        let avg = average()
        let variance = map { pow($0 - avg, 2) }.reduce(0, +) / Float(count - 1)
        return sqrt(variance)
    }
} 