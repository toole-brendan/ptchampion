import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - MediaPipe Pose Detection Service

class MediaPipePoseDetectionService {
    // MARK: - Properties
    
    private var poseDetector: PoseDetector?
    private(set) var pushupState = ExerciseState()
    private(set) var situpState = ExerciseState()
    private(set) var pullupState = ExerciseState()
    private var lastFrameTimestamp: Int64 = 0
    
    // MediaPipe has 33 landmarks versus Vision's 18
    enum MediaPipeLandmark {
        static let nose = 0
        static let leftEyeInner = 1
        static let leftEye = 2
        static let leftEyeOuter = 3
        static let rightEyeInner = 4
        static let rightEye = 5
        static let rightEyeOuter = 6
        static let leftEar = 7
        static let rightEar = 8
        static let mouthLeft = 9
        static let mouthRight = 10
        static let leftShoulder = 11
        static let rightShoulder = 12
        static let leftElbow = 13
        static let rightElbow = 14
        static let leftWrist = 15
        static let rightWrist = 16
        static let leftPinky = 17
        static let rightPinky = 18
        static let leftIndex = 19
        static let rightIndex = 20
        static let leftThumb = 21
        static let rightThumb = 22
        static let leftHip = 23
        static let rightHip = 24
        static let leftKnee = 25
        static let rightKnee = 26
        static let leftAnkle = 27
        static let rightAnkle = 28
        static let leftHeel = 29
        static let rightHeel = 30
        static let leftFootIndex = 31
        static let rightFootIndex = 32
    }
    
    // MARK: - Initialization
    
    init() {
        setupPoseDetector()
        resetExerciseStates()
    }
    
    private func setupPoseDetector() {
        let options = PoseDetectorOptions()
        options.baseOptions.modelAssetPath = "pose_landmarker_full.task"
        options.baseOptions.delegateOptions.useGpu = true  // Use GPU acceleration
        options.runningMode = .video  // For real-time camera feed
        options.numPoses = 1  // Track single person
        
        do {
            poseDetector = try PoseDetector.poseDetector(options: options)
        } catch {
            print("Failed to initialize pose detector: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    func resetExerciseStates() {
        pushupState = ExerciseState()
        situpState = ExerciseState()
        pullupState = ExerciseState()
    }
    
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> (pose: Pose?, mediaPoseResult: MPPPoseDetectorResult?) {
        guard let poseDetector = poseDetector else { return (nil, nil) }
        
        // Increment frame timestamp
        lastFrameTimestamp += 1
        
        do {
            let mpImage = try MPImage(sampleBuffer: sampleBuffer)
            let result = try poseDetector.detect(image: mpImage, timestampInMilliseconds: lastFrameTimestamp)
            
            // Convert to our app's Pose format for compatibility with existing code
            let pose = createPose(from: result)
            return (pose, result)
        } catch {
            print("Error detecting pose: \(error.localizedDescription)")
            return (nil, nil)
        }
    }
    
    // MARK: - Pose Analysis
    
    // Convert MediaPipe landmarks to our existing Pose structure
    private func createPose(from result: MPPPoseDetectorResult) -> Pose? {
        var keypoints = [VNHumanBodyPoseObservation.JointName: Keypoint]()
        
        // Make sure we have at least one detected pose
        guard let landmarks = result.landmarks().first, !landmarks.isEmpty else {
            return nil
        }
        
        // Map MediaPipe landmarks to our app's joint structure
        
        // Head landmarks
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.nose, to: .nose, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftEye, to: .leftEye, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightEye, to: .rightEye, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftEar, to: .leftEar, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightEar, to: .rightEar, in: &keypoints)
        
        // Upper body landmarks
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftShoulder, to: .leftShoulder, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightShoulder, to: .rightShoulder, in: &keypoints)
        // Map MediaPipe mouthLeft/Right midpoint to neck
        if landmarks.count > MediaPipeLandmark.rightShoulder {
            let leftShoulder = landmarks[MediaPipeLandmark.leftShoulder]
            let rightShoulder = landmarks[MediaPipeLandmark.rightShoulder]
            let neckPoint = CGPoint(
                x: (CGFloat(leftShoulder.x) + CGFloat(rightShoulder.x)) / 2,
                y: (CGFloat(leftShoulder.y) + CGFloat(rightShoulder.y)) / 2 - 0.05 // Slightly above shoulders
            )
            let confidence = Float((leftShoulder.visibility ?? 0 + rightShoulder.visibility ?? 0) / 2)
            keypoints[.neck] = Keypoint(point: neckPoint, confidence: confidence)
        }
        
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftElbow, to: .leftElbow, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightElbow, to: .rightElbow, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftWrist, to: .leftWrist, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightWrist, to: .rightWrist, in: &keypoints)
        
        // Lower body landmarks
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftHip, to: .leftHip, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightHip, to: .rightHip, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftKnee, to: .leftKnee, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightKnee, to: .rightKnee, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.leftAnkle, to: .leftAnkle, in: &keypoints)
        mapLandmarkIfAvailable(landmarks, MediaPipeLandmark.rightAnkle, to: .rightAnkle, in: &keypoints)
        
        return Pose(keypoints: keypoints)
    }
    
    private func mapLandmarkIfAvailable(_ landmarks: [MPPLandmark], _ mediaPipeIndex: Int, to jointName: VNHumanBodyPoseObservation.JointName, in keypoints: inout [VNHumanBodyPoseObservation.JointName: Keypoint]) {
        if landmarks.count > mediaPipeIndex {
            let landmark = landmarks[mediaPipeIndex]
            keypoints[jointName] = Keypoint(
                point: CGPoint(x: CGFloat(landmark.x), y: 1 - CGFloat(landmark.y)), // Flip Y coordinate to match Vision
                confidence: Float(landmark.visibility ?? 0)
            )
        }
    }
    
    // MARK: - Enhanced Push-up Detection
    
    func detectPushup(mediapipePose: MPPPoseDetectorResult) -> ExerciseState {
        var state = pushupState
        
        // Get the landmarks from MediaPipe result
        guard let landmarks = mediapipePose.landmarks().first,
              landmarks.count > MediaPipeLandmark.rightAnkle else {
            state.feedback = "Position not detected. Make sure your full body is visible."
            return state
        }
        
        // Extract key points for push-up analysis
        guard let leftShoulder = getLandmark(landmarks, MediaPipeLandmark.leftShoulder),
              let rightShoulder = getLandmark(landmarks, MediaPipeLandmark.rightShoulder),
              let leftElbow = getLandmark(landmarks, MediaPipeLandmark.leftElbow),
              let rightElbow = getLandmark(landmarks, MediaPipeLandmark.rightElbow),
              let leftWrist = getLandmark(landmarks, MediaPipeLandmark.leftWrist),
              let rightWrist = getLandmark(landmarks, MediaPipeLandmark.rightWrist),
              let leftHip = getLandmark(landmarks, MediaPipeLandmark.leftHip),
              let rightHip = getLandmark(landmarks, MediaPipeLandmark.rightHip) else {
            state.feedback = "Key points not detected. Ensure proper positioning."
            return state
        }
        
        // Calculate arm angles (shoulder-elbow-wrist)
        let leftArmAngle = calculateAngle(
            a: leftShoulder,
            b: leftElbow,
            c: leftWrist
        )
        
        let rightArmAngle = calculateAngle(
            a: rightShoulder, 
            b: rightElbow, 
            c: rightWrist
        )
        
        // Average arm angle
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Calculate body alignment (using shoulders and hips)
        let bodyLineAngle = calculateBodyLineAngle(
            shoulders: (left: leftShoulder, right: rightShoulder),
            hips: (left: leftHip, right: rightHip)
        )
        
        // Detect push-up positions
        let isUpPosition = avgArmAngle > 150 // Arms extended
        let isDownPosition = avgArmAngle < 90 // Arms bent
        
        // Form analysis
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check body alignment
        if abs(bodyLineAngle - 180) > 15 {
            formFeedback += "Keep your body straight. "
            formScoreValue -= 20
        }
        
        // Check arm symmetry
        if abs(leftArmAngle - rightArmAngle) > 15 {
            formFeedback += "Keep arms evenly aligned. "
            formScoreValue -= 15
        }
        
        // Hand placement check using index fingers
        if let leftIndex = getLandmark(landmarks, MediaPipeLandmark.leftIndex),
           let rightIndex = getLandmark(landmarks, MediaPipeLandmark.rightIndex) {
            
            // Horizontal distance between hands
            let handWidth = abs(leftIndex.x - rightIndex.x)
            
            // Shoulder width
            let shoulderWidth = abs(leftShoulder.x - rightShoulder.x)
            
            // Hands should be approximately shoulder-width apart
            if handWidth < shoulderWidth * 0.7 {
                formFeedback += "Hands too close together. "
                formScoreValue -= 15
            } else if handWidth > shoulderWidth * 1.5 {
                formFeedback += "Hands too far apart. "
                formScoreValue -= 15
            }
            
            // Check if hands are under shoulders
            let leftHandAlign = abs(leftIndex.x - leftShoulder.x)
            let rightHandAlign = abs(rightIndex.x - rightShoulder.x)
            
            if leftHandAlign > shoulderWidth * 0.25 || rightHandAlign > shoulderWidth * 0.25 {
                formFeedback += "Position hands under shoulders. "
                formScoreValue -= 10
            }
        }
        
        // Depth check with additional landmarks
        if isDownPosition {
            // Check if chest is close enough to ground
            let shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2
            let wristHeight = (leftWrist.y + rightWrist.y) / 2
            
            if shoulderHeight - wristHeight < 0.05 { // Not going low enough
                formFeedback += "Lower your chest closer to the ground. "
                formScoreValue -= 15
            }
        }
        
        // Rep counting logic
        if isUpPosition && !state.isUp && state.isDown {
            // Completed a rep (from down to up)
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set appropriate feedback based on position and form
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
    
    // MARK: - Enhanced Situp Detection
    
    func detectSitup(mediapipePose: MPPPoseDetectorResult) -> ExerciseState {
        var state = situpState
        
        // Get the landmarks from MediaPipe result
        guard let landmarks = mediapipePose.landmarks().first,
              landmarks.count > MediaPipeLandmark.rightKnee else {
            state.feedback = "Position not detected. Make sure your body is visible."
            return state
        }
        
        // Extract key points for sit-up analysis
        guard let leftShoulder = getLandmark(landmarks, MediaPipeLandmark.leftShoulder),
              let rightShoulder = getLandmark(landmarks, MediaPipeLandmark.rightShoulder),
              let leftHip = getLandmark(landmarks, MediaPipeLandmark.leftHip),
              let rightHip = getLandmark(landmarks, MediaPipeLandmark.rightHip),
              let leftKnee = getLandmark(landmarks, MediaPipeLandmark.leftKnee),
              let rightKnee = getLandmark(landmarks, MediaPipeLandmark.rightKnee) else {
            state.feedback = "Key points not detected. Ensure proper positioning."
            return state
        }
        
        // Calculate torso angle (shoulders-hips-knees)
        let leftTorsoAngle = calculateAngle(a: leftShoulder, b: leftHip, c: leftKnee)
        let rightTorsoAngle = calculateAngle(a: rightShoulder, b: rightHip, c: rightKnee)
        let avgTorsoAngle = (leftTorsoAngle + rightTorsoAngle) / 2
        
        // Calculate knee angle
        let leftKneeAngle = calculateAngle(
            a: getLandmark(landmarks, MediaPipeLandmark.leftHip) ?? leftHip,
            b: getLandmark(landmarks, MediaPipeLandmark.leftKnee) ?? leftKnee,
            c: getLandmark(landmarks, MediaPipeLandmark.leftAnkle) ?? CGPoint(x: leftKnee.x, y: leftKnee.y - 0.2)
        )
        let rightKneeAngle = calculateAngle(
            a: getLandmark(landmarks, MediaPipeLandmark.rightHip) ?? rightHip,
            b: getLandmark(landmarks, MediaPipeLandmark.rightKnee) ?? rightKnee,
            c: getLandmark(landmarks, MediaPipeLandmark.rightAnkle) ?? CGPoint(x: rightKnee.x, y: rightKnee.y - 0.2)
        )
        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
        
        // Detect sit-up positions
        let isUpPosition = avgTorsoAngle > 60 // Upper body is raised
        let isDownPosition = avgTorsoAngle < 30 // Upper body is down
        
        // Form analysis
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check knee bend
        if avgKneeAngle > 110 { // Knees too straight
            formFeedback += "Bend your knees more. "
            formScoreValue -= 15
        }
        
        // Check symmetry
        if abs(leftTorsoAngle - rightTorsoAngle) > 15 {
            formFeedback += "Keep your torso aligned. "
            formScoreValue -= 15
        }
        
        // Rep counting logic
        if isUpPosition && !state.isUp && state.isDown {
            // Completed a rep (from down to up)
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set appropriate feedback
        if formFeedback.isEmpty {
            if isUpPosition {
                state.feedback = "Good form! Lower your torso."
            } else if isDownPosition {
                state.feedback = "Good form! Raise your torso."
            } else {
                state.feedback = "Continue the movement."
            }
        } else {
            state.feedback = formFeedback
        }
        
        situpState = state
        return state
    }
    
    // MARK: - Enhanced Pullup Detection
    
    func detectPullup(mediapipePose: MPPPoseDetectorResult) -> ExerciseState {
        var state = pullupState
        
        // Get the landmarks from MediaPipe result
        guard let landmarks = mediapipePose.landmarks().first,
              landmarks.count > MediaPipeLandmark.rightWrist else {
            state.feedback = "Position not detected. Make sure your upper body is visible."
            return state
        }
        
        // Extract key points for pull-up analysis
        guard let leftShoulder = getLandmark(landmarks, MediaPipeLandmark.leftShoulder),
              let rightShoulder = getLandmark(landmarks, MediaPipeLandmark.rightShoulder),
              let leftElbow = getLandmark(landmarks, MediaPipeLandmark.leftElbow),
              let rightElbow = getLandmark(landmarks, MediaPipeLandmark.rightElbow),
              let leftWrist = getLandmark(landmarks, MediaPipeLandmark.leftWrist),
              let rightWrist = getLandmark(landmarks, MediaPipeLandmark.rightWrist),
              let nose = getLandmark(landmarks, MediaPipeLandmark.nose) else {
            state.feedback = "Key points not detected. Ensure upper body is visible."
            return state
        }
        
        // Calculate arm angles
        let leftArmAngle = calculateAngle(a: leftShoulder, b: leftElbow, c: leftWrist)
        let rightArmAngle = calculateAngle(a: rightShoulder, b: rightElbow, c: rightWrist)
        let avgArmAngle = (leftArmAngle + rightArmAngle) / 2
        
        // Average wrist height (bar position)
        let avgWristY = (leftWrist.y + rightWrist.y) / 2
        
        // Detect pull-up positions
        let isUpPosition = avgArmAngle < 90 && nose.y < avgWristY + 0.05 // Arms bent and chin over/near bar
        let isDownPosition = avgArmAngle > 150 // Arms extended
        
        // Form analysis
        var formFeedback = ""
        var formScoreValue = 100
        
        // Check arm symmetry
        if abs(leftArmAngle - rightArmAngle) > 15 {
            formFeedback += "Keep arms evenly aligned. "
            formScoreValue -= 15
        }
        
        // Check chin position relative to bar
        if isUpPosition && nose.y > avgWristY + 0.05 {
            formFeedback += "Pull up until chin is above the bar. "
            formScoreValue -= 20
        }
        
        // Check for full extension in down position
        if isDownPosition && avgArmAngle < 160 {
            formFeedback += "Extend arms fully at bottom of movement. "
            formScoreValue -= 15
        }
        
        // Rep counting logic
        if isUpPosition && !state.isUp && state.isDown {
            // Completed a rep (from down to up)
            state.recordRepetition()
            state.isDown = false
        } else if isDownPosition && !state.isDown {
            // Just reached down position
            state.isDown = true
        }
        
        // Update state
        state.isUp = isUpPosition
        state.updateFormScore(newScore: formScoreValue)
        
        // Set appropriate feedback
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
    
    // MARK: - Helper Methods
    
    private func getLandmark(_ landmarks: [MPPLandmark], _ index: Int) -> CGPoint? {
        guard landmarks.count > index, 
              let visibility = landmarks[index].visibility, 
              visibility > 0.3 else {
            return nil
        }
        
        return CGPoint(
            x: CGFloat(landmarks[index].x),
            y: CGFloat(landmarks[index].y)
        )
    }
    
    private func calculateAngle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let vector1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let vector2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        
        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let cross = vector1.dx * vector2.dy - vector1.dy * vector2.dx
        
        let angle = atan2(cross, dot)
        return abs(angle * 180 / .pi)
    }
    
    private func calculateBodyLineAngle(shoulders: (left: CGPoint, right: CGPoint), 
                                        hips: (left: CGPoint, right: CGPoint)) -> CGFloat {
        // Calculate midpoints
        let shoulderMidpoint = CGPoint(
            x: (shoulders.left.x + shoulders.right.x) / 2,
            y: (shoulders.left.y + shoulders.right.y) / 2
        )
        
        let hipMidpoint = CGPoint(
            x: (hips.left.x + hips.right.x) / 2,
            y: (hips.left.y + hips.right.y) / 2
        )
        
        // Calculate angle against horizontal
        let dx = shoulderMidpoint.x - hipMidpoint.x
        let dy = shoulderMidpoint.y - hipMidpoint.y
        
        return atan2(dy, dx) * 180 / .pi + 90 // Add 90 to get angle relative to vertical
    }
    
    // MARK: - Visualization Methods
    
    func drawPoseOverlay(on image: UIImage, mediapipePose: MPPPoseDetectorResult) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw original image
        image.draw(at: .zero)
        
        guard let landmarks = mediapipePose.landmarks().first else {
            let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return resultImage
        }
        
        // Define connections between landmarks
        let connections: [(Int, Int)] = [
            // Face
            (MediaPipeLandmark.nose, MediaPipeLandmark.leftEye),
            (MediaPipeLandmark.nose, MediaPipeLandmark.rightEye),
            (MediaPipeLandmark.leftEye, MediaPipeLandmark.leftEar),
            (MediaPipeLandmark.rightEye, MediaPipeLandmark.rightEar),
            
            // Torso
            (MediaPipeLandmark.leftShoulder, MediaPipeLandmark.rightShoulder),
            (MediaPipeLandmark.leftShoulder, MediaPipeLandmark.leftHip),
            (MediaPipeLandmark.rightShoulder, MediaPipeLandmark.rightHip),
            (MediaPipeLandmark.leftHip, MediaPipeLandmark.rightHip),
            
            // Arms
            (MediaPipeLandmark.leftShoulder, MediaPipeLandmark.leftElbow),
            (MediaPipeLandmark.leftElbow, MediaPipeLandmark.leftWrist),
            (MediaPipeLandmark.rightShoulder, MediaPipeLandmark.rightElbow),
            (MediaPipeLandmark.rightElbow, MediaPipeLandmark.rightWrist),
            
            // Hands (unique to MediaPipe)
            (MediaPipeLandmark.leftWrist, MediaPipeLandmark.leftThumb),
            (MediaPipeLandmark.leftWrist, MediaPipeLandmark.leftIndex),
            (MediaPipeLandmark.leftWrist, MediaPipeLandmark.leftPinky),
            (MediaPipeLandmark.rightWrist, MediaPipeLandmark.rightThumb),
            (MediaPipeLandmark.rightWrist, MediaPipeLandmark.rightIndex),
            (MediaPipeLandmark.rightWrist, MediaPipeLandmark.rightPinky),
            
            // Legs
            (MediaPipeLandmark.leftHip, MediaPipeLandmark.leftKnee),
            (MediaPipeLandmark.leftKnee, MediaPipeLandmark.leftAnkle),
            (MediaPipeLandmark.rightHip, MediaPipeLandmark.rightKnee),
            (MediaPipeLandmark.rightKnee, MediaPipeLandmark.rightAnkle),
            
            // Feet (unique to MediaPipe)
            (MediaPipeLandmark.leftAnkle, MediaPipeLandmark.leftHeel),
            (MediaPipeLandmark.leftHeel, MediaPipeLandmark.leftFootIndex),
            (MediaPipeLandmark.leftAnkle, MediaPipeLandmark.leftFootIndex),
            (MediaPipeLandmark.rightAnkle, MediaPipeLandmark.rightHeel),
            (MediaPipeLandmark.rightHeel, MediaPipeLandmark.rightFootIndex),
            (MediaPipeLandmark.rightAnkle, MediaPipeLandmark.rightFootIndex)
        ]
        
        // Draw connections
        context.setLineWidth(5.0)
        context.setStrokeColor(UIColor.green.cgColor)
        
        for (start, end) in connections {
            guard start < landmarks.count, end < landmarks.count,
                  (landmarks[start].visibility ?? 0) > 0.3,
                  (landmarks[end].visibility ?? 0) > 0.3 else {
                continue
            }
            
            let startPoint = CGPoint(
                x: CGFloat(landmarks[start].x) * image.size.width,
                y: CGFloat(landmarks[start].y) * image.size.height
            )
            
            let endPoint = CGPoint(
                x: CGFloat(landmarks[end].x) * image.size.width,
                y: CGFloat(landmarks[end].y) * image.size.height
            )
            
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
        
        // Draw landmarks
        for landmark in landmarks {
            if (landmark.visibility ?? 0) > 0.3 {
                let center = CGPoint(
                    x: CGFloat(landmark.x) * image.size.width,
                    y: CGFloat(landmark.y) * image.size.height
                )
                
                context.setFillColor(UIColor.red.cgColor)
                context.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
            }
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}
