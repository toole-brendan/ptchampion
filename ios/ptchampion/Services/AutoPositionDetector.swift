import Foundation
import Vision
import CoreGraphics

class AutoPositionDetector: ObservableObject {
    @Published var positionStatus: PositionStatus = .notDetected
    @Published var feedback: String = "Get into starting position"
    @Published var positionQuality: Float = 0.0
    @Published var isInCorrectPosition = false
    @Published var timeInCorrectPosition: TimeInterval = 0.0
    
    private var positionStartTime: Date?
    private let requiredHoldDuration: TimeInterval = 2.0
    
    enum PositionStatus {
        case notDetected
        case adjusting
        case correctPosition
        case holding
    }
    
    // MARK: - Analyze Position
    func analyzePosition(body: DetectedBody?, exerciseType: ExerciseType) {
        guard let body = body else {
            positionStatus = .notDetected
            feedback = "Position yourself in frame"
            positionQuality = 0.0
            resetHoldTimer()
            return
        }
        
        let analysis: PositionAnalysis
        
        switch exerciseType {
        case .pushup:
            analysis = analyzePushupPosition(body)
        case .situp:
            analysis = analyzeSitupPosition(body)
        case .pullup:
            analysis = analyzePullupPosition(body)
        default:
            analysis = PositionAnalysis(isCorrect: false, quality: 0.0, feedback: "Exercise not supported")
        }
        
        updatePositionState(analysis)
    }
    
    // MARK: - Push-up Position Analysis
    private func analyzePushupPosition(_ body: DetectedBody) -> PositionAnalysis {
        // Get required joints using 2D points, not 3D vectors
        guard let leftShoulder = body.point(.leftShoulder),
              let leftElbow = body.point(.leftElbow),
              let leftWrist = body.point(.leftWrist),
              let rightShoulder = body.point(.rightShoulder),
              let rightElbow = body.point(.rightElbow),
              let rightWrist = body.point(.rightWrist) else {
            return PositionAnalysis(isCorrect: false, quality: 0.0, feedback: "Can't see your arms clearly")
        }
        
        // Calculate elbow angles using 2D coordinates
        let leftElbowAngle = calculateAngle2D(
            pointA: leftShoulder.location,
            pointB: leftElbow.location,
            pointC: leftWrist.location
        )
        
        let rightElbowAngle = calculateAngle2D(
            pointA: rightShoulder.location,
            pointB: rightElbow.location,
            pointC: rightWrist.location
        )
        
        // Check if arms are extended (starting position)
        let targetAngle: CGFloat = 160.0
        let leftArmExtended = leftElbowAngle >= targetAngle
        let rightArmExtended = rightElbowAngle >= targetAngle
        
        var quality: Float = 0.0
        var feedback = ""
        
        if leftArmExtended && rightArmExtended {
            quality = 1.0
            feedback = "Perfect! Hold this position"
        } else {
            quality = Float(min(leftElbowAngle, rightElbowAngle) / targetAngle)
            feedback = "Extend your arms fully"
        }
        
        return PositionAnalysis(
            isCorrect: leftArmExtended && rightArmExtended,
            quality: quality,
            feedback: feedback
        )
    }
    
    // MARK: - Sit-up Position Analysis
    private func analyzeSitupPosition(_ body: DetectedBody) -> PositionAnalysis {
        guard let leftShoulder = body.point(.leftShoulder),
              let leftHip = body.point(.leftHip),
              let leftKnee = body.point(.leftKnee),
              let leftAnkle = body.point(.leftAnkle) else {
            return PositionAnalysis(isCorrect: false, quality: 0.0, feedback: "Position your full body in frame")
        }
        
        // Check if lying down (shoulders below hips)
        let isLyingDown = leftShoulder.location.y > leftHip.location.y
        
        // Check knee bend
        let kneeAngle = calculateAngle2D(
            pointA: leftHip.location,
            pointB: leftKnee.location,
            pointC: leftAnkle.location
        )
        
        let kneesBent = kneeAngle >= 80 && kneeAngle <= 100
        
        var quality: Float = 0.0
        var feedback = ""
        
        if isLyingDown && kneesBent {
            quality = 1.0
            feedback = "Perfect position! Hold steady"
        } else if !isLyingDown {
            quality = 0.3
            feedback = "Lie down on your back"
        } else if !kneesBent {
            quality = 0.7
            feedback = "Bend your knees to 90 degrees"
        }
        
        return PositionAnalysis(
            isCorrect: isLyingDown && kneesBent,
            quality: quality,
            feedback: feedback
        )
    }
    
    // MARK: - Pull-up Position Analysis
    private func analyzePullupPosition(_ body: DetectedBody) -> PositionAnalysis {
        guard let leftShoulder = body.point(.leftShoulder),
              let leftElbow = body.point(.leftElbow),
              let leftWrist = body.point(.leftWrist),
              let leftHip = body.point(.leftHip) else {
            return PositionAnalysis(isCorrect: false, quality: 0.0, feedback: "Position yourself in frame")
        }
        
        // Check if hands are above shoulders (hanging position)
        let handsAboveShoulders = leftWrist.location.y < leftShoulder.location.y
        
        // Check arm extension (dead hang)
        let armAngle = calculateAngle2D(
            pointA: leftShoulder.location,
            pointB: leftElbow.location,
            pointC: leftWrist.location
        )
        
        let armsExtended = armAngle >= 160
        
        var quality: Float = 0.0
        var feedback = ""
        
        if handsAboveShoulders && armsExtended {
            quality = 1.0
            feedback = "Perfect dead hang! Hold position"
        } else if !handsAboveShoulders {
            quality = 0.2
            feedback = "Grab the bar and hang"
        } else if !armsExtended {
            quality = 0.7
            feedback = "Extend your arms fully"
        }
        
        return PositionAnalysis(
            isCorrect: handsAboveShoulders && armsExtended,
            quality: quality,
            feedback: feedback
        )
    }
    
    // MARK: - Helper Methods
    private func calculateAngle2D(pointA: CGPoint, pointB: CGPoint, pointC: CGPoint) -> CGFloat {
        let vectorBA = CGPoint(x: pointA.x - pointB.x, y: pointA.y - pointB.y)
        let vectorBC = CGPoint(x: pointC.x - pointB.x, y: pointC.y - pointB.y)
        
        let dotProduct = vectorBA.x * vectorBC.x + vectorBA.y * vectorBC.y
        let magnitudeBA = sqrt(vectorBA.x * vectorBA.x + vectorBA.y * vectorBA.y)
        let magnitudeBC = sqrt(vectorBC.x * vectorBC.x + vectorBC.y * vectorBC.y)
        
        let cosineAngle = dotProduct / (magnitudeBA * magnitudeBC)
        let angleRadians = acos(max(-1, min(1, cosineAngle)))
        
        return angleRadians * 180 / .pi
    }
    
    private func updatePositionState(_ analysis: PositionAnalysis) {
        positionQuality = analysis.quality
        feedback = analysis.feedback
        isInCorrectPosition = analysis.isCorrect
        
        if analysis.isCorrect {
            if positionStartTime == nil {
                positionStartTime = Date()
            }
            
            timeInCorrectPosition = Date().timeIntervalSince(positionStartTime ?? Date())
            
            if timeInCorrectPosition >= requiredHoldDuration {
                positionStatus = .correctPosition
            } else {
                positionStatus = .holding
            }
        } else {
            resetHoldTimer()
            positionStatus = analysis.quality > 0.5 ? .adjusting : .notDetected
        }
    }
    
    private func resetHoldTimer() {
        positionStartTime = nil
        timeInCorrectPosition = 0.0
    }
    
    func reset() {
        positionStatus = .notDetected
        feedback = "Get into starting position"
        positionQuality = 0.0
        isInCorrectPosition = false
        resetHoldTimer()
    }
}

// MARK: - Supporting Types
struct PositionAnalysis {
    let isCorrect: Bool
    let quality: Float
    let feedback: String
} 