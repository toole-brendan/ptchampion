import Foundation
import Combine
import CoreMedia // For CMSampleBuffer
import Vision // For VNRequest

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
    case visionRequestFailed(Error)
    case invalidSampleBuffer

    var errorDescription: String? {
        switch self {
        case .processingFailed(let reason): return "Pose detection processing failed: \(reason)"
        case .visionRequestFailed(let error): return "Vision request failed: \(error.localizedDescription)"
        case .invalidSampleBuffer: return "Invalid sample buffer provided for processing."
        }
    }
} 