import Foundation
import Vision
import UIKit
import AVFoundation

// MARK: - Keypoint

struct Keypoint {
    let point: CGPoint
    let confidence: Float
    
    var isValid: Bool {
        return confidence > 0.3
    }
}

// MARK: - Pose

struct Pose {
    var keypoints: [VNHumanBodyPoseObservation.JointName: Keypoint]
    
    func angle(between joint1: VNHumanBodyPoseObservation.JointName, 
               joint2: VNHumanBodyPoseObservation.JointName, 
               joint3: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        
        guard let p1 = keypoints[joint1], p1.isValid,
              let p2 = keypoints[joint2], p2.isValid,
              let p3 = keypoints[joint3], p3.isValid else {
            return nil
        }
        
        let vector1 = CGVector(dx: p1.point.x - p2.point.x, dy: p1.point.y - p2.point.y)
        let vector2 = CGVector(dx: p3.point.x - p2.point.x, dy: p3.point.y - p2.point.y)
        
        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let cross = vector1.dx * vector2.dy - vector1.dy * vector2.dx
        
        let angle = atan2(cross, dot)
        let degrees = abs(angle * 180 / .pi)
        
        return degrees
    }
    
    func distance(between joint1: VNHumanBodyPoseObservation.JointName, 
                  and joint2: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        
        guard let p1 = keypoints[joint1], p1.isValid,
              let p2 = keypoints[joint2], p2.isValid else {
            return nil
        }
        
        let xDist = p2.point.x - p1.point.x
        let yDist = p2.point.y - p1.point.y
        
        return sqrt(xDist * xDist + yDist * yDist)
    }
    
    func keypoint(_ joint: VNHumanBodyPoseObservation.JointName) -> Keypoint? {
        return keypoints[joint]
    }
}

// MARK: - Exercise State

struct ExerciseState {
    var repetitionCount: Int = 0
    var isUp: Bool = false
    var isDown: Bool = false
    var formScore: Int = 0
    var feedback: String = ""
    var lastRepTime: Date?
    
    mutating func updateFormScore(newScore: Int) {
        // Accumulate form score throughout the exercise
        if formScore == 0 {
            formScore = newScore
        } else {
            formScore = (formScore + newScore) / 2
        }
    }
    
    mutating func recordRepetition() {
        repetitionCount += 1
        lastRepTime = Date()
    }
}

// MARK: - Pose Detection Service

class PoseDetectionService {
    
    // MARK: - Properties
    
    private let poseDetector: VNDetectHumanBodyPoseRequest
    private(set) var pushupState = ExerciseState()
    private(set) var situpState = ExerciseState()
    private(set) var pullupState = ExerciseState()
    
    // MARK: - Initialization
    
    init() {
        poseDetector = VNDetectHumanBodyPoseRequest()
        
        // Reset all exercise states
        resetExerciseStates()
    }
    
    // MARK: - Public Methods
    
    func resetExerciseStates() {
        pushupState = ExerciseState()
        situpState = ExerciseState()
        pullupState = ExerciseState()
    }
    
    func detectPose(in image: UIImage, completion: @escaping (Pose?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try requestHandler.perform([poseDetector])
            
            guard let observation = poseDetector.results?.first as? VNHumanBodyPoseObservation else {
                completion(nil)
                return
            }
            
            let pose = processObservation(observation)
            completion(pose)
        } catch {
            print("Error detecting pose: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, completion: @escaping (Pose?) -> Void) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation)
        
        do {
            try requestHandler.perform([poseDetector])
            
            guard let observation = poseDetector.results?.first as? VNHumanBodyPoseObservation else {
                completion(nil)
                return
            }
            
            let pose = processObservation(observation)
            completion(pose)
        } catch {
            print("Error detecting pose in frame: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // MARK: - Exercise Detection
    
    func detectPushup(pose: Pose) -> ExerciseState {
        var state = pushupState
        
        // Check if we have all required joints for pushup detection
        guard let leftElbowAngle = pose.angle(between: .leftShoulder, joint2: .leftElbow, joint3: .leftWrist),
              let rightElbowAngle = pose.angle(between: .rightShoulder, joint2: .rightElbow, joint3: .rightWrist),
              let leftShoulderAngle = pose.angle(between: .leftElbow, joint2: .leftShoulder, joint3: .leftHip),
              let rightShoulderAngle = pose.angle(between: .rightElbow, joint2: .rightShoulder, joint3: .rightHip) else {
            state.feedback = "Position not detected. Make sure your full body is visible."
            return state
        }
        
        // Average angles from both sides
        let elbowAngle = (leftElbowAngle + rightElbowAngle) / 2
        let shoulderAngle = (leftShoulderAngle + rightShoulderAngle) / 2
        
        // Detect up position (arms extended)
        let isUpPosition = elbowAngle > 150
        
        // Detect down position (arms bent)
        let isDownPosition = elbowAngle < 90
        
        // Check form
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check if body is straight
        if shoulderAngle < 160 {
            formFeedback += "Keep your body straight. "
            formScoreValue -= 20
        }
        
        // Check if elbows are too wide
        if let leftElbowDistance = pose.distance(between: .leftElbow, and: .leftShoulder),
           let rightElbowDistance = pose.distance(between: .rightElbow, and: .rightShoulder),
           let shoulderDistance = pose.distance(between: .leftShoulder, and: .rightShoulder) {
            
            let avgElbowDistance = (leftElbowDistance + rightElbowDistance) / 2
            if avgElbowDistance > shoulderDistance * 1.5 {
                formFeedback += "Keep elbows closer to body. "
                formScoreValue -= 15
            }
        }
        
        // Count repetitions
        if isUpPosition && !state.isUp && state.isDown {
            // Transition from down to up position - count a rep
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set feedback
        if formFeedback.isEmpty {
            if isUpPosition {
                state.feedback = "Good form! Lower your body."
            } else if isDownPosition {
                state.feedback = "Good form! Push up."
            } else {
                state.feedback = "Continue the movement."
            }
        } else {
            state.feedback = formFeedback
        }
        
        pushupState = state
        return state
    }
    
    func detectSitup(pose: Pose) -> ExerciseState {
        var state = situpState
        
        // Check if we have all required joints for situp detection
        guard let kneeAngle = pose.angle(between: .hip, joint2: .knee, joint3: .ankle),
              let hipAngle = pose.angle(between: .shoulder, joint2: .hip, joint3: .knee) else {
            state.feedback = "Position not detected. Make sure your full body is visible."
            return state
        }
        
        // Detect up position (torso upright)
        let isUpPosition = hipAngle > 80
        
        // Detect down position (torso reclined)
        let isDownPosition = hipAngle < 40
        
        // Check form
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check if knees are bent properly
        if kneeAngle > 120 {
            formFeedback += "Bend your knees more. "
            formScoreValue -= 15
        }
        
        // Count repetitions
        if isUpPosition && !state.isUp && state.isDown {
            // Transition from down to up position - count a rep
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set feedback
        if formFeedback.isEmpty {
            if isUpPosition {
                state.feedback = "Good form! Lower your torso."
            } else if isDownPosition {
                state.feedback = "Good form! Lift your torso."
            } else {
                state.feedback = "Continue the movement."
            }
        } else {
            state.feedback = formFeedback
        }
        
        situpState = state
        return state
    }
    
    func detectPullup(pose: Pose) -> ExerciseState {
        var state = pullupState
        
        // Check if we have all required joints for pullup detection
        guard let leftElbowAngle = pose.angle(between: .leftShoulder, joint2: .leftElbow, joint3: .leftWrist),
              let rightElbowAngle = pose.angle(between: .rightShoulder, joint2: .rightElbow, joint3: .rightWrist) else {
            state.feedback = "Position not detected. Make sure your upper body is visible."
            return state
        }
        
        // Average elbow angle from both sides
        let elbowAngle = (leftElbowAngle + rightElbowAngle) / 2
        
        // Detect up position (chin over bar, arms bent)
        let isUpPosition = elbowAngle < 90
        
        // Detect down position (arms extended)
        let isDownPosition = elbowAngle > 150
        
        // Check form
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check chin position relative to hands (wrists)
        if let leftWrist = pose.keypoint(.leftWrist),
           let rightWrist = pose.keypoint(.rightWrist),
           let chin = pose.keypoint(.neck) {
            
            let avgWristY = (leftWrist.point.y + rightWrist.point.y) / 2
            
            // In up position, chin should be near or above hands
            if isUpPosition && chin.point.y < avgWristY - 0.05 {
                formFeedback += "Pull up until chin is over the bar. "
                formScoreValue -= 20
            }
        }
        
        // Count repetitions
        if isUpPosition && !state.isUp && state.isDown {
            // Transition from down to up position - count a rep
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set feedback
        if formFeedback.isEmpty {
            if isUpPosition {
                state.feedback = "Good form! Lower your body."
            } else if isDownPosition {
                state.feedback = "Good form! Pull up."
            } else {
                state.feedback = "Continue the movement."
            }
        } else {
            state.feedback = formFeedback
        }
        
        pullupState = state
        return state
    }
    
    // MARK: - Private Methods
    
    private func processObservation(_ observation: VNHumanBodyPoseObservation) -> Pose {
        var keypoints = [VNHumanBodyPoseObservation.JointName: Keypoint]()
        
        for jointName in VNHumanBodyPoseObservation.JointName.allCases {
            do {
                let jointPoint = try observation.recognizedPoint(jointName)
                
                // Convert to screen coordinates (VN coordinates are normalized 0-1)
                let keypoint = Keypoint(
                    point: CGPoint(x: jointPoint.x, y: 1 - jointPoint.y), // Invert y because Vision's coordinate system is flipped
                    confidence: jointPoint.confidence
                )
                
                keypoints[jointName] = keypoint
            } catch {
                continue
            }
        }
        
        return Pose(keypoints: keypoints)
    }
    
    func drawPoseOverlay(on image: UIImage, pose: Pose) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw original image
        image.draw(at: .zero)
        
        // Define connections between joints
        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .neck),
            (.leftShoulder, .neck),
            (.rightShoulder, .neck),
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            (.leftShoulder, .leftHip),
            (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
        
        // Draw connections
        context.setLineWidth(5.0)
        context.setStrokeColor(UIColor.green.cgColor)
        
        for (joint1, joint2) in connections {
            guard let point1 = pose.keypoints[joint1], point1.isValid,
                  let point2 = pose.keypoints[joint2], point2.isValid else {
                continue
            }
            
            // Convert normalized coordinates to image coordinates
            let p1 = CGPoint(x: point1.point.x * image.size.width, y: point1.point.y * image.size.height)
            let p2 = CGPoint(x: point2.point.x * image.size.width, y: point2.point.y * image.size.height)
            
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()
        }
        
        // Draw keypoints
        for (_, keypoint) in pose.keypoints {
            if keypoint.isValid {
                let center = CGPoint(
                    x: keypoint.point.x * image.size.width,
                    y: keypoint.point.y * image.size.height
                )
                
                context.setFillColor(UIColor.red.cgColor)
                context.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
            }
        }
        
        // Get resulting image
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}

// Extension to use with camera feed
extension PoseDetectionService {
    func setupCameraSession() -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return session
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        return session
    }
}

// Extension for VNHumanBodyPoseObservation.JointName to make it CaseIterable
extension VNHumanBodyPoseObservation.JointName: CaseIterable {
    public static var allCases: [VNHumanBodyPoseObservation.JointName] {
        return [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .neck,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
    }
}