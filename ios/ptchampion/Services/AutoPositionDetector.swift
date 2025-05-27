import Foundation
import Vision
import Combine

/// Automatic position detection service that leverages existing exercise analyzers
/// to detect when users are in correct starting positions without manual calibration
class AutoPositionDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedExercise: ExerciseType?
    @Published var isInPosition: Bool = false
    @Published var positionQuality: Float = 0.0 // 0-1 score
    @Published var primaryInstruction: String = "Get into starting position"
    @Published var missingRequirements: [String] = []
    @Published var confidenceScore: Float = 0.0
    
    // MARK: - Position Detection Result
    struct PositionDetectionResult {
        let detectedExercise: ExerciseType?
        let isInPosition: Bool
        let positionQuality: Float
        let feedback: PositioningFeedback
        let confidenceScore: Float
    }
    
    struct PositioningFeedback {
        let primaryInstruction: String
        let visualGuide: FramingGuide
        let confidenceScore: Float
        let missingRequirements: [String]
    }
    
    struct FramingGuide {
        let tooClose: Bool
        let tooFar: Bool
        let moveLeft: Bool
        let moveRight: Bool
        let bodyNotVisible: Bool
        let optimalDistance: Float
    }
    
    // MARK: - Dependencies
    private let pushupAnalyzer: PushupPositionAnalyzer
    private let situpAnalyzer: SitupPositionAnalyzer
    private let pullupAnalyzer: PullupPositionAnalyzer
    private let framingAnalyzer: BodyFramingAnalyzer
    
    // MARK: - State
    private var recentDetections: [PositionDetectionResult] = []
    private let maxRecentDetections = 10
    private var positionHoldStartTime: Date?
    private let requiredHoldDuration: TimeInterval = 2.0
    
    // MARK: - Initialization
    init() {
        self.pushupAnalyzer = PushupPositionAnalyzer()
        self.situpAnalyzer = SitupPositionAnalyzer()
        self.pullupAnalyzer = PullupPositionAnalyzer()
        self.framingAnalyzer = BodyFramingAnalyzer()
    }
    
    // MARK: - Main Detection Method
    func detectPosition(body: DetectedBody, expectedExercise: ExerciseType? = nil) -> PositionDetectionResult {
        // First check body framing
        let framingAnalysis = framingAnalyzer.analyzeBodyFraming(body: body)
        
        // If framing is poor, focus on that first
        if !framingAnalysis.isAcceptable {
            let feedback = createFramingFeedback(framingAnalysis)
            let result = PositionDetectionResult(
                detectedExercise: nil,
                isInPosition: false,
                positionQuality: 0.0,
                feedback: feedback,
                confidenceScore: 0.0
            )
            updateState(with: result)
            return result
        }
        
        // Analyze position for each exercise type
        let analyses = [
            (ExerciseType.pushup, pushupAnalyzer.detectStartingPosition(body: body)),
            (ExerciseType.situp, situpAnalyzer.detectStartingPosition(body: body)),
            (ExerciseType.pullup, pullupAnalyzer.detectStartingPosition(body: body))
        ]
        
        // Select most likely exercise or use expected
        let detectedExercise = expectedExercise ?? selectMostLikelyExercise(analyses)
        
        // Get position analysis for detected/expected exercise
        let positionAnalysis = getPositionAnalysis(for: detectedExercise, from: analyses)
        
        // Create feedback
        let feedback = createPositionFeedback(
            exercise: detectedExercise,
            analysis: positionAnalysis,
            framingAnalysis: framingAnalysis
        )
        
        let result = PositionDetectionResult(
            detectedExercise: detectedExercise,
            isInPosition: positionAnalysis.isInStartingPosition,
            positionQuality: positionAnalysis.positionQuality,
            feedback: feedback,
            confidenceScore: positionAnalysis.confidence
        )
        
        updateState(with: result)
        return result
    }
    
    // MARK: - Exercise Selection Logic
    private func selectMostLikelyExercise(_ analyses: [(ExerciseType, ExercisePositionAnalysis)]) -> ExerciseType? {
        let validAnalyses = analyses.filter { $0.1.confidence > 0.3 }
        
        guard !validAnalyses.isEmpty else { return nil }
        
        // Return exercise with highest confidence
        return validAnalyses.max(by: { $0.1.confidence < $1.1.confidence })?.0
    }
    
    private func getPositionAnalysis(for exercise: ExerciseType?, from analyses: [(ExerciseType, ExercisePositionAnalysis)]) -> ExercisePositionAnalysis {
        guard let exercise = exercise else {
            return ExercisePositionAnalysis.unknown()
        }
        
        return analyses.first { $0.0 == exercise }?.1 ?? ExercisePositionAnalysis.unknown()
    }
    
    // MARK: - Feedback Creation
    private func createFramingFeedback(_ framingAnalysis: BodyFramingAnalysis) -> PositioningFeedback {
        var instruction = "Position your body in frame"
        var requirements: [String] = []
        
        if framingAnalysis.tooClose {
            instruction = "Step back from camera"
            requirements.append("Move further from camera")
        } else if framingAnalysis.tooFar {
            instruction = "Move closer to camera"
            requirements.append("Move closer to camera")
        } else if !framingAnalysis.isFullyInFrame {
            instruction = "Center your body in frame"
            requirements.append("Full body must be visible")
        }
        
        let visualGuide = FramingGuide(
            tooClose: framingAnalysis.tooClose,
            tooFar: framingAnalysis.tooFar,
            moveLeft: framingAnalysis.needsMoveLeft,
            moveRight: framingAnalysis.needsMoveRight,
            bodyNotVisible: !framingAnalysis.isFullyInFrame,
            optimalDistance: framingAnalysis.optimalDistance
        )
        
        return PositioningFeedback(
            primaryInstruction: instruction,
            visualGuide: visualGuide,
            confidenceScore: framingAnalysis.quality,
            missingRequirements: requirements
        )
    }
    
    private func createPositionFeedback(
        exercise: ExerciseType?,
        analysis: ExercisePositionAnalysis,
        framingAnalysis: BodyFramingAnalysis
    ) -> PositioningFeedback {
        
        guard let exercise = exercise else {
            return PositioningFeedback(
                primaryInstruction: "Position yourself for exercise",
                visualGuide: FramingGuide(
                    tooClose: false, tooFar: false, moveLeft: false, 
                    moveRight: false, bodyNotVisible: true, optimalDistance: 1.5
                ),
                confidenceScore: 0.0,
                missingRequirements: ["Cannot detect exercise position"]
            )
        }
        
        var instruction = analysis.primaryFeedback
        var requirements = analysis.missingRequirements
        
        // Override with exercise-specific guidance if in position
        if analysis.isInStartingPosition {
            instruction = "Perfect! Hold this position"
        }
        
        let visualGuide = FramingGuide(
            tooClose: framingAnalysis.tooClose,
            tooFar: framingAnalysis.tooFar,
            moveLeft: framingAnalysis.needsMoveLeft,
            moveRight: framingAnalysis.needsMoveRight,
            bodyNotVisible: !framingAnalysis.isFullyInFrame,
            optimalDistance: framingAnalysis.optimalDistance
        )
        
        return PositioningFeedback(
            primaryInstruction: instruction,
            visualGuide: visualGuide,
            confidenceScore: analysis.confidence,
            missingRequirements: requirements
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
            
            self.detectedExercise = result.detectedExercise
            self.positionQuality = result.positionQuality
            self.primaryInstruction = result.feedback.primaryInstruction
            self.missingRequirements = result.feedback.missingRequirements
            self.confidenceScore = result.confidenceScore
            
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