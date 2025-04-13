import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - MediaPipe Pose Detection Service (Refactored)

class MediaPipePoseDetectionService {
    // MARK: - Properties
    
    // Renamed to reflect the specific task
    private var poseLandmarker: PoseLandmarker? 
    private var lastFrameTimestampMs: Int64 = 0
    
    // MediaPipe Landmark Indices (using newer PoseLandmarker constants)
    // Note: Ensure these indices match the model used (e.g., pose_landmarker_full.task)
    // These might not be needed directly if using PoseLandmarker constants like PoseLandmark.leftShoulder
    // static let nose = 0 ... etc
    
    // MARK: - Initialization
    
    init() {
        setupPoseLandmarker() // Updated setup method name
        // Removed resetExerciseStates()
    }
    
    private func setupPoseLandmarker() {
        // Using the newer PoseLandmarker API setup based on typical examples
        let options = PoseLandmarkerOptions()
        // Ensure the model file exists and path is correct
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task") else {
            print("Error: pose_landmarker_full.task model file not found.")
            return
        }
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video // Use .liveStream if using the delegate method
        options.numPoses = 1
        // options.minPoseDetectionConfidence = 0.5 // Example confidence thresholds
        // options.minTrackingConfidence = 0.5
        // options.minPosePresenceConfidence = 0.5
        options.outputSegmentationMasks = false // Disable if masks aren't needed
        
        // Set delegate if using .liveStream mode
        // options.poseLandmarkerLiveStreamDelegate = self 
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
            print("PoseLandmarker initialized successfully.")
        } catch {
            print("Failed to initialize PoseLandmarker: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    // Refactored detection method to return only PoseLandmarkerResult
    // Note: The original used MPPPoseDetectorResult, switching to newer API type
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> PoseLandmarkerResult? {
        guard let poseLandmarker = poseLandmarker else { 
            print("PoseLandmarker not initialized.")
            return nil 
        }
        
        // Convert CMSampleBuffer to MPImage
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
             print("Failed to create MPImage from sample buffer.")
             return nil
         }
        
        // Increment timestamp (must be monotonically increasing)
        let currentTimestampMs = Int64(Date().timeIntervalSince1970 * 1000)
        // Ensure timestamp is always increasing, even for rapid frames
        lastFrameTimestampMs = max(currentTimestampMs, lastFrameTimestampMs + 1)
        
        do {
            // Use detect(videoFrame:timestampInMilliseconds:) for .video mode
            let result = try poseLandmarker.detect(videoFrame: image, timestampInMilliseconds: lastFrameTimestampMs)
            return result
        } catch {
            print("Error detecting pose with PoseLandmarker: \(error)")
            return nil
        }
    }
    
    // MARK: - Visualization Methods (Updated for PoseLandmarkerResult)
    
    // Keep this method, but update to use PoseLandmarkerResult and NormalizedLandmark
    func drawPoseOverlay(on image: UIImage, poseResult: PoseLandmarkerResult) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image // Return original on error
        }
        
        // Draw original image
        image.draw(at: .zero)
        
        // Use the first detected pose's landmarks
        guard let landmarks = poseResult.landmarks.first else {
            // No landmarks detected, return original image
            UIGraphicsEndImageContext()
            return image
        }
        
        // Define connections using PoseLandmarker constants (ensure these are correct)
        let connections = PoseConnections.all // Use predefined connections if available, or define manually
        /* Example Manual Definition:
        let connections: [(PoseLandmark, PoseLandmark)] = [
            (.nose, .leftEye), (.nose, .rightEye), (.leftEye, .leftEar), (.rightEye, .rightEar), 
            (.leftShoulder, .rightShoulder), (.leftShoulder, .leftHip), (.rightShoulder, .rightHip), 
            (.leftHip, .rightHip), (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist), 
            (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist), (.leftHip, .leftKnee), 
            (.leftKnee, .leftAnkle), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle) 
            // Add more if needed
        ]
        */
        
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.green.cgColor)
        
        for connection in connections {
            guard let startLandmark = landmarks[connection.start.rawValue],
                  let endLandmark = landmarks[connection.end.rawValue],
                  startLandmark.visibility ?? 0 > 0.3,
                  endLandmark.visibility ?? 0 > 0.3 else {
                continue
            }
            
            let startPoint = CGPoint(
                x: CGFloat(startLandmark.x) * image.size.width,
                y: CGFloat(startLandmark.y) * image.size.height
            )
            let endPoint = CGPoint(
                x: CGFloat(endLandmark.x) * image.size.width,
                y: CGFloat(endLandmark.y) * image.size.height
            )
            
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
        
        // Draw landmarks
        context.setFillColor(UIColor.red.cgColor)
        for landmark in landmarks {
            if landmark.visibility ?? 0 > 0.3 {
                let center = CGPoint(
                    x: CGFloat(landmark.x) * image.size.width,
                    y: CGFloat(landmark.y) * image.size.height
                )
                let radius: CGFloat = 4.0
                context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage ?? image // Return original if context fails
    }
}

// Add PoseConnections helper if not defined elsewhere
struct PoseConnections {
    static let all: [(start: PoseLandmark, end: PoseLandmark)] = [
        // Torso
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        // Left Arm
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        // Right Arm
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
         // Left Leg
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        // Right Leg
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        // Optional Face (if needed)
        // (.nose, .leftEye), (.nose, .rightEye), (.leftEye, .leftEar), (.rightEye, .rightEar)
    ]
}
