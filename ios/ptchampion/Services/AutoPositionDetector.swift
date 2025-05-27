import Foundation
import Vision
import Combine
import MediaPipeTasksVision

/// Automatic position detection service that leverages MediaPipe landmarks
/// to detect when users are in correct starting positions without manual calibration
class AutoPositionDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedExercise: ExerciseType?
    @Published var isInPosition: Bool = false
    @Published var positionQuality: Float = 0.0 // 0-1 score
    @Published var primaryInstruction: String = "Get into starting position"
    @Published var missingRequirements: [String] = []
    @Published var confidenceScore: Float = 0.0
    @Published var currentDetection: PositionDetectionResult?
    @Published var isDetecting = false
    
    // MARK: - Exercise-Specific Thresholds
    private let pushupThresholds = PushupThresholds()
    private let situpThresholds = SitupThresholds()
    private let pullupThresholds = PullupThresholds()
    
    // MARK: - State
    private var recentDetections: [PositionDetectionResult] = []
    private let maxRecentDetections = 10
    private var positionHoldStartTime: Date?
    private let requiredHoldDuration: TimeInterval = 2.0
    
    // MARK: - Initialization
    init() {
        // Initialize with default state
    }
    
    // MARK: - Main Detection Method
    func detectPosition(body: DetectedBody, expectedExercise: ExerciseType? = nil) -> PositionDetectionResult {
        // Convert DetectedBody to MediaPipe landmarks for analysis
        let landmarks = convertDetectedBodyToLandmarks(body)
        return detectExercisePosition(landmarks: landmarks, expectedExercise: expectedExercise)
    }
    
    func detectExercisePosition(landmarks: [NormalizedLandmark], expectedExercise: ExerciseType? = nil) -> PositionDetectionResult {
        isDetecting = true
        
        // Analyze body framing first
        let framingAnalysis = analyzeBodyFraming(landmarks)
        
        // If not properly framed, return early with framing feedback
        guard framingAnalysis.isFullyInFrame else {
            let result = PositionDetectionResult(
                detectedExercise: nil,
                isInPosition: false,
                feedback: createFramingFeedback(framingAnalysis),
                confidence: 0.0
            )
            updateState(with: result)
            return result
        }
        
        // If expected exercise is provided, analyze only that exercise
        if let expectedExercise = expectedExercise {
            let score = analyzeSpecificExercise(landmarks, exercise: expectedExercise)
            let result = PositionDetectionResult(
                detectedExercise: expectedExercise,
                isInPosition: score.isInPosition,
                feedback: score.feedback,
                confidence: score.confidence
            )
            updateState(with: result)
            return result
        }
        
        // Detect which exercise the user is attempting
        let pushupScore = analyzePushupPosition(landmarks)
        let situpScore = analyzeSitupPosition(landmarks)
        let pullupScore = analyzePullupPosition(landmarks)
        
        // Find the most likely exercise based on position scores
        let scores = [
            (ExerciseType.pushup, pushupScore),
            (ExerciseType.situp, situpScore),
            (ExerciseType.pullup, pullupScore)
        ]
        
        guard let bestMatch = scores.max(by: { $0.1.confidence < $1.1.confidence }),
              bestMatch.1.confidence > 0.6 else {
            let result = PositionDetectionResult(
                detectedExercise: nil,
                isInPosition: false,
                feedback: PositioningFeedback(
                    primaryInstruction: "Please get into starting position for your exercise",
                    visualGuide: framingAnalysis,
                    confidenceScore: 0.0,
                    missingRequirements: ["No clear exercise position detected"]
                ),
                confidence: 0.0
            )
            updateState(with: result)
            return result
        }
        
        let result = PositionDetectionResult(
            detectedExercise: bestMatch.0,
            isInPosition: bestMatch.1.isInPosition,
            feedback: bestMatch.1.feedback,
            confidence: bestMatch.1.confidence
        )
        updateState(with: result)
        return result
    }
    
    // MARK: - Exercise-Specific Analysis
    private func analyzeSpecificExercise(_ landmarks: [NormalizedLandmark], exercise: ExerciseType) -> PositionScore {
        switch exercise {
        case .pushup:
            return analyzePushupPosition(landmarks)
        case .situp:
            return analyzeSitupPosition(landmarks)
        case .pullup:
            return analyzePullupPosition(landmarks)
        default:
            return PositionScore(confidence: 0, isInPosition: false, feedback: createDefaultFeedback())
        }
    }
    
    private func analyzePushupPosition(_ landmarks: [NormalizedLandmark]) -> PositionScore {
        guard landmarks.count >= 33 else {
            return PositionScore(confidence: 0, isInPosition: false, feedback: createDefaultFeedback())
        }
        
        // Get key landmarks for pushup analysis
        let leftShoulder = landmarks[11]
        let rightShoulder = landmarks[12]
        let leftElbow = landmarks[13]
        let rightElbow = landmarks[14]
        let leftWrist = landmarks[15]
        let rightWrist = landmarks[16]
        let leftHip = landmarks[23]
        let rightHip = landmarks[24]
        
        // Calculate arm extension
        let leftArmAngle = calculateAngle(
            pointA: leftShoulder,
            pointB: leftElbow,
            pointC: leftWrist
        )
        let rightArmAngle = calculateAngle(
            pointA: rightShoulder,
            pointB: rightElbow,
            pointC: rightWrist
        )
        
        // Check if arms are extended (starting position)
        let armsExtended = leftArmAngle >= pushupThresholds.minArmExtension && rightArmAngle >= pushupThresholds.minArmExtension
        
        // Check body alignment
        let bodyAlignment = checkBodyAlignment(
            shoulders: [leftShoulder, rightShoulder],
            hips: [leftHip, rightHip]
        )
        
        // Check if hands are on ground (wrists below shoulders)
        let handsOnGround = leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y
        
        var missingRequirements: [String] = []
        if !armsExtended {
            missingRequirements.append("Extend your arms fully")
        }
        if !bodyAlignment {
            missingRequirements.append("Keep your body straight")
        }
        if !handsOnGround {
            missingRequirements.append("Place hands on the ground")
        }
        
        let isInPosition = armsExtended && bodyAlignment && handsOnGround
        let confidence = calculateConfidence(
            factors: [armsExtended, bodyAlignment, handsOnGround]
        )
        
        return PositionScore(
            confidence: confidence,
            isInPosition: isInPosition,
            feedback: PositioningFeedback(
                primaryInstruction: missingRequirements.first ?? "Hold position",
                visualGuide: FramingGuide(
                    isFullyInFrame: true,
                    tooClose: false,
                    tooFar: false,
                    optimalDistance: 1.0,
                    currentDistance: 1.0
                ),
                confidenceScore: confidence,
                missingRequirements: missingRequirements
            )
        )
    }
    
    private func analyzeSitupPosition(_ landmarks: [NormalizedLandmark]) -> PositionScore {
        guard landmarks.count >= 33 else {
            return PositionScore(confidence: 0, isInPosition: false, feedback: createDefaultFeedback())
        }
        
        // Get key landmarks for situp analysis
        let leftShoulder = landmarks[11]
        let rightShoulder = landmarks[12]
        let leftHip = landmarks[23]
        let rightHip = landmarks[24]
        let leftKnee = landmarks[25]
        let rightKnee = landmarks[26]
        
        // Check if person is lying down (shoulders near hip level)
        let shouldersNearGround = abs(leftShoulder.y - leftHip.y) < situpThresholds.maxShoulderHeight
        
        // Check knee bend
        let kneesAboveHips = leftKnee.y < leftHip.y && rightKnee.y < rightHip.y
        
        // Calculate hip angle to ensure proper starting position
        let hipAngle = calculateAngle(
            pointA: leftShoulder,
            pointB: leftHip,
            pointC: leftKnee
        )
        
        let properHipAngle = hipAngle >= situpThresholds.minHipAngle && hipAngle <= 180
        
        var missingRequirements: [String] = []
        if !shouldersNearGround {
            missingRequirements.append("Lie down on your back")
        }
        if !kneesAboveHips {
            missingRequirements.append("Bend your knees")
        }
        if !properHipAngle {
            missingRequirements.append("Adjust your position")
        }
        
        let isInPosition = shouldersNearGround && kneesAboveHips && properHipAngle
        let confidence = calculateConfidence(
            factors: [shouldersNearGround, kneesAboveHips, properHipAngle]
        )
        
        return PositionScore(
            confidence: confidence,
            isInPosition: isInPosition,
            feedback: PositioningFeedback(
                primaryInstruction: missingRequirements.first ?? "Hold position",
                visualGuide: FramingGuide(
                    isFullyInFrame: true,
                    tooClose: false,
                    tooFar: false,
                    optimalDistance: 1.0,
                    currentDistance: 1.0
                ),
                confidenceScore: confidence,
                missingRequirements: missingRequirements
            )
        )
    }
    
    private func analyzePullupPosition(_ landmarks: [NormalizedLandmark]) -> PositionScore {
        guard landmarks.count >= 33 else {
            return PositionScore(confidence: 0, isInPosition: false, feedback: createDefaultFeedback())
        }
        
        // Get key landmarks for pullup analysis
        let leftWrist = landmarks[15]
        let rightWrist = landmarks[16]
        let leftShoulder = landmarks[11]
        let rightShoulder = landmarks[12]
        let leftElbow = landmarks[13]
        let rightElbow = landmarks[14]
        
        // Check if hands are above head (dead hang position)
        let handsAboveHead = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y
        
        // Check arm extension for dead hang
        let leftArmAngle = calculateAngle(
            pointA: leftShoulder,
            pointB: leftElbow,
            pointC: leftWrist
        )
        let rightArmAngle = calculateAngle(
            pointA: rightShoulder,
            pointB: rightElbow,
            pointC: rightWrist
        )
        
        let armsExtended = leftArmAngle >= pullupThresholds.minArmExtension && rightArmAngle >= pullupThresholds.minArmExtension
        
        // Check body is hanging (feet likely off ground)
        let leftAnkle = landmarks[27]
        let rightAnkle = landmarks[28]
        let feetPosition = (leftAnkle.y + rightAnkle.y) / 2
        let bodyHanging = feetPosition > 0.7 // Lower portion of frame
        
        var missingRequirements: [String] = []
        if !handsAboveHead {
            missingRequirements.append("Grab the bar above your head")
        }
        if !armsExtended {
            missingRequirements.append("Extend your arms fully")
        }
        if !bodyHanging {
            missingRequirements.append("Hang from the bar")
        }
        
        let isInPosition = handsAboveHead && armsExtended && bodyHanging
        let confidence = calculateConfidence(
            factors: [handsAboveHead, armsExtended, bodyHanging]
        )
        
        return PositionScore(
            confidence: confidence,
            isInPosition: isInPosition,
            feedback: PositioningFeedback(
                primaryInstruction: missingRequirements.first ?? "Hold dead hang position",
                visualGuide: FramingGuide(
                    isFullyInFrame: true,
                    tooClose: false,
                    tooFar: false,
                    optimalDistance: 1.0,
                    currentDistance: 1.0
                ),
                confidenceScore: confidence,
                missingRequirements: missingRequirements
            )
        )
    }
    
    // MARK: - Helper Methods
    private func convertDetectedBodyToLandmarks(_ body: DetectedBody) -> [NormalizedLandmark] {
        // Convert DetectedBody points to MediaPipe NormalizedLandmark format
        var landmarks: [NormalizedLandmark] = []
        
        // MediaPipe BlazePose has 33 landmarks, initialize with default values
        for i in 0..<33 {
            landmarks.append(NormalizedLandmark(x: 0, y: 0, z: 0))
        }
        
        // Map known joint points to MediaPipe landmark indices
        let jointMapping: [(VNHumanBodyPoseObservation.JointName, Int)] = [
            (.nose, 0),
            (.leftEye, 1), (.rightEye, 2),
            (.leftEar, 3), (.rightEar, 4),
            (.leftShoulder, 11), (.rightShoulder, 12),
            (.leftElbow, 13), (.rightElbow, 14),
            (.leftWrist, 15), (.rightWrist, 16),
            (.leftHip, 23), (.rightHip, 24),
            (.leftKnee, 25), (.rightKnee, 26),
            (.leftAnkle, 27), (.rightAnkle, 28)
        ]
        
        // Fill in the landmarks from DetectedBody
        for (jointName, index) in jointMapping {
            if let point = body.point(jointName) {
                landmarks[index] = NormalizedLandmark(
                    x: Float(point.location.x),
                    y: Float(point.location.y),
                    z: 0 // DetectedBody doesn't provide z coordinate
                )
            }
        }
        
        return landmarks
    }
    
    private func analyzeBodyFraming(_ landmarks: [NormalizedLandmark]) -> FramingGuide {
        guard !landmarks.isEmpty else {
            return FramingGuide(
                isFullyInFrame: false,
                tooClose: false,
                tooFar: true,
                optimalDistance: 1.0,
                currentDistance: 0.0
            )
        }
        
        // Calculate bounding box of all landmarks
        let xCoordinates = landmarks.map { $0.x }
        let yCoordinates = landmarks.map { $0.y }
        
        guard let minX = xCoordinates.min(),
              let maxX = xCoordinates.max(),
              let minY = yCoordinates.min(),
              let maxY = yCoordinates.max() else {
            return FramingGuide(
                isFullyInFrame: false,
                tooClose: false,
                tooFar: true,
                optimalDistance: 1.0,
                currentDistance: 0.0
            )
        }
        
        let width = maxX - minX
        let height = maxY - minY
        
        // Check if all landmarks are within normalized bounds (0-1)
        let isFullyInFrame = minX > 0.05 && maxX < 0.95 && minY > 0.05 && maxY < 0.95
        
        // Determine if too close or too far
        let area = width * height
        let tooClose = area > 0.8
        let tooFar = area < 0.3
        
        let currentDistance = 1.0 / Double(area)
        let optimalDistance = 1.0 / 0.5 // Optimal area is 0.5
        
        return FramingGuide(
            isFullyInFrame: isFullyInFrame,
            tooClose: tooClose,
            tooFar: tooFar,
            optimalDistance: optimalDistance,
            currentDistance: currentDistance
        )
    }
    
    private func calculateAngle(pointA: NormalizedLandmark, pointB: NormalizedLandmark, pointC: NormalizedLandmark) -> Double {
        let radians = atan2(pointC.y - pointB.y, pointC.x - pointB.x) - atan2(pointA.y - pointB.y, pointA.x - pointB.x)
        var degrees = abs(Double(radians) * 180.0 / .pi)
        if degrees > 180.0 {
            degrees = 360.0 - degrees
        }
        return degrees
    }
    
    private func checkBodyAlignment(shoulders: [NormalizedLandmark], hips: [NormalizedLandmark]) -> Bool {
        let shoulderCenter = CGPoint(
            x: CGFloat((shoulders[0].x + shoulders[1].x) / 2),
            y: CGFloat((shoulders[0].y + shoulders[1].y) / 2)
        )
        let hipCenter = CGPoint(
            x: CGFloat((hips[0].x + hips[1].x) / 2),
            y: CGFloat((hips[0].y + hips[1].y) / 2)
        )
        
        // Check if shoulders and hips are reasonably aligned
        let horizontalAlignment = abs(shoulderCenter.x - hipCenter.x) < 0.1
        return horizontalAlignment
    }
    
    private func calculateConfidence(factors: [Bool]) -> Double {
        let trueCount = factors.filter { $0 }.count
        return Double(trueCount) / Double(factors.count)
    }
    
    private func createFramingFeedback(_ framing: FramingGuide) -> PositioningFeedback {
        var instruction = "Please position yourself in the camera frame"
        var requirements: [String] = []
        
        if !framing.isFullyInFrame {
            requirements.append("Move so your entire body is visible")
        }
        if framing.tooClose {
            instruction = "Step back from the camera"
            requirements.append("You're too close to the camera")
        } else if framing.tooFar {
            instruction = "Step closer to the camera"
            requirements.append("You're too far from the camera")
        }
        
        return PositioningFeedback(
            primaryInstruction: instruction,
            visualGuide: framing,
            confidenceScore: 0.0,
            missingRequirements: requirements
        )
    }
    
    private func createDefaultFeedback() -> PositioningFeedback {
        return PositioningFeedback(
            primaryInstruction: "Unable to detect body position",
            visualGuide: FramingGuide(
                isFullyInFrame: false,
                tooClose: false,
                tooFar: false,
                optimalDistance: 1.0,
                currentDistance: 0.0
            ),
            confidenceScore: 0.0,
            missingRequirements: ["Ensure you're visible in the camera"]
        )
    }
    

    
    // MARK: - State Management
    private func updateState(with result: PositionDetectionResult) {
        // Add to recent detections
        recentDetections.append(result)
        if recentDetections.count > maxRecentDetections {
            recentDetections.removeFirst()
        }
        
        // Update published properties
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentDetection = result
            self.detectedExercise = result.detectedExercise
            self.positionQuality = Float(result.confidence)
            self.primaryInstruction = result.feedback.primaryInstruction
            self.missingRequirements = result.feedback.missingRequirements
            self.confidenceScore = Float(result.confidence)
            
            // Handle position hold timing
            if result.isInPosition {
                if self.positionHoldStartTime == nil {
                    self.positionHoldStartTime = Date()
                }
                
                let holdDuration = Date().timeIntervalSince(self.positionHoldStartTime ?? Date())
                self.isInPosition = holdDuration >= self.requiredHoldDuration
            } else {
                self.positionHoldStartTime = nil
                self.isInPosition = false
            }
        }
    }
    
    // MARK: - Public Methods
    func reset() {
        recentDetections.removeAll()
        positionHoldStartTime = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.detectedExercise = nil
            self?.isInPosition = false
            self?.positionQuality = 0.0
            self?.primaryInstruction = "Get into starting position"
            self?.missingRequirements = []
            self?.confidenceScore = 0.0
        }
    }
    
    func getPositionHoldProgress() -> Float {
        guard let startTime = positionHoldStartTime else { return 0.0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, Float(elapsed / requiredHoldDuration))
    }
}

// MARK: - Supporting Types

struct PositionDetectionResult {
    let detectedExercise: ExerciseType?
    let isInPosition: Bool
    let feedback: PositioningFeedback
    let confidence: Double
}

struct PositioningFeedback {
    let primaryInstruction: String
    let visualGuide: FramingGuide
    let confidenceScore: Double
    let missingRequirements: [String]
}

struct FramingGuide {
    let isFullyInFrame: Bool
    let tooClose: Bool
    let tooFar: Bool
    let optimalDistance: Double
    let currentDistance: Double
}

struct PositionScore {
    let confidence: Double
    let isInPosition: Bool
    let feedback: PositioningFeedback
}

struct PushupThresholds {
    let minArmExtension: Double = 160.0
    let maxBodyAngle: Double = 20.0
}

struct SitupThresholds {
    let minHipAngle: Double = 150.0
    let maxShoulderHeight: Float = 0.15
}

struct PullupThresholds {
    let minArmExtension: Double = 160.0
    let minHandHeight: Double = 0.2
}

// MARK: - Exercise Type Extension
extension ExerciseType {
    var startingPositionDescription: String {
        switch self {
        case .pushup:
            return "High plank position with arms extended"
        case .situp:
            return "Lying on back with knees bent"
        case .pullup:
            return "Dead hang from bar with arms extended"
        default:
            return "Starting position for exercise"
        }
    }
}

// MARK: - Legacy Supporting Types (for backward compatibility)

struct ExercisePositionAnalysis {
    let isInStartingPosition: Bool
    let positionQuality: Float // 0-1
    let confidence: Float // 0-1
    let primaryFeedback: String
    let missingRequirements: [String]
    
    static func unknown() -> ExercisePositionAnalysis {
        return ExercisePositionAnalysis(
            isInStartingPosition: false,
            positionQuality: 0.0,
            confidence: 0.0,
            primaryFeedback: "Cannot detect position",
            missingRequirements: ["Body not detected"]
        )
    }
}

struct BodyFramingAnalysis {
    let isFullyInFrame: Bool
    let isAcceptable: Bool
    let tooClose: Bool
    let tooFar: Bool
    let needsMoveLeft: Bool
    let needsMoveRight: Bool
    let quality: Float // 0-1
    let optimalDistance: Float
}

// MARK: - Exercise-Specific Position Analyzers

class PushupPositionAnalyzer {
    func detectStartingPosition(body: DetectedBody) -> ExercisePositionAnalysis {
        // Leverage existing pushup logic for starting position detection
        guard let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow),
              let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist) else {
            return ExercisePositionAnalysis(
                isInStartingPosition: false,
                positionQuality: 0.0,
                confidence: 0.0,
                primaryFeedback: "Position hands and arms in frame",
                missingRequirements: ["Arms not visible"]
            )
        }
        
        // Calculate arm angles (existing logic)
        let leftArmAngle = calculateAngle(
            point1: leftShoulder.location,
            vertex: leftElbow.location,
            point3: leftWrist.location
        )
        let rightArmAngle = calculateAngle(
            point1: rightShoulder.location,
            vertex: rightElbow.location,
            point3: rightWrist.location
        )
        
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        let isArmsExtended = avgArmAngle >= 160.0 // Starting position threshold
        
        // Check body alignment (simplified)
        let confidence = min(leftElbow.confidence, rightElbow.confidence, 
                           leftShoulder.confidence, rightShoulder.confidence)
        
        var feedback = "Get into push-up starting position"
        var requirements: [String] = []
        
        if !isArmsExtended {
            feedback = "Extend your arms fully"
            requirements.append("Arms must be straight")
        } else {
            feedback = "Perfect push-up position!"
        }
        
        return ExercisePositionAnalysis(
            isInStartingPosition: isArmsExtended,
            positionQuality: isArmsExtended ? 1.0 : avgArmAngle / 160.0,
            confidence: confidence,
            primaryFeedback: feedback,
            missingRequirements: requirements
        )
    }
    
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let vector1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let vector2 = CGPoint(x: point3.x - vertex.x, y: point3.y - vertex.y)
        
        let dot = vector1.x * vector2.x + vector1.y * vector2.y
        let mag1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let mag2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCos) * 180.0 / .pi)
    }
}

class SitupPositionAnalyzer {
    func detectStartingPosition(body: DetectedBody) -> ExercisePositionAnalysis {
        // Leverage existing situp logic
        guard let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftHip = body.point(.leftHip),
              let rightHip = body.point(.rightHip),
              let leftKnee = body.point(.leftKnee),
              let rightKnee = body.point(.rightKnee) else {
            return ExercisePositionAnalysis(
                isInStartingPosition: false,
                positionQuality: 0.0,
                confidence: 0.0,
                primaryFeedback: "Lie down with knees bent",
                missingRequirements: ["Body position not detected"]
            )
        }
        
        // Check if lying down (shoulders lower than hips in camera view)
        let shoulderY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let hipY = (leftHip.location.y + rightHip.location.y) / 2
        let isLyingDown = shoulderY > hipY // In camera coordinates, higher Y = lower on screen
        
        // Check knee bend
        let leftKneeAngle = calculateKneeAngle(
            hip: leftHip.location,
            knee: leftKnee.location,
            ankle: body.point(.leftAnkle)?.location ?? CGPoint.zero
        )
        let rightKneeAngle = calculateKneeAngle(
            hip: rightHip.location,
            knee: rightKnee.location,
            ankle: body.point(.rightAnkle)?.location ?? CGPoint.zero
        )
        
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
        let isKneesBent = avgKneeAngle >= 80 && avgKneeAngle <= 100
        
        let confidence = min(leftShoulder.confidence, rightShoulder.confidence,
                           leftHip.confidence, rightHip.confidence)
        
        let isInPosition = isLyingDown && isKneesBent
        
        var feedback = "Get into sit-up starting position"
        var requirements: [String] = []
        
        if !isLyingDown {
            feedback = "Lie down on your back"
            requirements.append("Must be lying down")
        } else if !isKneesBent {
            feedback = "Bend your knees to 90 degrees"
            requirements.append("Knees must be bent")
        } else {
            feedback = "Perfect sit-up position!"
        }
        
        return ExercisePositionAnalysis(
            isInStartingPosition: isInPosition,
            positionQuality: isInPosition ? 1.0 : 0.5,
            confidence: confidence,
            primaryFeedback: feedback,
            missingRequirements: requirements
        )
    }
    
    private func calculateKneeAngle(hip: CGPoint, knee: CGPoint, ankle: CGPoint) -> Float {
        let vector1 = CGPoint(x: hip.x - knee.x, y: hip.y - knee.y)
        let vector2 = CGPoint(x: ankle.x - knee.x, y: ankle.y - knee.y)
        
        let dot = vector1.x * vector2.x + vector1.y * vector2.y
        let mag1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let mag2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 90 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCos) * 180.0 / .pi)
    }
}

class PullupPositionAnalyzer {
    func detectStartingPosition(body: DetectedBody) -> ExercisePositionAnalysis {
        // Leverage existing pullup logic
        guard let leftWrist = body.point(.leftWrist),
              let rightWrist = body.point(.rightWrist),
              let leftShoulder = body.point(.leftShoulder),
              let rightShoulder = body.point(.rightShoulder),
              let leftElbow = body.point(.leftElbow),
              let rightElbow = body.point(.rightElbow) else {
            return ExercisePositionAnalysis(
                isInStartingPosition: false,
                positionQuality: 0.0,
                confidence: 0.0,
                primaryFeedback: "Hang from pull-up bar",
                missingRequirements: ["Arms not detected"]
            )
        }
        
        // Check if arms are extended (dead hang)
        let leftArmAngle = calculateAngle(
            point1: leftShoulder.location,
            vertex: leftElbow.location,
            point3: leftWrist.location
        )
        let rightArmAngle = calculateAngle(
            point1: rightShoulder.location,
            vertex: rightElbow.location,
            point3: rightWrist.location
        )
        
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        let isDeadHang = avgArmAngle >= 160.0
        
        // Check if hands are above shoulders (hanging position)
        let handsAboveShoulders = leftWrist.location.y < leftShoulder.location.y &&
                                 rightWrist.location.y < rightShoulder.location.y
        
        let confidence = min(leftWrist.confidence, rightWrist.confidence,
                           leftShoulder.confidence, rightShoulder.confidence)
        
        let isInPosition = isDeadHang && handsAboveShoulders
        
        var feedback = "Get into pull-up starting position"
        var requirements: [String] = []
        
        if !handsAboveShoulders {
            feedback = "Grab the pull-up bar"
            requirements.append("Hands must be on bar")
        } else if !isDeadHang {
            feedback = "Hang with arms fully extended"
            requirements.append("Arms must be straight")
        } else {
            feedback = "Perfect pull-up position!"
        }
        
        return ExercisePositionAnalysis(
            isInStartingPosition: isInPosition,
            positionQuality: isInPosition ? 1.0 : avgArmAngle / 160.0,
            confidence: confidence,
            primaryFeedback: feedback,
            missingRequirements: requirements
        )
    }
    
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point3: CGPoint) -> Float {
        let vector1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let vector2 = CGPoint(x: point3.x - vertex.x, y: point3.y - vertex.y)
        
        let dot = vector1.x * vector2.x + vector1.y * vector2.y
        let mag1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let mag2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return Float(acos(clampedCos) * 180.0 / .pi)
    }
}

class BodyFramingAnalyzer {
    func analyzeBodyFraming(body: DetectedBody) -> BodyFramingAnalysis {
        // Calculate body boundaries
        let allPoints = body.allPoints
        guard !allPoints.isEmpty else {
            return BodyFramingAnalysis(
                isFullyInFrame: false,
                isAcceptable: false,
                tooClose: false,
                tooFar: true,
                needsMoveLeft: false,
                needsMoveRight: false,
                quality: 0.0,
                optimalDistance: 1.5
            )
        }
        
        let minX = allPoints.map(\.location.x).min() ?? 0
        let maxX = allPoints.map(\.location.x).max() ?? 1
        let minY = allPoints.map(\.location.y).min() ?? 0
        let maxY = allPoints.map(\.location.y).max() ?? 1
        
        let bodyWidth = maxX - minX
        let bodyHeight = maxY - minY
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        
        // Analyze framing
        let isFullyInFrame = minX >= 0.05 && maxX <= 0.95 && minY >= 0.05 && maxY <= 0.95
        let tooClose = bodyHeight > 0.9 || bodyWidth > 0.9
        let tooFar = bodyHeight < 0.3 || bodyWidth < 0.3
        let needsMoveLeft = centerX > 0.7
        let needsMoveRight = centerX < 0.3
        
        let isAcceptable = isFullyInFrame && !tooClose && !tooFar
        
        // Calculate quality score
        var quality: Float = 0.0
        if isFullyInFrame {
            quality += 0.4
        }
        if !tooClose && !tooFar {
            quality += 0.4
        }
        if abs(centerX - 0.5) < 0.2 {
            quality += 0.2
        }
        
        let optimalDistance: Float = tooClose ? 2.0 : (tooFar ? 1.0 : 1.5)
        
        return BodyFramingAnalysis(
            isFullyInFrame: isFullyInFrame,
            isAcceptable: isAcceptable,
            tooClose: tooClose,
            tooFar: tooFar,
            needsMoveLeft: needsMoveLeft,
            needsMoveRight: needsMoveRight,
            quality: quality,
            optimalDistance: optimalDistance
        )
    }
} 