import Foundation
import MediaPipeTasksVision
import Combine
import CoreMedia
import UIKit // For image orientation
import AVFoundation // For video orientation
import Vision // Only kept for VNHumanBodyPoseObservation.JointName constants

class PoseDetectorService: NSObject, PoseDetectorServiceProtocol, ObservableObject, PoseLandmarkerLiveStreamDelegate {

    private let visionQueue = DispatchQueue(label: "com.ptchampion.posedetector.visionqueue", qos: .userInitiated)
    private var poseLandmarker: PoseLandmarker? = nil

    // Combine Publishers
    private let detectedBodySubject = CurrentValueSubject<DetectedBody?, Never>(nil)
    private let errorSubject = PassthroughSubject<Error, Never>()

    // Configuration
    private let minimumPointConfidence: Float = 0.1
    
    // Throttling support
    private var lastProcessedTimestamp: TimeInterval = 0
    private var throttleInterval: TimeInterval = 0.05 // 20 FPS (1/20 = 0.05s)
    private var isThrottlingEnabled: Bool = true
    
    // Orientation management
    private let orientationManager = OrientationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Smoothing support
    private var poseHistory: [DetectedBody] = []
    private let maxHistorySize = 3 // Average over last 3 frames
    private let smoothingAlpha: Float = 0.7 // Weight for current frame (0.7 = 70% current, 30% history)

    var detectedBodyPublisher: AnyPublisher<DetectedBody?, Never> {
        detectedBodySubject.eraseToAnyPublisher()
    }
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    init(throttleFrames: Bool = true) {
        // Call super.init() first before using self
        super.init()
        
        // Initialize the Vision request with throttling option
        self.isThrottlingEnabled = throttleFrames
        print("PoseDetectorService initialized. Throttling: \(throttleFrames)")
        
        // Initialize MediaPipe PoseLandmarker
        do {
            let modelPath = Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task")!
            // Configure options
            let options = PoseLandmarkerOptions()
            options.baseOptions.modelAssetPath = modelPath
            options.runningMode = .liveStream
            options.poseLandmarkerLiveStreamDelegate = self  // receive async callbacks
            options.numPoses = 1  // we only need the top pose
            // (Optional) Set confidence thresholds if desired; defaults are 0.5
            options.minPoseDetectionConfidence = 0.5
            options.minPosePresenceConfidence = 0.5
            options.minTrackingConfidence = 0.5
            // Create the PoseLandmarker
            self.poseLandmarker = try PoseLandmarker(options: options)
            print("PoseLandmarker model loaded successfully")
        } catch {
            print("Error loading PoseLandmarker: \(error)")
            self.poseLandmarker = nil
            // Publish an error to let the app know
            errorSubject.send(PoseDetectorError.modelLoadingFailed("Failed to load pose model: \(error.localizedDescription)"))
        }
    }
    
    // Set throttling enabled/disabled and the rate
    func setThrottling(enabled: Bool, framesPerSecond: Double = 20.0) {
        isThrottlingEnabled = enabled
        if framesPerSecond > 0 {
            throttleInterval = 1.0 / framesPerSecond
        }
        print("PoseDetectorService: Throttling \(enabled ? "enabled" : "disabled") at \(framesPerSecond) FPS")
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // Check if we should throttle this frame
        let currentTime = CACurrentMediaTime()
        if isThrottlingEnabled && (currentTime - lastProcessedTimestamp) < throttleInterval {
            // Skip this frame due to throttling
            return
        }
        lastProcessedTimestamp = currentTime
        
        guard let poseLandmarker = self.poseLandmarker else {
            errorSubject.send(PoseDetectorError.inferenceEngineFailure("PoseLandmarker not initialized"))
            return
        }
        
        // Get interface orientation for more reliable orientation detection
        let interfaceOrientation = orientationManager.interfaceOrientation
        // Use back camera orientation since CameraService uses .back for exercise tracking
        let imageOrientation = orientationManager.imageOrientationBackCamera(for: interfaceOrientation)
        
        do {
            // Wrap the CMSampleBuffer in an MPImage with the proper orientation
            let mpImage = try MPImage(sampleBuffer: sampleBuffer, orientation: imageOrientation)
            // Send it to the pose landmarker for async processing
            try poseLandmarker.detectAsync(image: mpImage, timestampInMilliseconds: getCurrentTimestampMs())
        } catch {
            // If there's an error converting image or sending to the model
            self.errorSubject.send(PoseDetectorError.processingFailed("MediaPipe pose detection failed: \(error.localizedDescription)"))
            return
        }
    }

    func getCurrentTimestampMs() -> Int {
        let time = CACurrentMediaTime() * 1000.0  // seconds to ms
        return Int(time)
    }
    
    // PoseLandmarkerLiveStreamDelegate method
    func poseLandmarker(_ landmarker: PoseLandmarker, 
                      didFinishDetection result: PoseLandmarkerResult?, 
                      timestampInMilliseconds ts: Int, 
                      error: Error?) {
        if let error = error {
            // Detection encountered an error
            DispatchQueue.main.async { [weak self] in
                self?.errorSubject.send(PoseDetectorError.processingFailed("PoseLandmarker error: \(error.localizedDescription)"))
            }
            return
        }
        
        guard let result = result, !result.landmarks.isEmpty else {
            // No pose detected in this frame – publish nil
            DispatchQueue.main.async { [weak self] in
                // Clear pose history when no body detected to avoid ghosting
                self?.poseHistory.removeAll()
                self?.detectedBodySubject.send(nil)
            }
            return
        }
        
        // We have at least one pose
        let landmarks = result.landmarks[0]  // first (and only) pose's landmarks
        var pointsDict: [VNHumanBodyPoseObservation.JointName: DetectedPoint] = [:]
        var totalConfidence: Float = 0
        var pointCount: Int = 0
        
        // Map MediaPipe's landmarks to our joints of interest
        // Face landmarks (indices 0-10)
        let noseLM        = landmarks[0]
        let leftEyeInner  = landmarks[1], leftEyeCenter = landmarks[2], leftEyeOuter = landmarks[3]
        let rightEyeInner = landmarks[4], rightEyeCenter = landmarks[5], rightEyeOuter = landmarks[6]
        let leftEarLM     = landmarks[7], rightEarLM    = landmarks[8]
        let leftMouthLM   = landmarks[9], rightMouthLM  = landmarks[10]
        
        // Body landmarks (indices 11-16, 23-28)
        let leftShoulder = landmarks[11], rightShoulder = landmarks[12]
        let leftElbow    = landmarks[13], rightElbow    = landmarks[14]
        let leftWrist    = landmarks[15], rightWrist    = landmarks[16]
        // Note: indices 17-22 are hand keypoints (fingers) - these can be captured if needed
        let leftHip      = landmarks[23], rightHip      = landmarks[24]
        let leftKnee     = landmarks[25], rightKnee     = landmarks[26]
        let leftAnkle    = landmarks[27], rightAnkle    = landmarks[28]
        
        // Foot landmarks (indices 29-32)
        let leftHeel     = landmarks[29], rightHeel     = landmarks[30]
        let leftToe      = landmarks[31], rightToe      = landmarks[32]
        
        // Compute synthetic joints
        let neckX = CGFloat((leftShoulder.x + rightShoulder.x) / 2)
        let neckY = CGFloat((leftShoulder.y + rightShoulder.y) / 2)
        let rootX = CGFloat((leftHip.x + rightHip.x) / 2)
        let rootY = CGFloat((leftHip.y + rightHip.y) / 2)
        
        // Helper to get confidence (visibility) if available
        func landmarkConfidence(_ lm: NormalizedLandmark) -> Float {
            if let vis = lm.visibility { 
                return vis.floatValue 
            }
            return 1.0  // if model doesn't provide visibility, default to 1.0
        }
        
        // Build DetectedPoint for each joint (using normalized [0,1] coordinates)
        let jointMappings: [(VNHumanBodyPoseObservation.JointName, CGFloat, CGFloat, Float)] = [
            // Face
            (.nose,          CGFloat(noseLM.x),       CGFloat(noseLM.y),       landmarkConfidence(noseLM)),
            (.leftEye,       CGFloat(leftEyeCenter.x),CGFloat(leftEyeCenter.y),landmarkConfidence(leftEyeCenter)),
            (.leftEyeInner,  CGFloat(leftEyeInner.x), CGFloat(leftEyeInner.y), landmarkConfidence(leftEyeInner)),
            (.leftEyeOuter,  CGFloat(leftEyeOuter.x), CGFloat(leftEyeOuter.y), landmarkConfidence(leftEyeOuter)),
            (.rightEye,      CGFloat(rightEyeCenter.x),CGFloat(rightEyeCenter.y),landmarkConfidence(rightEyeCenter)),
            (.rightEyeInner, CGFloat(rightEyeInner.x),CGFloat(rightEyeInner.y),landmarkConfidence(rightEyeInner)),
            (.rightEyeOuter, CGFloat(rightEyeOuter.x),CGFloat(rightEyeOuter.y),landmarkConfidence(rightEyeOuter)),
            (.leftEar,       CGFloat(leftEarLM.x),    CGFloat(leftEarLM.y),    landmarkConfidence(leftEarLM)),
            (.rightEar,      CGFloat(rightEarLM.x),   CGFloat(rightEarLM.y),   landmarkConfidence(rightEarLM)),
            (.leftMouth,     CGFloat(leftMouthLM.x),  CGFloat(leftMouthLM.y),  landmarkConfidence(leftMouthLM)),
            (.rightMouth,    CGFloat(rightMouthLM.x), CGFloat(rightMouthLM.y), landmarkConfidence(rightMouthLM)),
            // Body
            (.leftShoulder,  CGFloat(leftShoulder.x), CGFloat(leftShoulder.y), landmarkConfidence(leftShoulder)),
            (.rightShoulder, CGFloat(rightShoulder.x),CGFloat(rightShoulder.y),landmarkConfidence(rightShoulder)),
            (.leftElbow,     CGFloat(leftElbow.x),    CGFloat(leftElbow.y),    landmarkConfidence(leftElbow)),
            (.rightElbow,    CGFloat(rightElbow.x),   CGFloat(rightElbow.y),   landmarkConfidence(rightElbow)),
            (.leftWrist,     CGFloat(leftWrist.x),    CGFloat(leftWrist.y),    landmarkConfidence(leftWrist)),
            (.rightWrist,    CGFloat(rightWrist.x),   CGFloat(rightWrist.y),   landmarkConfidence(rightWrist)),
            (.leftHip,       CGFloat(leftHip.x),      CGFloat(leftHip.y),      landmarkConfidence(leftHip)),
            (.rightHip,      CGFloat(rightHip.x),     CGFloat(rightHip.y),     landmarkConfidence(rightHip)),
            (.leftKnee,      CGFloat(leftKnee.x),     CGFloat(leftKnee.y),     landmarkConfidence(leftKnee)),
            (.rightKnee,     CGFloat(rightKnee.x),    CGFloat(rightKnee.y),    landmarkConfidence(rightKnee)),
            (.leftAnkle,     CGFloat(leftAnkle.x),    CGFloat(leftAnkle.y),    landmarkConfidence(leftAnkle)),
            (.rightAnkle,    CGFloat(rightAnkle.x),   CGFloat(rightAnkle.y),   landmarkConfidence(rightAnkle)),
            // Feet
            (.leftHeel,      CGFloat(leftHeel.x),     CGFloat(leftHeel.y),     landmarkConfidence(leftHeel)),
            (.rightHeel,     CGFloat(rightHeel.x),    CGFloat(rightHeel.y),    landmarkConfidence(rightHeel)),
            (.leftToe,       CGFloat(leftToe.x),      CGFloat(leftToe.y),      landmarkConfidence(leftToe)),
            (.rightToe,      CGFloat(rightToe.x),     CGFloat(rightToe.y),     landmarkConfidence(rightToe)),
            // Synthetic
            (.neck,          neckX, neckY, min(landmarkConfidence(leftShoulder), landmarkConfidence(rightShoulder))),
            (.root,          rootX, rootY, min(landmarkConfidence(leftHip), landmarkConfidence(rightHip)))
        ]
        
        for (joint, x, y, conf) in jointMappings {
            let point = DetectedPoint(name: joint, location: CGPoint(x: x, y: y), confidence: conf)
            pointsDict[joint] = point
            if conf >= self.minimumPointConfidence {
                totalConfidence += conf
                pointCount += 1
            }
        }
        
        let overallConf: Float = pointCount > 0 ? totalConfidence / Float(pointCount) : 0
        let detectedBody = DetectedBody(points: pointsDict, confidence: overallConf)
        
        // Apply smoothing to reduce jumpiness
        let smoothedBody = smoothPose(detectedBody)
        
        // Publish the detected body on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.detectedBodySubject.send(smoothedBody)
        }
    }

    // MARK: - Smoothing
    private func smoothPose(_ currentBody: DetectedBody) -> DetectedBody {
        // Add current pose to history
        poseHistory.append(currentBody)
        
        // Maintain history size
        if poseHistory.count > maxHistorySize {
            poseHistory.removeFirst()
        }
        
        // If not enough history, return current pose
        if poseHistory.count < 2 {
            return currentBody
        }
        
        // Apply exponential moving average smoothing
        var smoothedPoints: [VNHumanBodyPoseObservation.JointName: DetectedPoint] = [:]
        
        for (jointName, currentPoint) in currentBody.points {
            // Get historical positions for this joint
            var historicalX: CGFloat = 0
            var historicalY: CGFloat = 0
            var historicalConfidence: Float = 0
            var validHistoryCount = 0
            
            // Calculate average of historical positions (excluding current)
            for i in 0..<(poseHistory.count - 1) {
                if let historicalPoint = poseHistory[i].points[jointName] {
                    historicalX += historicalPoint.location.x
                    historicalY += historicalPoint.location.y
                    historicalConfidence += historicalPoint.confidence
                    validHistoryCount += 1
                }
            }
            
            if validHistoryCount > 0 {
                // Calculate historical average
                historicalX /= CGFloat(validHistoryCount)
                historicalY /= CGFloat(validHistoryCount)
                historicalConfidence /= Float(validHistoryCount)
                
                // Apply exponential smoothing
                let smoothedX = CGFloat(smoothingAlpha) * currentPoint.location.x + CGFloat(1 - smoothingAlpha) * historicalX
                let smoothedY = CGFloat(smoothingAlpha) * currentPoint.location.y + CGFloat(1 - smoothingAlpha) * historicalY
                let smoothedConfidence = smoothingAlpha * currentPoint.confidence + (1 - smoothingAlpha) * historicalConfidence
                
                smoothedPoints[jointName] = DetectedPoint(
                    name: jointName,
                    location: CGPoint(x: smoothedX, y: smoothedY),
                    confidence: smoothedConfidence
                )
            } else {
                // No history, use current point
                smoothedPoints[jointName] = currentPoint
            }
        }
        
        return DetectedBody(points: smoothedPoints, confidence: currentBody.confidence)
    }

    deinit {
        // Clear poseLandmarker
        poseLandmarker = nil
        
        // Clear pose history
        poseHistory.removeAll()
        
        // Clear references
        detectedBodySubject.send(nil)
        
        // Cancel orientation subscriptions
        cancellables.forEach { $0.cancel() }
        
        print("PoseDetectorService deinitialized.")
    }
}
