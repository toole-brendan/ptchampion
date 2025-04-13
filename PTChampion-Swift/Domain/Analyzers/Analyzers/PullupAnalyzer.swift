import Foundation
import MediaPipeTasksVision
import simd

class PullupAnalyzer: ExerciseAnalyzer {

    private var repCount: Int = 0
    private var currentState: ExerciseState = .idle
    private var feedback: [String] = []
    private var formScore: Double = 100.0
    private var minVisibility: Float = 0.5

    // Thresholds (adjust as needed)
    private let elbowAngleDownThreshold: Double = 150.0 // Min angle for elbows to be considered 'down' (extended)
    private let elbowAngleUpThreshold: Double = 70.0   // Max angle for elbows to be considered 'up' (flexed)
    private let chinAboveBarThresholdRatio: Float = 0.05 // Nose Y should be below shoulder Y by this ratio of shoulder height difference
    private let formDeductionExtension: Double = 5.0 // Points deducted for not extending fully
    private let formDeductionChin: Double = 5.0    // Points deducted for not getting chin high enough

    init() {}

    func analyze(poseLandmarkerResult: PoseLandmarkerResult, imageSize: CGSize) -> AnalysisResult {
        feedback = []
        guard let landmarks = poseLandmarkerResult.landmarks.first else {
            currentState = .invalid
            feedback.append("No person detected or landmarks unclear.")
            return AnalysisResult(repCount: repCount, feedback: feedback, state: currentState, confidence: 0.0, formScore: formScore)
        }

        let confidence = landmarks.compactMap { $0.visibility }.reduce(0, +) / Float(landmarks.count)

        // Key landmarks
        let leftShoulder = landmarks[PoseLandmark.leftShoulder.rawValue]
        let rightShoulder = landmarks[PoseLandmark.rightShoulder.rawValue]
        let leftElbow = landmarks[PoseLandmark.leftElbow.rawValue]
        let rightElbow = landmarks[PoseLandmark.rightElbow.rawValue]
        let leftWrist = landmarks[PoseLandmark.leftWrist.rawValue]
        let rightWrist = landmarks[PoseLandmark.rightWrist.rawValue]
        let nose = landmarks[PoseLandmark.nose.rawValue]

        // Calculate angles
        let leftElbowAngle = AngleCalculator.calculateAngle(leftShoulder, leftElbow, leftWrist, minVisibility: minVisibility)
        let rightElbowAngle = AngleCalculator.calculateAngle(rightShoulder, rightElbow, rightWrist, minVisibility: minVisibility)
        let elbowAngle = averageAngle(leftElbowAngle, rightElbowAngle)

        // --- Rep counting state machine --- 
        guard let currentElbowAngle = elbowAngle,
              let noseY = nose?.y,
              let lShoulderY = leftShoulder?.y,
              let rShoulderY = rightShoulder?.y,
              nose?.visibility ?? 0 >= minVisibility,
              leftShoulder?.visibility ?? 0 >= minVisibility,
              rightShoulder?.visibility ?? 0 >= minVisibility else {
            currentState = .invalid
            feedback.append("Cannot see key landmarks (elbows, shoulders, nose) clearly.")
            return AnalysisResult(repCount: repCount, feedback: feedback, state: currentState, confidence: confidence, formScore: formScore)
        }

        // Estimate shoulder Y midpoint and height difference for relative positioning
        let shoulderY = (lShoulderY + rShoulderY) / 2.0
        // Note: Y is often inverted in normalized coords (0 top, 1 bottom)
        let isChinAboveShoulders = noseY < shoulderY

        switch currentState {
        case .idle, .finished:
            // Need to be in the down position (arms extended) to start
            if currentElbowAngle > elbowAngleDownThreshold {
                currentState = .starting
            }
        case .starting:
            // Transition to UP when elbows bend significantly
            if currentElbowAngle < elbowAngleUpThreshold {
                currentState = .up
                // Check if arms were fully extended at the start of the rep
                if currentElbowAngle < elbowAngleDownThreshold {
                     feedback.append("Extend arms fully at the bottom!")
                     formScore = max(0, formScore - formDeductionExtension)
                 }
            }
        case .up:
            // Check if chin is high enough
            if !isChinAboveShoulders {
                 feedback.append("Pull higher! Chin over bar.")
                 // Small deduction while in 'up' state but not high enough
                 formScore = max(0, formScore - formDeductionChin * 0.1)
            }
            // Transition to DOWN when elbows start extending
            if currentElbowAngle > elbowAngleDownThreshold {
                currentState = .down
                // Evaluate form at the top of the rep
                if isChinAboveShoulders {
                    // Good height
                } else {
                    // Apply full deduction for not reaching height
                    formScore = max(0, formScore - formDeductionChin)
                    feedback.append("Chin didn't clear bar on last rep.")
                }
                repCount += 1
                feedback.append("Rep \(repCount) counted!")
            }
        case .down:
            // Check for full extension
            if currentElbowAngle < elbowAngleDownThreshold {
                 feedback.append("Extend arms fully!")
                 formScore = max(0, formScore - formDeductionExtension * 0.1) // Small deduction
            }
            // Transition back to UP if elbows bend again
            if currentElbowAngle < elbowAngleUpThreshold {
                currentState = .up
            }
        case .invalid:
            // Try to recover if landmarks become visible and extended
            if currentElbowAngle > elbowAngleDownThreshold {
                 currentState = .starting
            }
        }

        return AnalysisResult(repCount: repCount, feedback: feedback, state: currentState, confidence: confidence, formScore: formScore)
    }

    func reset() {
        repCount = 0
        currentState = .idle
        feedback = []
        formScore = 100.0
    }

    func start() {
        if currentState == .idle || currentState == .finished {
           reset()
        }
    }

    func stop() {
        currentState = .finished
    }
    
    // Helper to average angles, preferring a valid one if only one exists
    private func averageAngle(_ angle1: Double?, _ angle2: Double?) -> Double? {
        if let a1 = angle1, let a2 = angle2 {
            return (a1 + a2) / 2.0
        } else {
            return angle1 ?? angle2
        }
    }
} 