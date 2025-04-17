import Foundation
import AVFoundation
import Combine
import UIKit // Needed for orientation

class CameraService: NSObject, CameraServiceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.ptchampion.cameraservice.sessionqueue", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    // Combine Publishers
    private let authorizationStatusSubject = CurrentValueSubject<AVAuthorizationStatus, Never>(.notDetermined)
    private let frameSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    var authorizationStatusPublisher: AnyPublisher<AVAuthorizationStatus, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }
    var framePublisher: AnyPublisher<CMSampleBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // Public computed property for preview layer
    // Consider if this belongs here or should be managed separately
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill // Adjust gravity as needed
        return layer
    }

    override init() {
        super.init()
        // Initial status check
        authorizationStatusSubject.send(AVCaptureDevice.authorizationStatus(for: .video))
        // Configure session asynchronously
        sessionQueue.async {
            self.configureSession()
        }
    }

    // MARK: - Configuration

    private func configureSession() {
        guard authorizationStatusSubject.value == .authorized else {
            print("CameraService: Configuration skipped, not authorized.")
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720 // Choose appropriate preset

        // Input Device (Default to Front Camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front), // Use .front for exercise tracking
              let input = try? AVCaptureDeviceInput(device: videoDevice) else {
            errorSubject.send(CameraError.setupFailed("Could not create video device input."))
            session.commitConfiguration()
            return
        }
        guard session.canAddInput(input) else {
            errorSubject.send(CameraError.setupFailed("Could not add video device input to session."))
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        self.videoDeviceInput = input

        // Video Output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.ptchampion.cameraservice.samplebufferqueue", qos: .userInitiated))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        guard session.canAddOutput(videoOutput) else {
            errorSubject.send(CameraError.setupFailed("Could not add video data output to session."))
            session.commitConfiguration()
            return
        }
        session.addOutput(videoOutput)

        // Set output orientation based on current interface orientation
        updateOutputOrientation()

        session.commitConfiguration()
        print("CameraService: Session configured successfully.")
    }

    // MARK: - Permissions

    func requestCameraPermission() {
        sessionQueue.async {
            let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if currentStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.authorizationStatusSubject.send(granted ? .authorized : .denied)
                        if granted {
                            self?.sessionQueue.async { self?.configureSession() }
                        } else {
                             self?.errorSubject.send(CameraError.permissionDenied)
                        }
                    }
                }
            } else if currentStatus == .denied || currentStatus == .restricted {
                DispatchQueue.main.async {
                    self.errorSubject.send(CameraError.permissionDenied)
                }
            } else if currentStatus == .authorized {
                 // Already authorized, ensure session is configured if needed
                 if self.session.inputs.isEmpty {
                     self.configureSession()
                 }
            }
        }
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async {
            guard self.authorizationStatusSubject.value == .authorized else {
                print("CameraService: Cannot start session, not authorized.")
                self.requestCameraPermission() // Prompt if not determined
                return
            }
            guard !self.session.isRunning else {
                print("CameraService: Session already running.")
                return
            }
            // Ensure orientation is correct before starting
            self.updateOutputOrientation()
            self.session.startRunning()
            print("CameraService: Session started.")
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else {
                print("CameraService: Session already stopped.")
                return
            }
            self.session.stopRunning()
            print("CameraService: Session stopped.")
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Forward the sample buffer to the publisher
        frameSubject.send(sampleBuffer)
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("CameraService: Dropped frame")
    }

    // MARK: - Orientation Helper

    private func updateOutputOrientation() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        // Get current interface orientation (requires running on main thread)
        DispatchQueue.main.async {
            let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
            let videoOrientation: AVCaptureVideoOrientation

            switch interfaceOrientation {
            case .portrait: videoOrientation = .portrait
            case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
            case .landscapeLeft: videoOrientation = .landscapeLeft
            case .landscapeRight: videoOrientation = .landscapeRight
            default: videoOrientation = .portrait
            }

             self.sessionQueue.async { // Switch back to session queue to set orientation
                 if connection.isVideoOrientationSupported {
                     connection.videoOrientation = videoOrientation
                 }
                 // Mirror front camera video
                 if self.videoDeviceInput?.device.position == .front,
                    connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                 }
             }
        }
    }

    // MARK: - Deinitialization
    deinit {
        stopSession()
        print("CameraService deinitialized.")
    }
} 