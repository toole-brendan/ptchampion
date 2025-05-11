import Foundation
import Vision
import Combine
import CoreMedia
import UIKit // For image orientation
import AVFoundation // For video orientation

class PoseDetectorService: PoseDetectorServiceProtocol, ObservableObject {

    private let visionQueue = DispatchQueue(label: "com.ptchampion.posedetector.visionqueue", qos: .userInitiated)
    private var requestHandler: VNImageRequestHandler?
    lazy private var bodyPoseRequest: VNDetectHumanBodyPoseRequest = {
        // Use [weak self] to avoid strong reference cycle
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            self?.handlePoseDetectionResults(request: request, error: error)
        }
        
        return request
    }()

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
        // Initialize the Vision request with throttling option
        self.isThrottlingEnabled = throttleFrames
        print("PoseDetectorService initialized. Throttling: \(throttleFrames)")
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
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            errorSubject.send(PoseDetectorError.invalidSampleBuffer)
            print("PoseDetectorService: Failed to get pixel buffer from sample buffer.")
            return
        }

        // Get orientation on main thread to avoid UIKit thread violations
        let orientation = DispatchQueue.main.sync {
            return self.imageOrientation(from: sampleBuffer)
        }

        // Use weak self in async block to avoid strong capture
        visionQueue.async { [weak self] in
            guard let self = self else { 
                print("PoseDetectorService: Self was nil during frame processing - skipping")
                return 
            }
            
            // Create a request handler for the current frame
            self.requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
            do {
                // Perform the body pose request
                try self.requestHandler?.perform([self.bodyPoseRequest])
            } catch {
                 // Use weak self in nested async block
                 DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorSubject.send(PoseDetectorError.visionRequestFailed(error))
                 }
                print("PoseDetectorService: Failed to perform Vision request: \(error.localizedDescription)")
            }
             // Release the handler after processing
             self.requestHandler = nil
        }
    }

    // Completion handler for the Vision request
    private func handlePoseDetectionResults(request: VNRequest, error: Error?) {
        if let error = error {
             // Use weak self in async block
             DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorSubject.send(PoseDetectorError.visionRequestFailed(error))
             }
            print("PoseDetectorService: Vision request failed with error: \(error.localizedDescription)")
            return
        }

        guard let results = request.results as? [VNHumanBodyPoseObservation], let observation = results.first else {
            // No body detected or error in results, publish nil
             // Use weak self in async block
             DispatchQueue.main.async { [weak self] in 
                guard let self = self else { return }
                self.detectedBodySubject.send(nil) 
             }
            // print("PoseDetectorService: No body pose detected or invalid results.")
            return
        }

        // Process the observation into our DetectedBody struct
        do {
            let detectedPoints = try observation.recognizedPoints(.all)
            var pointsDict: [VNHumanBodyPoseObservation.JointName: DetectedPoint] = [:]
            var totalConfidence: Float = 0
            var pointCount: Int = 0

            for (jointName, recognizedPoint) in detectedPoints {
                // Include all points but mark confidence clearly
                let point = DetectedPoint(name: jointName,
                                         location: recognizedPoint.location,
                                         confidence: recognizedPoint.confidence)
                
                // Only count high confidence points toward the overall confidence
                if recognizedPoint.confidence >= minimumPointConfidence {
                    totalConfidence += recognizedPoint.confidence
                    pointCount += 1
                }
                
                pointsDict[jointName] = point
            }
            
            // Calculate overall body confidence (average of valid points)
            let overallConfidence = pointCount > 0 ? totalConfidence / Float(pointCount) : 0
            
            let detectedBody = DetectedBody(points: pointsDict, confidence: overallConfidence)
            // Use weak self in async block
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.detectedBodySubject.send(detectedBody)
            }
        } catch {
            // Use weak self in async blocks
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorSubject.send(PoseDetectorError.processingFailed("Failed to process recognized points: \(error.localizedDescription)"))
            }
            print("PoseDetectorService: Error processing recognized points: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in 
                guard let self = self else { return }
                self.detectedBodySubject.send(nil) 
            }
        }
    }

    // Comprehensive orientation mapping for all device orientations
    private func imageOrientation(from sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
        // Try to get camera intrinsic data if available
        var exifOrientation: CGImagePropertyOrientation = .up
        
        // We'll rely primarily on the device orientation rather than trying to extract
        // orientation from the sample buffer, which can be device-specific
        let deviceOrientation = UIDevice.current.orientation
        
        switch deviceOrientation {
        case .portrait:
            exifOrientation = .right
        case .portraitUpsideDown:
            exifOrientation = .left
        case .landscapeLeft:
            exifOrientation = .up
        case .landscapeRight:
            exifOrientation = .down
        case .faceUp, .faceDown, .unknown:
            // When face up, face down, or unknown, use interface orientation
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let interfaceOrientation = windowScene.interfaceOrientation
                
                switch interfaceOrientation {
                case .portrait:
                    exifOrientation = .right
                case .portraitUpsideDown:
                    exifOrientation = .left
                case .landscapeLeft:
                    exifOrientation = .down
                case .landscapeRight:
                    exifOrientation = .up
                default:
                    // Default to portrait orientation
                    exifOrientation = .right
                }
            } else {
                // Default to portrait if we can't get the interface orientation
                exifOrientation = .right
            }
        @unknown default:
            // Default to portrait for any future device orientations
            exifOrientation = .right
        }
        
        return exifOrientation
    }

    deinit {
        // Cancel any pending requests
        bodyPoseRequest.cancel()
        requestHandler = nil
        
        // Clear references
        detectedBodySubject.send(nil)
        
        print("PoseDetectorService deinitialized.")
    }
} 