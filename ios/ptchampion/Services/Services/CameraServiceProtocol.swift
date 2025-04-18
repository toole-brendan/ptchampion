import Foundation
import AVFoundation
import Combine

// Protocol defining the interface for camera access and frame publishing
protocol CameraServiceProtocol {
    // Publisher for camera access authorization status
    var authorizationStatusPublisher: AnyPublisher<AVAuthorizationStatus, Never> { get }

    // Publisher for the live camera frames (CMSampleBuffer)
    var framePublisher: AnyPublisher<CMSampleBuffer, Never> { get }

    // Publisher for errors encountered during session setup or runtime
    var errorPublisher: AnyPublisher<Error, Never> { get }

    // Requests camera permission from the user
    func requestCameraPermission()

    // Starts the camera capture session
    func startSession()

    // Stops the camera capture session
    func stopSession()

    // Provides the preview layer for displaying the camera feed
    // Note: Managing the layer itself might be better handled by the View
    //       or a dedicated UIViewRepresentable.
    // func getPreviewLayer() -> AVCaptureVideoPreviewLayer?
}

// Custom Error enum for CameraService
enum CameraError: Error, LocalizedError {
    case setupFailed(String)
    case permissionDenied
    case sessionError(Error)
    case deviceUnavailable

    var errorDescription: String? {
        switch self {
        case .setupFailed(let reason): return "Camera setup failed: \(reason)"
        case .permissionDenied: return "Camera access permission was denied."
        case .sessionError(let error): return "Camera session error: \(error.localizedDescription)"
        case .deviceUnavailable: return "Required camera device is unavailable."
        }
    }
} 