import Foundation
import Vision
import Combine
import CoreMedia
import UIKit // For image orientation

class PoseDetectorService: PoseDetectorServiceProtocol, ObservableObject {

    private let visionQueue = DispatchQueue(label: "com.ptchampion.posedetector.visionqueue", qos: .userInitiated)
    private var requestHandler: VNImageRequestHandler?
    lazy private var bodyPoseRequest: VNDetectHumanBodyPoseRequest = {
        VNDetectHumanBodyPoseRequest(completionHandler: handlePoseDetectionResults)
    }()

    // Combine Publishers
    private let detectedBodySubject = CurrentValueSubject<DetectedBody?, Never>(nil)
    private let errorSubject = PassthroughSubject<Error, Never>()

    var detectedBodyPublisher: AnyPublisher<DetectedBody?, Never> {
        detectedBodySubject.eraseToAnyPublisher()
    }
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    init() {
        // Initialize the Vision request. This can be configured further.
        print("PoseDetectorService initialized.")
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            errorSubject.send(PoseDetectorError.invalidSampleBuffer)
            print("PoseDetectorService: Failed to get pixel buffer from sample buffer.")
            return
        }

        // Determine the correct orientation for the Vision request
        // This uses the sample buffer's attachments if available, falling back
        // to device orientation (less reliable if device orientation is locked).
        let orientation = imageOrientation(from: sampleBuffer)

        visionQueue.async {
            // Create a request handler for the current frame
            self.requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
            do {
                // Perform the body pose request
                try self.requestHandler?.perform([self.bodyPoseRequest])
            } catch {
                 DispatchQueue.main.async { // Publish error on main thread
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
             DispatchQueue.main.async {
                self.errorSubject.send(PoseDetectorError.visionRequestFailed(error))
             }
            print("PoseDetectorService: Vision request failed with error: \(error.localizedDescription)")
            return
        }

        guard let results = request.results as? [VNHumanBodyPoseObservation], let observation = results.first else {
            // No body detected or error in results, publish nil
             DispatchQueue.main.async { self.detectedBodySubject.send(nil) }
            // print("PoseDetectorService: No body pose detected or invalid results.")
            return
        }

        // Process the observation into our DetectedBody struct
        do {
            let detectedPoints = try observation.recognizedPoints(.all)
            var pointsDict: [VNHumanBodyPoseObservation.JointName: DetectedPoint] = [:]

            for (jointName, recognizedPoint) in detectedPoints where recognizedPoint.confidence > 0.1 { // Filter low confidence points
                pointsDict[jointName] = DetectedPoint(name: jointName,
                                                    location: recognizedPoint.location,
                                                    confidence: recognizedPoint.confidence)
            }

            let detectedBody = DetectedBody(points: pointsDict, confidence: observation.confidence)
             DispatchQueue.main.async { // Publish result on main thread
                 self.detectedBodySubject.send(detectedBody)
             }
             // print("PoseDetectorService: Detected body with \(detectedBody.points.count) points.")
        } catch {
             DispatchQueue.main.async {
                 self.errorSubject.send(PoseDetectorError.processingFailed("Failed to process recognized points: \(error.localizedDescription)"))
             }
            print("PoseDetectorService: Error processing recognized points: \(error.localizedDescription)")
             DispatchQueue.main.async { self.detectedBodySubject.send(nil) }
        }
    }

     // Helper to determine CGImagePropertyOrientation from CMSampleBuffer
     private func imageOrientation(from sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
         // Attempt to get orientation from CMSampleBuffer attachment
         if let orientationAttachment = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) as? Data {
             // Extract orientation from the intrinsic matrix data if possible (complex)
             // Placeholder: This part is non-trivial and often device-specific.
             // For now, we fall back to device orientation.
             // print("Orientation attachment found, but extraction not implemented.")
         }

         // Fallback: Get orientation from the current device UI orientation
         // Note: This might be incorrect if the device orientation is locked.
         let currentDeviceOrientation = UIDevice.current.orientation
         let exifOrientation: CGImagePropertyOrientation

         switch currentDeviceOrientation {
         case .portrait: exifOrientation = .right // Sample buffer is landscape right, UI is portrait
         case .portraitUpsideDown: exifOrientation = .left // Sample buffer is landscape right, UI is upside down
         case .landscapeLeft: exifOrientation = .up // Sample buffer is landscape right, UI is landscape left
         case .landscapeRight: exifOrientation = .down // Sample buffer is landscape right, UI is landscape right
         case .faceUp, .faceDown, .unknown:
             // Assume portrait if orientation is unknown
             exifOrientation = .right
         @unknown default: exifOrientation = .right
         }
         // print("Using orientation: \(exifOrientation.rawValue)")
         return exifOrientation
     }

    deinit {
        print("PoseDetectorService deinitialized.")
    }
} 