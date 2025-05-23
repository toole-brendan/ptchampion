import Foundation
import Vision
import CoreGraphics
import simd

/// Enhanced APFT validator that integrates with calibration data for personalized accuracy
class CalibratedAPFTValidator: ObservableObject {
    
    // MARK: - Base Validator
    private let baseValidator: APFTRepValidator
    
    // MARK: - Calibration Integration
    private var calibrationData: CalibrationData?
    private var currentExercise: ExerciseType = .pushup
    
    // MARK: - Adaptive Thresholds
    private var adaptiveThresholds: AdaptiveExerciseThresholds
    
    // MARK: - Performance Tracking
    private var performanceHistory: [PerformanceFrame] = []
    private let maxHistoryFrames = 100
    
    // MARK: - Published Properties
    @Published var calibrationQuality: CalibrationQuality = .invalid
    @Published var accuracyConfidence: Float = 0.0
    @Published var adaptationLevel: AdaptationLevel = .none
    
    // MARK: - Initialization
    init(baseValidator: APFTRepValidator = APFTRepValidator()) {
        self.baseValidator = baseValidator
        self.adaptiveThresholds = AdaptiveExerciseThresholds()
    }
    
    // MARK: - Calibration Integration
    func loadCalibration(_ calibration: CalibrationData) {
        self.calibrationData = calibration
        self.currentExercise = calibration.exercise
        self.calibrationQuality = evaluateCalibrationQuality(calibration)
        
        // Apply calibration adjustments to thresholds
        applyCalibrationAdjustments(calibration)
        
        print("🎯 Loaded calibration for \(calibration.exercise.displayName)")
        print("   Quality: \(calibrationQuality)")
        print("   Confidence: \(calibration.confidenceLevel)")
    }
    
    func loadSavedCalibration(for exercise: ExerciseType) {
        guard let data = UserDefaults.standard.data(forKey: "calibration_\(exercise.rawValue)"),
              let calibration = try? JSONDecoder().decode(CalibrationData.self, from: data) else {
            print("⚠️ No saved calibration found for \(exercise.displayName)")
            return
        }
        
        loadCalibration(calibration)
    }
    
    // MARK: - Enhanced Validation Methods
    func validatePushup(body: DetectedBody) -> ValidationResult {
        let baseResult = baseValidator.validatePushup(body: body)
        
        guard let calibration = calibrationData, calibration.exercise == .pushup else {
            return ValidationResult(
                isValid: baseResult,
                confidence: 0.5,
                adjustedAngles: [:],
                formScore: calculateBasicFormScore(body: body),
                feedback: generateBasicFeedback(body: body, exercise: .pushup)
            )
        }
        
        return validateWithCalibration(body: body, exercise: .pushup, baseValid: baseResult)
    }
    
    func validateSitup(body: DetectedBody) -> ValidationResult {
        let baseResult = baseValidator.validateSitup(body: body)
        
        guard let calibration = calibrationData, calibration.exercise == .situp else {
            return ValidationResult(
                isValid: baseResult,
                confidence: 0.5,
                adjustedAngles: [:],
                formScore: calculateBasicFormScore(body: body),
                feedback: generateBasicFeedback(body: body, exercise: .situp)
            )
        }
        
        return validateWithCalibration(body: body, exercise: .situp, baseValid: baseResult)
    }
    
    func validatePullup(body: DetectedBody, barHeightY: Float = 0.2) -> ValidationResult {
        let baseResult = baseValidator.validatePullup(body: body, barHeightY: barHeightY)
        
        guard let calibration = calibrationData, calibration.exercise == .pullup else {
            return ValidationResult(
                isValid: baseResult,
                confidence: 0.5,
                adjustedAngles: [:],
                formScore: calculateBasicFormScore(body: body),
                feedback: generateBasicFeedback(body: body, exercise: .pullup)
            )
        }
        
        return validateWithCalibration(body: body, exercise: .pullup, baseValid: baseResult)
    }
    
    // MARK: - Calibrated Validation
    private func validateWithCalibration(body: DetectedBody, exercise: ExerciseType, baseValid: Bool) -> ValidationResult {
        guard let calibration = calibrationData else {
            fatalError("Calibration data should be available")
        }
        
        // Calculate adjusted angles based on calibration
        let adjustedAngles = calculateAdjustedAngles(body: body, calibration: calibration)
        
        // Validate visibility with calibrated thresholds
        let visibilityValid = validateVisibility(body: body, thresholds: calibration.visibilityThresholds)
        
        // Calculate confidence based on calibration quality and pose quality
        let confidence = calculateValidationConfidence(
            body: body,
            calibration: calibration,
            adjustedAngles: adjustedAngles
        )
        
        // Calculate enhanced form score
        let formScore = calculateCalibratedFormScore(
            body: body,
            calibration: calibration,
            adjustedAngles: adjustedAngles
        )
        
        // Generate detailed feedback
        let feedback = generateCalibratedFeedback(
            body: body,
            calibration: calibration,
            adjustedAngles: adjustedAngles,
            baseValid: baseValid
        )
        
        // Update performance history
        updatePerformanceHistory(body: body, formScore: formScore, confidence: confidence)
        
        // Determine final validity
        let isValid = baseValid && visibilityValid && confidence > 0.6
        
        return ValidationResult(
            isValid: isValid,
            confidence: confidence,
            adjustedAngles: adjustedAngles,
            formScore: formScore,
            feedback: feedback
        )
    }
    
    // MARK: - Calibration Adjustments
    private func applyCalibrationAdjustments(_ calibration: CalibrationData) {
        adaptiveThresholds.updateForCalibration(calibration)
        
        // Update accuracy confidence based on calibration quality
        accuracyConfidence = calibration.confidenceLevel
        
        // Determine adaptation level
        adaptationLevel = determineAdaptationLevel(calibration)
        
        print("📊 Applied calibration adjustments:")
        print("   Device angle: \(calibration.deviceAngle)°")
        print("   User height: \(calibration.userHeight)m")
        print("   Adaptation level: \(adaptationLevel)")
    }
    
    private func determineAdaptationLevel(_ calibration: CalibrationData) -> AdaptationLevel {
        let score = calibration.calibrationScore
        let confidence = calibration.confidenceLevel
        
        if score >= 90 && confidence >= 0.9 {
            return .high
        } else if score >= 75 && confidence >= 0.7 {
            return .medium
        } else if score >= 60 && confidence >= 0.5 {
            return .low
        } else {
            return .none
        }
    }
    
    // MARK: - Angle Calculations
    private func calculateAdjustedAngles(body: DetectedBody, calibration: CalibrationData) -> [String: Float] {
        var adjustedAngles: [String: Float] = [:]
        
        switch calibration.exercise {
        case .pushup:
            adjustedAngles = calculatePushupAngles(body: body, calibration: calibration)
        case .situp:
            adjustedAngles = calculateSitupAngles(body: body, calibration: calibration)
        case .pullup:
            adjustedAngles = calculatePullupAngles(body: body, calibration: calibration)
        default:
            break
        }
        
        return adjustedAngles
    }
    
    private func calculatePushupAngles(body: DetectedBody, calibration: CalibrationData) -> [String: Float] {
        var angles: [String: Float] = [:]
        
        // Left arm angle
        if let leftShoulder = body.point(.leftShoulder),
           let leftElbow = body.point(.leftElbow),
           let leftWrist = body.point(.leftWrist) {
            let rawAngle = calculateAngle(
                point1: leftShoulder.location,
                vertex: leftElbow.location,
                point3: leftWrist.location
            )
            
            // Apply calibration adjustment
            let adjustedAngle = rawAngle + calibration.angleAdjustments.pushupElbowUp - 170.0
            angles["left_elbow"] = adjustedAngle
        }
        
        // Right arm angle
        if let rightShoulder = body.point(.rightShoulder),
           let rightElbow = body.point(.rightElbow),
           let rightWrist = body.point(.rightWrist) {
            let rawAngle = calculateAngle(
                point1: rightShoulder.location,
                vertex: rightElbow.location,
                point3: rightWrist.location
            )
            
            let adjustedAngle = rawAngle + calibration.angleAdjustments.pushupElbowDown - 90.0
            angles["right_elbow"] = adjustedAngle
        }
        
        // Body alignment angle
        if let bodyAngle = calculateBodyAlignment(body: body) {
            let adjustedBodyAngle = bodyAngle - calibration.angleAdjustments.pushupBodyAlignment
            angles["body_alignment"] = adjustedBodyAngle
        }
        
        return angles
    }
    
    private func calculateSitupAngles(body: DetectedBody, calibration: CalibrationData) -> [String: Float] {
        var angles: [String: Float] = [:]
        
        // Torso angle
        if let leftShoulder = body.point(.leftShoulder),
           let rightShoulder = body.point(.rightShoulder),
           let leftHip = body.point(.leftHip),
           let rightHip = body.point(.rightHip) {
            
            let shoulderMid = CGPoint(
                x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
                y: (leftShoulder.location.y + rightShoulder.location.y) / 2
            )
            let hipMid = CGPoint(
                x: (leftHip.location.x + rightHip.location.x) / 2,
                y: (leftHip.location.y + rightHip.location.y) / 2
            )
            
            let torsoAngle = atan2(shoulderMid.y - hipMid.y, shoulderMid.x - hipMid.x) * 180.0 / .pi
            let adjustedTorsoAngle = Float(torsoAngle) + calibration.angleAdjustments.situpTorsoUp - 90.0
            angles["torso"] = adjustedTorsoAngle
        }
        
        // Knee angle
        if let leftHip = body.point(.leftHip),
           let leftKnee = body.point(.leftKnee),
           let leftAnkle = body.point(.leftAnkle) {
            let kneeAngle = calculateAngle(
                point1: leftHip.location,
                vertex: leftKnee.location,
                point3: leftAnkle.location
            )
            let adjustedKneeAngle = kneeAngle + calibration.angleAdjustments.situpKneeAngle - 90.0
            angles["knee"] = adjustedKneeAngle
        }
        
        return angles
    }
    
    private func calculatePullupAngles(body: DetectedBody, calibration: CalibrationData) -> [String: Float] {
        var angles: [String: Float] = [:]
        
        // Arm extension angles
        if let leftShoulder = body.point(.leftShoulder),
           let leftElbow = body.point(.leftElbow),
           let leftWrist = body.point(.leftWrist) {
            let armAngle = calculateAngle(
                point1: leftShoulder.location,
                vertex: leftElbow.location,
                point3: leftWrist.location
            )
            let adjustedAngle = armAngle + calibration.angleAdjustments.pullupArmExtended - 170.0
            angles["left_arm"] = adjustedAngle
        }
        
        // Body vertical alignment
        if let bodyAngle = calculateBodyAlignment(body: body) {
            let adjustedBodyAngle = bodyAngle - calibration.angleAdjustments.pullupBodyVertical
            angles["body_vertical"] = adjustedBodyAngle
        }
        
        return angles
    }
    
    // MARK: - Validation Support
    private func validateVisibility(body: DetectedBody, thresholds: VisibilityThresholds) -> Bool {
        let criticalJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip
        ]
        
        for joint in criticalJoints {
            if let point = body.point(joint) {
                if point.confidence < thresholds.criticalJoints {
                    return false
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    private func calculateValidationConfidence(
        body: DetectedBody,
        calibration: CalibrationData,
        adjustedAngles: [String: Float]
    ) -> Float {
        var confidence: Float = calibration.confidenceLevel
        
        // Adjust based on pose quality
        let poseQuality = calculatePoseQuality(body: body, calibration: calibration)
        confidence *= poseQuality
        
        // Adjust based on angle accuracy
        let angleAccuracy = calculateAngleAccuracy(adjustedAngles: adjustedAngles, calibration: calibration)
        confidence *= angleAccuracy
        
        // Adjust based on historical performance
        let historicalAccuracy = calculateHistoricalAccuracy()
        confidence *= historicalAccuracy
        
        return max(0.0, min(1.0, confidence))
    }
    
    private func calculatePoseQuality(body: DetectedBody, calibration: CalibrationData) -> Float {
        // Calculate overall pose quality based on joint visibility and consistency
        var totalConfidence: Float = 0
        var jointCount = 0
        
        for point in body.allPoints {
            totalConfidence += point.confidence
            jointCount += 1
        }
        
        let avgConfidence = jointCount > 0 ? totalConfidence / Float(jointCount) : 0
        
        // Normalize against calibration thresholds
        let normalizedQuality = avgConfidence / calibration.visibilityThresholds.criticalJoints
        return min(1.0, normalizedQuality)
    }
    
    private func calculateAngleAccuracy(adjustedAngles: [String: Float], calibration: CalibrationData) -> Float {
        var accuracy: Float = 1.0
        
        for (angleType, angle) in adjustedAngles {
            if let tolerance = calibration.validationRanges.angleTolerances[angleType] {
                let deviation = abs(angle)
                if deviation > tolerance {
                    let penalty = min(0.3, deviation / (tolerance * 2))
                    accuracy -= penalty
                }
            }
        }
        
        return max(0.0, accuracy)
    }
    
    private func calculateHistoricalAccuracy() -> Float {
        guard performanceHistory.count >= 5 else { return 1.0 }
        
        let recentFrames = Array(performanceHistory.suffix(10))
        let avgConfidence = recentFrames.map(\.confidence).reduce(0, +) / Float(recentFrames.count)
        let avgFormScore = recentFrames.map(\.formScore).reduce(0, +) / Float(recentFrames.count)
        
        return (avgConfidence + avgFormScore) / 2.0
    }
    
    // MARK: - Form Scoring
    private func calculateCalibratedFormScore(
        body: DetectedBody,
        calibration: CalibrationData,
        adjustedAngles: [String: Float]
    ) -> Float {
        var score: Float = 1.0
        
        // Visibility component (30%)
        let visibilityScore = calculatePoseQuality(body: body, calibration: calibration)
        score *= (0.7 + 0.3 * visibilityScore)
        
        // Angle accuracy component (40%)
        let angleScore = calculateAngleAccuracy(adjustedAngles: adjustedAngles, calibration: calibration)
        score *= (0.6 + 0.4 * angleScore)
        
        // Stability component (20%)
        let stabilityScore = calculateStabilityScore(body: body)
        score *= (0.8 + 0.2 * stabilityScore)
        
        // Normalization component (10%)
        let normalizationScore = calculateNormalizationScore(body: body, calibration: calibration)
        score *= (0.9 + 0.1 * normalizationScore)
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateBasicFormScore(body: DetectedBody) -> Float {
        // Basic form score without calibration
        let avgConfidence = body.allPoints.map(\.confidence).reduce(0, +) / Float(body.allPoints.count)
        return avgConfidence
    }
    
    private func calculateStabilityScore(body: DetectedBody) -> Float {
        guard performanceHistory.count >= 3 else { return 1.0 }
        
        let recentFrames = Array(performanceHistory.suffix(3))
        var stabilityScore: Float = 1.0
        
        for i in 1..<recentFrames.count {
            let current = recentFrames[i]
            let previous = recentFrames[i-1]
            
            if abs(current.formScore - previous.formScore) > 0.2 {
                stabilityScore -= 0.2
            }
        }
        
        return max(0.0, stabilityScore)
    }
    
    private func calculateNormalizationScore(body: DetectedBody, calibration: CalibrationData) -> Float {
        // Score based on how well the pose fits the normalized measurements
        let normalization = calibration.poseNormalization
        
        // Calculate current measurements
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder) else {
            return 0.5
        }
        
        let currentShoulderWidth = Float(leftShoulder.distance(to: rightShoulder))
        let expectedShoulderWidth = normalization.shoulderWidth
        
        let widthRatio = min(currentShoulderWidth, expectedShoulderWidth) / max(currentShoulderWidth, expectedShoulderWidth)
        return widthRatio
    }
    
    // MARK: - Feedback Generation
    private func generateCalibratedFeedback(
        body: DetectedBody,
        calibration: CalibrationData,
        adjustedAngles: [String: Float],
        baseValid: Bool
    ) -> DetailedFeedback {
        var feedback = DetailedFeedback()
        
        // Visibility feedback
        feedback.visibilityIssues = analyzeVisibilityIssues(body: body, calibration: calibration)
        
        // Angle feedback
        feedback.angleIssues = analyzeAngleIssues(adjustedAngles: adjustedAngles, calibration: calibration)
        
        // Stability feedback
        feedback.stabilityIssues = analyzeStabilityIssues()
        
        // Adaptation feedback
        feedback.adaptationSuggestions = generateAdaptationSuggestions(calibration: calibration)
        
        return feedback
    }
    
    private func generateBasicFeedback(body: DetectedBody, exercise: ExerciseType) -> DetailedFeedback {
        // Basic feedback without calibration
        return DetailedFeedback()
    }
    
    private func analyzeVisibilityIssues(body: DetectedBody, calibration: CalibrationData) -> [String] {
        var issues: [String] = []
        
        let thresholds = calibration.visibilityThresholds
        let criticalJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip
        ]
        
        for joint in criticalJoints {
            if let point = body.point(joint) {
                if point.confidence < thresholds.criticalJoints {
                    issues.append("Low visibility for \(joint)")
                }
            } else {
                issues.append("Missing joint: \(joint)")
            }
        }
        
        return issues
    }
    
    private func analyzeAngleIssues(adjustedAngles: [String: Float], calibration: CalibrationData) -> [String] {
        var issues: [String] = []
        
        for (angleType, angle) in adjustedAngles {
            if let tolerance = calibration.validationRanges.angleTolerances[angleType] {
                if abs(angle) > tolerance {
                    issues.append("Angle deviation in \(angleType): \(String(format: "%.1f", angle))°")
                }
            }
        }
        
        return issues
    }
    
    private func analyzeStabilityIssues() -> [String] {
        guard performanceHistory.count >= 5 else { return [] }
        
        var issues: [String] = []
        let recentFrames = Array(performanceHistory.suffix(5))
        
        let confidenceVariation = recentFrames.map(\.confidence).reduce(0) { result, confidence in
            abs(confidence - recentFrames.first!.confidence)
        } / Float(recentFrames.count)
        
        if confidenceVariation > 0.2 {
            issues.append("Unstable pose detection")
        }
        
        return issues
    }
    
    private func generateAdaptationSuggestions(calibration: CalibrationData) -> [String] {
        var suggestions: [String] = []
        
        switch adaptationLevel {
        case .none:
            suggestions.append("Consider recalibrating for better accuracy")
        case .low:
            suggestions.append("Calibration quality could be improved")
        case .medium:
            suggestions.append("Good calibration - maintain consistent positioning")
        case .high:
            suggestions.append("Excellent calibration - optimal accuracy expected")
        }
        
        return suggestions
    }
    
    // MARK: - Performance Tracking
    private func updatePerformanceHistory(body: DetectedBody, formScore: Float, confidence: Float) {
        let frame = PerformanceFrame(
            timestamp: Date(),
            formScore: formScore,
            confidence: confidence,
            jointCount: body.allPoints.count
        )
        
        performanceHistory.append(frame)
        
        if performanceHistory.count > maxHistoryFrames {
            performanceHistory.removeFirst()
        }
    }
    
    // MARK: - Utility Methods
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let v1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let v2 = CGPoint(x: point3.x - vertex.x, y: point3.y - vertex.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCosAngle) * 180.0 / .pi)
    }
    
    private func calculateBodyAlignment(body: DetectedBody) -> Float? {
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip) else {
            return nil
        }
        
        let shoulderMid = CGPoint(
            x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
            y: (leftShoulder.location.y + rightShoulder.location.y) / 2
        )
        let hipMid = CGPoint(
            x: (leftHip.location.x + rightHip.location.x) / 2,
            y: (leftHip.location.y + rightHip.location.y) / 2
        )
        
        let bodyVector = CGPoint(x: shoulderMid.x - hipMid.x, y: shoulderMid.y - hipMid.y)
        let verticalVector = CGPoint(x: 0, y: 1)
        
        let dot = bodyVector.x * verticalVector.x + bodyVector.y * verticalVector.y
        let bodyMag = sqrt(bodyVector.x * bodyVector.x + bodyVector.y * bodyVector.y)
        
        guard bodyMag > 0 else { return 0 }
        
        let cosAngle = dot / bodyMag
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCosAngle) * 180.0 / .pi)
    }
    
    private func evaluateCalibrationQuality(_ calibration: CalibrationData) -> CalibrationQuality {
        let score = calibration.calibrationScore
        
        switch score {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .acceptable
        case 60..<70: return .poor
        default: return .invalid
        }
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let confidence: Float
    let adjustedAngles: [String: Float]
    let formScore: Float
    let feedback: DetailedFeedback
}

struct DetailedFeedback {
    var visibilityIssues: [String] = []
    var angleIssues: [String] = []
    var stabilityIssues: [String] = []
    var adaptationSuggestions: [String] = []
}

struct AdaptiveExerciseThresholds {
    var pushupElbowExtension: Float = 170.0
    var pushupElbowFlexion: Float = 90.0
    var pushupBodyAlignment: Float = 15.0
    
    var situpTorsoUp: Float = 90.0
    var situpTorsoDown: Float = 45.0
    var situpKneeAngle: Float = 90.0
    
    var pullupArmExtension: Float = 170.0
    var pullupArmFlexion: Float = 90.0
    var pullupBodyVertical: Float = 20.0
    
    mutating func updateForCalibration(_ calibration: CalibrationData) {
        let adjustments = calibration.angleAdjustments
        
        switch calibration.exercise {
        case .pushup:
            pushupElbowExtension = adjustments.pushupElbowUp
            pushupElbowFlexion = adjustments.pushupElbowDown
            pushupBodyAlignment = adjustments.pushupBodyAlignment
        case .situp:
            situpTorsoUp = adjustments.situpTorsoUp
            situpTorsoDown = adjustments.situpTorsoDown
            situpKneeAngle = adjustments.situpKneeAngle
        case .pullup:
            pullupArmExtension = adjustments.pullupArmExtended
            pullupArmFlexion = adjustments.pullupArmFlexed
            pullupBodyVertical = adjustments.pullupBodyVertical
        default:
            break
        }
    }
}

struct PerformanceFrame {
    let timestamp: Date
    let formScore: Float
    let confidence: Float
    let jointCount: Int
}

enum AdaptationLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .none: return "No adaptation"
        case .low: return "Basic adaptation"
        case .medium: return "Good adaptation"
        case .high: return "Optimal adaptation"
        }
    }
} 