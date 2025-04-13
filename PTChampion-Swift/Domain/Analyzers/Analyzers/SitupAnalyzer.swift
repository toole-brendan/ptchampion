import Foundation
import MediaPipeTasksVision
import simd

class SitupAnalyzer: ExerciseAnalyzer {

    private var repCount: Int = 0
    private var currentState: ExerciseState = .idle
    private var feedback: [String] = []
    private var formScore: Double = 100.0
    private var minVisibility: Float = 0.5

    // Thresholds (adjust as needed)
    private let torsoAngleDownThreshold: Double = 140.0 // Min angle for torso to be considered 'down' (lying back)
    private let torsoAngleUpThreshold: Double = 80.0   // Max angle for torso to be considered 'up' 
    private let formDeductionRange: Double = 5.0     // Points deducted for insufficient range of motion

    init() {}

    func analyze(poseLandmarkerResult: PoseLandmarkerResult, imageSize: CGSize) -> AnalysisResult {
        feedback = []
        guard let landmarks = poseLandmarkerResult.landmarks.first else {
            currentState = .invalid
            feedback.append("No person detected or landmarks unclear.")
            return AnalysisResult(repCount: repCount, feedback: feedback, state: currentState, confidence: 0.0, formScore: formScore)
        }

        let confidence = landmarks.compactMap { $0.visibility }.reduce(0, +) / Float(landmarks.count)

        // Key landmarks for torso angle (Shoulder-Hip-Knee)
        let leftShoulder = landmarks[PoseLandmark.leftShoulder.rawValue]
        let rightShoulder = landmarks[PoseLandmark.rightShoulder.rawValue]
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let rightHip = landmarks[PoseLandmark.rightHip.rawValue]
        let leftKnee = landmarks[PoseLandmark.leftKnee.rawValue]
        let rightKnee = landmarks[PoseLandmark.rightKnee.rawValue]

        // Calculate torso angles (using the hip as the vertex)
        let leftTorsoAngle = AngleCalculator.calculateAngle(leftShoulder, leftHip, leftKnee, minVisibility: minVisibility)
        let rightTorsoAngle = AngleCalculator.calculateAngle(rightShoulder, rightHip, rightKnee, minVisibility: minVisibility)
        let torsoAngle = averageAngle(leftTorsoAngle, rightTorsoAngle)

        // --- Rep counting state machine --- 
        guard let currentTorsoAngle = torsoAngle else {
            currentState = .invalid
            feedback.append("Cannot see key landmarks (shoulders, hips, knees) clearly.")
            return AnalysisResult(repCount: repCount, feedback: feedback, state: currentState, confidence: confidence, formScore: formScore)
        }

        switch currentState {
        case .idle, .finished:
            // Need to be in the down position to start
            if currentTorsoAngle > torsoAngleDownThreshold {
                currentState = .starting
            }
        case .starting:
            // Transition to UP when torso angle decreases (sitting up)
            if currentTorsoAngle < torsoAngleUpThreshold {
                currentState = .up
                // Check if fully down at the start
                if currentTorsoAngle < torsoAngleDownThreshold {
                     feedback.append("Lie further back!")
                     formScore = max(0, formScore - formDeductionRange)
                 }
            }
        case .up:
            // Check if sitting up enough
            if currentTorsoAngle > torsoAngleUpThreshold {
                 feedback.append("Sit up higher!")
                 formScore = max(0, formScore - formDeductionRange * 0.1) // Small deduction
            }
            // Transition to DOWN when torso angle increases (lying back)
            if currentTorsoAngle > torsoAngleDownThreshold {
                currentState = .down
                // Evaluate form at the top
                if currentTorsoAngle <= torsoAngleUpThreshold {
                    // Good range
                } else {
                    formScore = max(0, formScore - formDeductionRange)
                    feedback.append("Didn't sit up fully on last rep.")
                }
                repCount += 1
                feedback.append("Rep \(repCount) counted!")
            }
        case .down:
             // Check if lying back enough
             if currentTorsoAngle < torsoAngleDownThreshold {
                 feedback.append("Lie further back!")
                 formScore = max(0, formScore - formDeductionRange * 0.1) // Small deduction
            }
            // Transition back to UP if sitting up again
            if currentTorsoAngle < torsoAngleUpThreshold {
                currentState = .up
            }
        case .invalid:
            // Try to recover if landmarks become visible and down
            if currentTorsoAngle > torsoAngleDownThreshold {
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
    
    // Helper to average angles
    private func averageAngle(_ angle1: Double?, _ angle2: Double?) -> Double? {
        if let a1 = angle1, let a2 = angle2 {
            return (a1 + a2) / 2.0
        } else {
            return angle1 ?? angle2
        }
    }
} 