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
    
    // We still need the service to GET the raw landmarks
    private var mediaPipePoseDetectorService: MediaPipePoseDetectionService {
        if _mediaPipeService == nil {
            _mediaPipeService = MediaPipePoseDetectionService()
        }
        return _mediaPipeService!
    }
    private var _mediaPipeService: MediaPipePoseDetectionService?
    
    // Updated MediaPipe detection using ExerciseAnalyzer
    func detectPoseWithMediaPipe(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        // Only process if the session is running and we have an analyzer
        guard sessionState == .running, let analyzer = self.exerciseAnalyzer else {
            // Optionally clear overlay if not running or no analyzer
            // DispatchQueue.main.async { self.overlayImage = nil }
            return
        }
        
        // Use MediaPipe service just to get the landmark results
        let (_, mediaPoseResult) = mediaPipePoseDetectorService.detectPoseInFrame(sampleBuffer: sampleBuffer, orientation: orientation)
        
        // Process results if MediaPipe detection was successful
        if let mediaPoseResult = mediaPoseResult {
            // Analyze the pose using the specific exercise analyzer
            let analysisResult = analyzer.analyze(poseLandmarkerResult: mediaPoseResult, imageSize: originalImage.size)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Update published properties from the analysis result
                self.repCount = analysisResult.repCount
                self.feedback = analysisResult.feedback
                self.formScore = analysisResult.formScore
                self.currentExerciseState = analysisResult.state
                
                // Draw pose overlay using the raw result
                // Ensure drawPoseOverlay still exists and works with PoseLandmarkerResult
                self.overlayImage = self.mediaPipePoseDetectorService.drawPoseOverlay(on: originalImage, mediapipePose: mediaPoseResult)
            }
        } else {
            // Handle MediaPipe detection failure (e.g., show error, switch state)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.feedback = ["MediaPipe detection failed."]
                self.currentExerciseState = .invalid
                self.overlayImage = originalImage // Show original image without overlay
            }
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
    
    // Updated detection method choosing the active path
    // Assumes handleFrame in the main ViewModel calls this
    func detectPoseInFrame(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, exerciseType: ExerciseType, originalImage: UIImage) {
        // Removed the useMediaPipe toggle logic for simplicity, assuming MediaPipe is the primary method now.
        // If the toggle is still desired, re-add the if/else based on self.useMediaPipe.
        detectPoseWithMediaPipe(sampleBuffer: sampleBuffer, orientation: orientation, exerciseType: exerciseType, originalImage: originalImage)
        
        // If Vision fallback is kept:
        // if useMediaPipe { ... } else { detectPoseWithVision(...) }
    }
    
    // Toggle MediaPipe (if still needed) - Updated reset logic
    func toggleMediaPipe() -> Bool {
        useMediaPipe.toggle()
        // Reset the analyzer state and view model state when toggling
        self.exerciseAnalyzer?.reset()
        self.resetAnalysisState() // Use the VM's reset method added previously
        
        // Original code had poseDetectionService.resetExerciseStates() - remove if Vision path is removed
        // if !useMediaPipe { poseDetectionService.resetExerciseStates() }
        
        print("Toggled MediaPipe usage to: \(useMediaPipe)")
        return useMediaPipe
    }
}
