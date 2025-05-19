import Foundation
import Combine
import CoreMedia // For CMSampleBuffer

// Protocol defining the interface for pose detection
protocol PoseDetectorServiceProtocol {
    // Publisher for detected body poses
    var detectedBodyPublisher: AnyPublisher<DetectedBody?, Never> { get }
    // Publisher for any errors during processing
    var errorPublisher: AnyPublisher<Error, Never> { get }

    // Processes a single camera frame (CMSampleBuffer) to detect poses
    func processFrame(_ sampleBuffer: CMSampleBuffer)
}

// Custom Error enum for PoseDetectorService
enum PoseDetectorError: Error, LocalizedError {
    case processingFailed(String)
    case detectionFailed(Error)
    case invalidSampleBuffer
    case modelLoadingFailed(String)
    case inferenceEngineFailure(String)

    var errorDescription: String? {
        switch self {
        case .processingFailed(let reason): return "Pose detection processing failed: \(reason)"
        case .detectionFailed(let error): return "Pose detection failed: \(error.localizedDescription)"
        case .invalidSampleBuffer: return "Invalid sample buffer provided for processing."
        case .modelLoadingFailed(let reason): return "Failed to load pose detection model: \(reason)"
        case .inferenceEngineFailure(let reason): return "Inference engine failed: \(reason)"
        }
    }
} 