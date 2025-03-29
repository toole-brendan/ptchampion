import Foundation
import UIKit
import AVFoundation
import Combine

// MARK: - ExerciseViewModel+MediaPipe

extension ExerciseViewModel {
    // Configuration key for MediaPipe
    private static let useMediaPipeKey = "useMediaPipeDetection"
    
    // Flag to control which detection system to use
    var useMediaPipe: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Self.useMediaPipeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.useMediaPipeKey)
        }
    }
    
    // Lazy-loaded MediaPipe service
    private var mediaPipeService: MediaPipePoseDetectionService {
        if _mediaPipeService == nil {
            _mediaPipeService = MediaPipePoseDetectionService()
        }
        return _mediaPipeService!
    }
    private var _mediaPipeService: MediaPipePoseDetectionService?
    
    // Enhanced MediaPipe detection
    func detectPoseWithMediaPipe(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        guard isExerciseActive else { return }
        
        // Use MediaPipe for detection
        let (pose, mediaPoseResult) = mediaPipeService.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: orientation)
        
        // Process results if we have both a pose and MediaPipe result
        if let pose = pose, let mediaPoseResult = mediaPoseResult {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Process different exercise types
                switch exerciseType {
                case .pushup:
                    self.exerciseState = self.mediaPipeService.detectPushup(mediapipePose: mediaPoseResult)
                case .situp:
                    self.exerciseState = self.mediaPipeService.detectSitup(mediapipePose: mediaPoseResult)
                case .pullup:
                    self.exerciseState = self.mediaPipeService.detectPullup(mediapipePose: mediaPoseResult)
                case .run:
                    // Run tracking is typically done via Bluetooth, not pose detection
                    break
                }
                
                // Draw enhanced pose overlay
                self.overlayImage = self.mediaPipeService.drawPoseOverlay(on: originalImage, mediapipePose: mediaPoseResult)
            }
        } else {
            // Fall back to traditional detection if MediaPipe fails
            detectPoseWithVision(sampleBuffer: sampleBuffer, orientation: orientation, exerciseType: exerciseType, originalImage: originalImage)
        }
    }
    
    // Original Vision-based detection (renamed for clarity)
    func detectPoseWithVision(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        guard isExerciseActive else { return }
        
        // This is the original implementation moved here for clarity
        poseDetectionService.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: orientation) { [weak self] pose in
            guard let self = self, let pose = pose else { return }
            
            // Detect exercise based on type
            DispatchQueue.main.async {
                switch exerciseType {
                case .pushup:
                    self.exerciseState = self.poseDetectionService.detectPushup(pose: pose)
                case .situp:
                    self.exerciseState = self.poseDetectionService.detectSitup(pose: pose)
                case .pullup:
                    self.exerciseState = self.poseDetectionService.detectPullup(pose: pose)
                case .run:
                    // Run is tracked via Bluetooth, not pose
                    break
                }
                
                // Draw pose overlay on the image
                self.overlayImage = self.poseDetectionService.drawPoseOverlay(on: originalImage, pose: pose)
            }
        }
    }
    
    // Updated detection method that chooses between MediaPipe and Vision
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        if useMediaPipe {
            detectPoseWithMediaPipe(sampleBuffer: sampleBuffer, orientation: orientation, exerciseType: exerciseType, originalImage: originalImage)
        } else {
            detectPoseWithVision(sampleBuffer: sampleBuffer, orientation: orientation, exerciseType: exerciseType, originalImage: originalImage)
        }
    }
    
    // Toggle between MediaPipe and Vision detection
    func toggleMediaPipe() -> Bool {
        useMediaPipe.toggle()
        if useMediaPipe {
            // Reset exercise state when switching to ensure clean tracking
            mediaPipeService.resetExerciseStates()
        } else {
            poseDetectionService.resetExerciseStates()
        }
        return useMediaPipe
    }
}
