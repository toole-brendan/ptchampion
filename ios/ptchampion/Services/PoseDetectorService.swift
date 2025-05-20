import Foundation
import MediaPipeTasksVision
import Combine
import CoreMedia
import UIKit // For image orientation
import AVFoundation // For video orientation
import Vision // For VNHumanBodyPoseObservation

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
        
        // Get device orientation to determine image rotation
        let deviceOrientation = UIDevice.current.orientation
        let imageOrientation: UIImage.Orientation
        
        switch deviceOrientation {
        case .portrait: 
            imageOrientation = .right        // device upright → rotate image 90° clockwise
        case .portraitUpsideDown: 
            imageOrientation = .left         // device upside down → rotate 90° counter-clockwise
        case .landscapeLeft: 
            imageOrientation = .up           // device rotated left → image is already upright
        case .landscapeRight: 
            imageOrientation = .down         // device rotated right → image 180° rotated
        default:
            imageOrientation = .right        // default to portrait behavior
        }
        
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
        // Joint indices reference BlazePose keypoints
        let noseLM       = landmarks[0]
        let leftShoulder = landmarks[11], rightShoulder = landmarks[12]
        let leftElbow    = landmarks[13], rightElbow    = landmarks[14]
        let leftWrist    = landmarks[15], rightWrist    = landmarks[16]
        let leftHip      = landmarks[23], rightHip      = landmarks[24]
        let leftKnee     = landmarks[25], rightKnee     = landmarks[26]
        let leftAnkle    = landmarks[27], rightAnkle    = landmarks[28]
        
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
            (.nose,          CGFloat(noseLM.x),       CGFloat(noseLM.y),       landmarkConfidence(noseLM)),
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
        
        // Publish the detected body on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.detectedBodySubject.send(detectedBody)
        }
    }

    deinit {
        // Clear poseLandmarker
        poseLandmarker = nil
        
        // Clear references
        detectedBodySubject.send(nil)
        
        print("PoseDetectorService deinitialized.")
    }
} 