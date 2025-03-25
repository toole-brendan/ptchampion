import Foundation
import Vision
import UIKit
import Combine

// MARK: - Pose Types

struct Keypoint {
    let position: CGPoint
    let part: String
    let confidence: Float
    
    init(point: CGPoint, type: String, confidence: Float) {
        self.position = point
        self.part = type
        self.confidence = confidence
    }
}

struct PoseLine {
    let from: Keypoint
    let to: Keypoint
}

// Exercise state models that match the web version
struct PushupState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 80
    var feedback: String = "Position yourself for push-ups"
}

struct PullupState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 80
    var feedback: String = "Position yourself for pull-ups"
}

struct SitupState {
    var isUp: Bool = false
    var isDown: Bool = false
    var count: Int = 0
    var formScore: Int = 80
    var feedback: String = "Position yourself for sit-ups"
}

// MARK: - Pose Detection Service

class PoseDetectionService: ObservableObject {
    // Constants
    static let MIN_CONFIDENCE: Float = 0.3
    
    // Body part indices
    enum BodyPart: Int, CaseIterable {
        case nose = 0
        case leftEye
        case rightEye
        case leftEar
        case rightEar
        case leftShoulder
        case rightShoulder
        case leftElbow
        case rightElbow
        case leftWrist
        case rightWrist
        case leftHip
        case rightHip
        case leftKnee
        case rightKnee
        case leftAnkle
        case rightAnkle
        
        var name: String {
            switch self {
            case .nose: return "nose"
            case .leftEye: return "leftEye"
            case .rightEye: return "rightEye"
            case .leftEar: return "leftEar"
            case .rightEar: return "rightEar"
            case .leftShoulder: return "leftShoulder"
            case .rightShoulder: return "rightShoulder"
            case .leftElbow: return "leftElbow"
            case .rightElbow: return "rightElbow"
            case .leftWrist: return "leftWrist"
            case .rightWrist: return "rightWrist"
            case .leftHip: return "leftHip"
            case .rightHip: return "rightHip"
            case .leftKnee: return "leftKnee"
            case .rightKnee: return "rightKnee"
            case .leftAnkle: return "leftAnkle"
            case .rightAnkle: return "rightAnkle"
            }
        }
    }
    
    // Published properties
    @Published var pushupState = PushupState()
    @Published var pullupState = PullupState()
    @Published var situpState = SitupState()
    @Published var keypoints: [Keypoint] = []
    @Published var poseLines: [PoseLine] = []
    
    // VNRequest for human body pose detection
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    
    // Initialize the pose detection service
    init() {
        poseRequest = VNDetectHumanBodyPoseRequest()
    }
    
    // Process a frame from the camera to detect poses
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([poseRequest!])
            
            if let observations = poseRequest?.results, !observations.isEmpty {
                // Process the first detected person
                if let observation = observations.first {
                    processObservation(observation, frameSize: CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)))
                }
            }
        } catch {
            print("Failed to perform pose detection: \(error.localizedDescription)")
        }
    }
    
    // Process a VNHumanBodyPoseObservation and extract keypoints
    private func processObservation(_ observation: VNHumanBodyPoseObservation, frameSize: CGSize) {
        // Extract all available joints
        var detectedKeypoints: [Keypoint] = []
        
        for bodyPart in BodyPart.allCases {
            guard let jointPoint = try? observation.recognizedPoint(VNHumanBodyPoseObservation.JointName(rawValue: bodyPart.name)) else {
                continue
            }
            
            // Filter out low confidence points
            guard jointPoint.confidence > PoseDetectionService.MIN_CONFIDENCE else {
                continue
            }
            
            // Convert normalized point to frame coordinates
            let framePoint = CGPoint(
                x: jointPoint.x * frameSize.width,
                y: (1 - jointPoint.y) * frameSize.height // Flip Y to match UIKit coordinate system
            )
            
            detectedKeypoints.append(Keypoint(
                point: framePoint,
                type: bodyPart.name,
                confidence: jointPoint.confidence
            ))
        }
        
        // Update keypoints
        DispatchQueue.main.async { [weak self] in
            self?.keypoints = detectedKeypoints
            self?.poseLines = self?.calculatePoseLines(detectedKeypoints) ?? []
            
            // Apply exercise detection based on keypoints
            if let self = self {
                // Update exercise states
                self.pushupState = self.detectPushup(keypoints: detectedKeypoints, prevState: self.pushupState)
                self.pullupState = self.detectPullup(keypoints: detectedKeypoints, prevState: self.pullupState)
                self.situpState = self.detectSitup(keypoints: detectedKeypoints, prevState: self.situpState)
            }
        }
    }
    
    // MARK: - Pose Analysis Utilities
    
    // Calculate angle between three points
    private func calculateAngle(a: Keypoint, b: Keypoint, c: Keypoint) -> Double {
        let angleRadians = atan2(
            c.position.y - b.position.y,
            c.position.x - b.position.x
        ) - atan2(
            a.position.y - b.position.y,
            a.position.x - b.position.x
        )
        
        var angleDegrees = angleRadians * (180 / Double.pi)
        if angleDegrees < 0 {
            angleDegrees += 360
        }
        
        return angleDegrees
    }
    
    // Get distance between two points
    private func getDistance(p1: Keypoint, p2: Keypoint) -> Double {
        return sqrt(
            pow(p2.position.x - p1.position.x, 2) +
            pow(p2.position.y - p1.position.y, 2)
        )
    }
    
    // Calculate lines to draw between keypoints
    private func calculatePoseLines(_ keypoints: [Keypoint]) -> [PoseLine] {
        // Create a dictionary for easy lookup
        var keypointDict: [String: Keypoint] = [:]
        for keypoint in keypoints {
            keypointDict[keypoint.part] = keypoint
        }
        
        // Define the connections we want to draw
        let connections: [(String, String)] = [
            // Head connections
            (BodyPart.leftEar.name, BodyPart.leftEye.name),
            (BodyPart.leftEye.name, BodyPart.nose.name),
            (BodyPart.nose.name, BodyPart.rightEye.name),
            (BodyPart.rightEye.name, BodyPart.rightEar.name),
            
            // Torso connections
            (BodyPart.leftShoulder.name, BodyPart.rightShoulder.name),
            (BodyPart.leftShoulder.name, BodyPart.leftHip.name),
            (BodyPart.rightShoulder.name, BodyPart.rightHip.name),
            (BodyPart.leftHip.name, BodyPart.rightHip.name),
            
            // Arms connections
            (BodyPart.leftShoulder.name, BodyPart.leftElbow.name),
            (BodyPart.leftElbow.name, BodyPart.leftWrist.name),
            (BodyPart.rightShoulder.name, BodyPart.rightElbow.name),
            (BodyPart.rightElbow.name, BodyPart.rightWrist.name),
            
            // Legs connections
            (BodyPart.leftHip.name, BodyPart.leftKnee.name),
            (BodyPart.leftKnee.name, BodyPart.leftAnkle.name),
            (BodyPart.rightHip.name, BodyPart.rightKnee.name),
            (BodyPart.rightKnee.name, BodyPart.rightAnkle.name),
        ]
        
        var lines: [PoseLine] = []
        
        for (fromName, toName) in connections {
            guard let fromPoint = keypointDict[fromName],
                  let toPoint = keypointDict[toName],
                  fromPoint.confidence > PoseDetectionService.MIN_CONFIDENCE,
                  toPoint.confidence > PoseDetectionService.MIN_CONFIDENCE else {
                continue
            }
            
            lines.append(PoseLine(from: fromPoint, to: toPoint))
        }
        
        return lines
    }
    
    // MARK: - Exercise Detection Algorithms
    
    // Push-up detection algorithm
    private func detectPushup(keypoints: [Keypoint], prevState: PushupState) -> PushupState {
        // Create a dictionary for easy lookup
        var keypointDict: [String: Keypoint] = [:]
        for keypoint in keypoints {
            keypointDict[keypoint.part] = keypoint
        }
        
        // Check if we have all necessary keypoints
        guard let leftShoulder = keypointDict[BodyPart.leftShoulder.name],
              let rightShoulder = keypointDict[BodyPart.rightShoulder.name],
              let leftElbow = keypointDict[BodyPart.leftElbow.name],
              let rightElbow = keypointDict[BodyPart.rightElbow.name],
              let leftWrist = keypointDict[BodyPart.leftWrist.name],
              let rightWrist = keypointDict[BodyPart.rightWrist.name],
              let leftHip = keypointDict[BodyPart.leftHip.name],
              let rightHip = keypointDict[BodyPart.rightHip.name] else {
            return PushupState(
                isUp: prevState.isUp,
                isDown: prevState.isDown,
                count: prevState.count,
                formScore: prevState.formScore,
                feedback: "Position your full body in the frame"
            )
        }
        
        // Calculate angles for left and right arms
        let leftArmAngle = calculateAngle(a: leftShoulder, b: leftElbow, c: leftWrist)
        let rightArmAngle = calculateAngle(a: rightShoulder, b: rightElbow, c: rightWrist)
        
        // Calculate body alignment (back straight)
        let leftBodyAngle = calculateAngle(
            a: leftShoulder,
            b: leftHip,
            c: keypointDict[BodyPart.leftKnee.name] ?? leftHip
        )
        
        let rightBodyAngle = calculateAngle(
            a: rightShoulder,
            b: rightHip,
            c: keypointDict[BodyPart.rightKnee.name] ?? rightHip
        )
        
        // Average arm angle for detection
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Average body angle for detecting straight back
        let avgBodyAngle = (leftBodyAngle + rightBodyAngle) / 2
        
        // Check if the person is in up position (arms extended)
        let isUp = avgArmAngle > 160
        
        // Check if the person is in down position (arms bent)
        let isDown = avgArmAngle < 80
        
        // Calculate form score
        var formScore = 80 // Base score
        var feedback = ""
        
        // Arm position check
        if abs(leftArmAngle - rightArmAngle) > 30 {
            formScore -= 20
            feedback = "Keep arms evenly aligned"
        }
        
        // Back alignment check
        if avgBodyAngle < 160 || avgBodyAngle > 200 {
            formScore -= 20
            feedback = "Keep your back straight"
        }
        
        // Check for complete motion
        if isDown && prevState.isUp && !prevState.isDown {
            // Count a rep if it went from up to down
            return PushupState(
                isUp: false,
                isDown: true,
                count: prevState.count + 1,
                formScore: formScore,
                feedback: feedback
            )
        }
        
        // Update state for up position
        if isUp && !prevState.isUp && prevState.isDown {
            return PushupState(
                isUp: true,
                isDown: false,
                count: prevState.count,
                formScore: formScore,
                feedback: feedback.isEmpty ? "Good form" : feedback
            )
        }
        
        // Provide feedback for partial movements
        if !isUp && !isDown {
            if avgArmAngle > 120 {
                feedback = "Lower your body closer to the ground"
            } else if avgArmAngle < 100 {
                feedback = "Extend your arms fully when pushing up"
            }
        }
        
        return PushupState(
            isUp: isUp || prevState.isUp,
            isDown: isDown || prevState.isDown,
            count: prevState.count,
            formScore: formScore,
            feedback: feedback.isEmpty ? prevState.feedback : feedback
        )
    }
    
    // Pull-up detection algorithm
    private func detectPullup(keypoints: [Keypoint], prevState: PullupState) -> PullupState {
        // Create a dictionary for easy lookup
        var keypointDict: [String: Keypoint] = [:]
        for keypoint in keypoints {
            keypointDict[keypoint.part] = keypoint
        }
        
        // Check if we have all necessary keypoints
        guard let leftShoulder = keypointDict[BodyPart.leftShoulder.name],
              let rightShoulder = keypointDict[BodyPart.rightShoulder.name],
              let leftElbow = keypointDict[BodyPart.leftElbow.name],
              let rightElbow = keypointDict[BodyPart.rightElbow.name],
              let leftWrist = keypointDict[BodyPart.leftWrist.name],
              let rightWrist = keypointDict[BodyPart.rightWrist.name],
              let nose = keypointDict[BodyPart.nose.name] else {
            return PullupState(
                isUp: prevState.isUp,
                isDown: prevState.isDown,
                count: prevState.count,
                formScore: prevState.formScore,
                feedback: "Position your upper body in the frame"
            )
        }
        
        // For pull-ups, check if chin is above or below hands (wrists)
        let avgWristY = (leftWrist.position.y + rightWrist.position.y) / 2
        let noseY = nose.position.y
        
        // Check if chin (nose) is above hands (wrists)
        let isUp = noseY < avgWristY - 10 // Nose is above wrists
        
        // Check if in down position (arms extended)
        let leftArmAngle = calculateAngle(a: leftShoulder, b: leftElbow, c: leftWrist)
        let rightArmAngle = calculateAngle(a: rightShoulder, b: rightElbow, c: rightWrist)
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        let isDown = avgArmAngle > 160 // Arms extended in down position
        
        // Calculate form score
        var formScore = 80 // Base score
        var feedback = ""
        
        // Arm alignment check
        if abs(leftArmAngle - rightArmAngle) > 30 {
            formScore -= 20
            feedback = "Keep arms evenly aligned"
        }
        
        // Check for complete motion
        if isUp && prevState.isDown && !prevState.isUp {
            // Count a rep if it went from down to up
            return PullupState(
                isUp: true,
                isDown: false,
                count: prevState.count + 1,
                formScore: formScore,
                feedback: feedback.isEmpty ? "Good form" : feedback
            )
        }
        
        // Update state for down position
        if isDown && !prevState.isDown && prevState.isUp {
            return PullupState(
                isUp: false,
                isDown: true,
                count: prevState.count,
                formScore: formScore,
                feedback: feedback
            )
        }
        
        // Provide feedback
        if !isUp && !isDown {
            if noseY > avgWristY {
                feedback = "Pull your chin above the bar"
            } else if avgArmAngle < 160 {
                feedback = "Extend your arms fully on the way down"
            }
        }
        
        return PullupState(
            isUp: isUp || prevState.isUp,
            isDown: isDown || prevState.isDown,
            count: prevState.count,
            formScore: formScore,
            feedback: feedback.isEmpty ? prevState.feedback : feedback
        )
    }
    
    // Sit-up detection algorithm
    private func detectSitup(keypoints: [Keypoint], prevState: SitupState) -> SitupState {
        // Create a dictionary for easy lookup
        var keypointDict: [String: Keypoint] = [:]
        for keypoint in keypoints {
            keypointDict[keypoint.part] = keypoint
        }
        
        // Check if we have all necessary keypoints
        guard let leftShoulder = keypointDict[BodyPart.leftShoulder.name],
              let rightShoulder = keypointDict[BodyPart.rightShoulder.name],
              let leftHip = keypointDict[BodyPart.leftHip.name],
              let rightHip = keypointDict[BodyPart.rightHip.name],
              let leftKnee = keypointDict[BodyPart.leftKnee.name],
              let rightKnee = keypointDict[BodyPart.rightKnee.name] else {
            return SitupState(
                isUp: prevState.isUp,
                isDown: prevState.isDown,
                count: prevState.count,
                formScore: prevState.formScore,
                feedback: "Position your full body in the frame"
            )
        }
        
        // Calculate the angle between shoulders-hips-knees
        let leftAngle = calculateAngle(a: leftShoulder, b: leftHip, c: leftKnee)
        let rightAngle = calculateAngle(a: rightShoulder, b: rightHip, c: rightKnee)
        let avgAngle = (leftAngle + rightAngle) / 2
        
        // For sit-ups, the up position is when the upper body is at an angle to legs
        let isUp = avgAngle < 130 // Smaller angle means torso is up
        
        // Down position is when lying flat
        let isDown = avgAngle > 160 // Larger angle means torso is down
        
        // Calculate form score
        var formScore = 80 // Base score
        var feedback = ""
        
        // Check symmetry
        if abs(leftAngle - rightAngle) > 30 {
            formScore -= 20
            feedback = "Keep your body centered during the sit-up"
        }
        
        // Check knee position (should be bent)
        let leftLegAngle = calculateAngle(
            a: leftHip,
            b: leftKnee,
            c: keypointDict[BodyPart.leftAnkle.name] ?? leftKnee
        )
        
        let rightLegAngle = calculateAngle(
            a: rightHip,
            b: rightKnee,
            c: keypointDict[BodyPart.rightAnkle.name] ?? rightKnee
        )
        
        let avgLegAngle = (leftLegAngle + rightLegAngle) / 2
        
        if avgLegAngle > 160 { // Legs too straight
            formScore -= 20
            feedback = "Bend your knees for proper form"
        }
        
        // Check for complete motion
        if isUp && prevState.isDown && !prevState.isUp {
            // Count a rep if it went from down to up
            return SitupState(
                isUp: true,
                isDown: false,
                count: prevState.count + 1,
                formScore: formScore,
                feedback: feedback.isEmpty ? "Good form" : feedback
            )
        }
        
        // Update state for down position
        if isDown && !prevState.isDown && prevState.isUp {
            return SitupState(
                isUp: false,
                isDown: true,
                count: prevState.count,
                formScore: formScore,
                feedback: feedback
            )
        }
        
        // Provide feedback
        if !isUp && !isDown {
            if avgAngle > 140 {
                feedback = "Lift your upper body higher"
            } else if avgAngle < 150 {
                feedback = "Lower your back completely to the ground"
            }
        }
        
        return SitupState(
            isUp: isUp || prevState.isUp,
            isDown: isDown || prevState.isDown,
            count: prevState.count,
            formScore: formScore,
            feedback: feedback.isEmpty ? prevState.feedback : feedback
        )
    }
    
    // MARK: - Utility Methods
    
    // Reset exercise states
    func resetExerciseStates() {
        pushupState = PushupState()
        pullupState = PullupState()
        situpState = SitupState()
    }
}