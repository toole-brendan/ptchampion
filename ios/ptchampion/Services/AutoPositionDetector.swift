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
    private let requiredHoldDuration: TimeInterval = 1.5
    
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
    
    // MARK: - Push-up Position Analysis (More Forgiving)
    private func analyzePushupPosition(_ body: DetectedBody) -> PositionAnalysis {
        // Check basic visibility first - more forgiving
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist
        ]
        
        var visibleJoints = 0
        for joint in keyJoints {
            if let point = body.point(joint), point.confidence > 0.4 { // Lowered from implicit higher threshold
                visibleJoints += 1
            }
        }
        
        // If we can't see enough joints, give helpful feedback
        if visibleJoints < 4 { // Only need 4 out of 6 key joints
            return PositionAnalysis(
                isCorrect: false,
                quality: Float(visibleJoints) / 6.0,
                feedback: "Move into full view of camera"
            )
        }
        
        // Get available joints for angle calculation
        let leftShoulder = body.point(.leftShoulder)
        let leftElbow = body.point(.leftElbow)
        let leftWrist = body.point(.leftWrist)
        let rightShoulder = body.point(.rightShoulder)
        let rightElbow = body.point(.rightElbow)
        let rightWrist = body.point(.rightWrist)
        
        // Calculate angles if we have enough data (use available side)
        var hasGoodPosition = false
        var quality: Float = 0.5 // Start with base quality for being visible
        var feedback = "Get into push-up position"
        
        // Check left side if available
        if let ls = leftShoulder, let le = leftElbow, let lw = leftWrist {
            let leftElbowAngle = calculateAngle2D(
                pointA: ls.location,
                pointB: le.location,
                pointC: lw.location
            )
            
            // Much more forgiving angle requirements
            let targetAngle: CGFloat = 140.0 // Reduced from 160.0
            let tolerance: CGFloat = 30.0 // Increased tolerance
            
            if leftElbowAngle >= targetAngle - tolerance {
                hasGoodPosition = true
                quality = Float(min(1.0, leftElbowAngle / targetAngle))
                feedback = quality > 0.8 ? "Great! Hold position" : "Almost there!"
            } else {
                quality = Float(max(0.3, leftElbowAngle / targetAngle))
                feedback = "Extend your arms a bit more"
            }
        }
        
        // Check right side if left wasn't good enough
        if !hasGoodPosition, let rs = rightShoulder, let re = rightElbow, let rw = rightWrist {
            let rightElbowAngle = calculateAngle2D(
                pointA: rs.location,
                pointB: re.location,
                pointC: rw.location
            )
            
            let targetAngle: CGFloat = 140.0
            let tolerance: CGFloat = 30.0
            
            if rightElbowAngle >= targetAngle - tolerance {
                hasGoodPosition = true
                quality = Float(min(1.0, rightElbowAngle / targetAngle))
                feedback = quality > 0.8 ? "Great! Hold position" : "Almost there!"
            }
        }
        
        // Accept position if quality is above 60%
        return PositionAnalysis(
            isCorrect: quality >= 0.6, // Reduced from implicit higher threshold
            quality: quality,
            feedback: feedback
        )
    }
    
    // MARK: - Sit-up Position Analysis (More Forgiving)
    private func analyzeSitupPosition(_ body: DetectedBody) -> PositionAnalysis {
        // Basic visibility check
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .leftHip, .leftKnee
        ]
        
        var visibleJoints = 0
        for joint in keyJoints {
            if let point = body.point(joint), point.confidence > 0.4 {
                visibleJoints += 1
            }
        }
        
        if visibleJoints < 2 { // Only need 2 out of 3
            return PositionAnalysis(
                isCorrect: false,
                quality: Float(visibleJoints) / 3.0,
                feedback: "Position your full body in frame"
            )
        }
        
        let leftShoulder = body.point(.leftShoulder)
        let leftHip = body.point(.leftHip)
        let leftKnee = body.point(.leftKnee)
        let leftAnkle = body.point(.leftAnkle)
        
        var quality: Float = 0.5
        var feedback = "Lie on your back with knees bent"
        var isCorrect = false
        
        // Check if roughly lying down (shoulders should be somewhat below or level with hips)
        if let shoulder = leftShoulder, let hip = leftHip {
            let isLyingDown = shoulder.location.y >= hip.location.y - 0.1 // More forgiving
            
            if isLyingDown {
                quality = 0.7
                feedback = "Good position!"
                isCorrect = true
                
                // Check knee bend if possible (optional enhancement)
                if let knee = leftKnee, let ankle = leftAnkle {
                    let kneeAngle = calculateAngle2D(
                        pointA: hip.location,
                        pointB: knee.location,
                        pointC: ankle.location
                    )
                    
                    // Very forgiving knee angle range
                    if kneeAngle >= 60 && kneeAngle <= 120 {
                        quality = 0.9
                        feedback = "Perfect! Hold position"
                    } else {
                        quality = 0.75
                        feedback = "Good! Adjust knees if comfortable"
                    }
                }
            } else {
                quality = 0.4
                feedback = "Lie down on your back"
                isCorrect = false
            }
        }
        
        // Accept position if quality is above 60%
        return PositionAnalysis(
            isCorrect: quality >= 0.6,
            quality: quality,
            feedback: feedback
        )
    }
    
    // MARK: - Pull-up Position Analysis (More Forgiving)
    private func analyzePullupPosition(_ body: DetectedBody) -> PositionAnalysis {
        // Basic visibility check for upper body
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .leftElbow, .leftWrist
        ]
        
        var visibleJoints = 0
        for joint in keyJoints {
            if let point = body.point(joint), point.confidence > 0.4 {
                visibleJoints += 1
            }
        }
        
        if visibleJoints < 2 {
            return PositionAnalysis(
                isCorrect: false,
                quality: Float(visibleJoints) / 3.0,
                feedback: "Position yourself in frame"
            )
        }
        
        let leftShoulder = body.point(.leftShoulder)
        let leftElbow = body.point(.leftElbow)
        let leftWrist = body.point(.leftWrist)
        
        var quality: Float = 0.5
        var feedback = "Hang from the bar"
        var isCorrect = false
        
        // Check if hands are roughly above shoulders (hanging position)
        if let shoulder = leftShoulder, let wrist = leftWrist {
            let handsAboveShoulders = wrist.location.y <= shoulder.location.y + 0.1 // More forgiving
            
            if handsAboveShoulders {
                quality = 0.7
                feedback = "Good hang position!"
                isCorrect = true
                
                // Check arm extension if elbow is visible (optional)
                if let elbow = leftElbow {
                    let armAngle = calculateAngle2D(
                        pointA: shoulder.location,
                        pointB: elbow.location,
                        pointC: wrist.location
                    )
                    
                    // More forgiving arm extension
                    if armAngle >= 140 { // Reduced from 160
                        quality = 0.9
                        feedback = "Perfect dead hang!"
                    } else if armAngle >= 120 {
                        quality = 0.75
                        feedback = "Good! Extend arms if comfortable"
                    }
                }
            } else {
                quality = 0.3
                feedback = "Grab the bar above you"
                isCorrect = false
            }
        }
        
        // Accept position if quality is above 60%
        return PositionAnalysis(
            isCorrect: quality >= 0.6,
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