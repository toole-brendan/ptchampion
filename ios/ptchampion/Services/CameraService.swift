import Foundation
import AVFoundation
import Combine
import UIKit // Needed for orientation

#if targetEnvironment(simulator)
private let kRunningInSimulator = true
#else
private let kRunningInSimulator = false
#endif

class CameraService: NSObject, CameraServiceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {

    let session = AVCaptureSession()
    private let sessionQueueKey = DispatchSpecificKey<Bool>()
    private let sessionQueue = DispatchQueue(label: "com.ptchampion.cameraservice.sessionqueue", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var currentPreviewLayer: AVCaptureVideoPreviewLayer? = nil  // Renamed to avoid conflict
    
    // Orientation management
    private let orientationManager = OrientationManager.shared
    private var cancellables = Set<AnyCancellable>()

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
        // Set the queue-specific key for identifying the session queue
        sessionQueue.setSpecific(key: sessionQueueKey, value: true)
        // Initial status check
        authorizationStatusSubject.send(AVCaptureDevice.authorizationStatus(for: .video))
        
        // Subscribe to orientation changes
        setupOrientationObserver()
        
        // Configure session asynchronously
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    private func setupOrientationObserver() {
        orientationManager.debouncedOrientationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOutputOrientation()
            }
            .store(in: &cancellables)
    }

    // MARK: - Configuration

    private func configureSession() {
        guard authorizationStatusSubject.value == .authorized else {
            print("CameraService: Configuration skipped, not authorized.")
            return
        }

        session.beginConfiguration()
        
        if kRunningInSimulator {
            print("CameraService: Running in Simulator – skipping real camera configuration.")
            session.commitConfiguration()
            return
        }
        
        session.sessionPreset = .hd1280x720 // Choose appropriate preset

        // Input Device (Default to Rear Camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), // Use .back for exercise tracking
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
            
            // Make sure we don't have a delegate set before starting a new session
            if self.session.isRunning {
                self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
                self.session.stopRunning()
            }
            
            // Ensure orientation is correct before starting
            self.updateOutputOrientation()
            self.session.startRunning()
            
            // Set the delegate after the session is running
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.ptchampion.cameraservice.samplebufferqueue", qos: .userInitiated))
            
            print("CameraService: Session started.")
        }
    }

    func stopSession(sync: Bool = false) {
        // --------  synchronous path (used only from deinit)  --------
        if sync {
            if session.isRunning {
                // First, clear the video output delegate to prevent further callbacks
                videoOutput.setSampleBufferDelegate(nil, queue: nil)
                
                // execute on the session queue if we are not already on it
                if DispatchQueue.getSpecific(key: sessionQueueKey) == nil {
                    sessionQueue.sync { session.stopRunning() }
                } else {
                    session.stopRunning()
                }
                print("CameraService: Session stopped (sync).")
            } else {
                print("CameraService: Session already stopped.")
            }
            return                                      // ⚑  nothing else
        }

        // --------  normal asynchronous path  --------
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else {
                print("CameraService: Session already stopped.")
                return
            }
            
            // Clear the video output delegate to prevent further callbacks
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            
            // Small delay to ensure callbacks are stopped before stopping the session
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sessionQueue.async {
                    if self.session.isRunning {
                        self.session.stopRunning()
                        print("CameraService: Session stopped with delegate cleared.")
                    }
                }
            }
        }
    }

    // ✅ add this wrapper to satisfy the protocol
    func stopSession() {
        stopSession(sync: false)
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

    // Change from private to public to allow external calls when device orientation changes
    public func updateOutputOrientation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Use OrientationManager for consistent orientation handling
            let interfaceOrientation = self.orientationManager.interfaceOrientation
            let videoOrientation = self.orientationManager.videoOrientation(for: interfaceOrientation)
            
            print("DEBUG: [CameraService] Updating orientation to: \(interfaceOrientation) -> \(videoOrientation)")
            
            self.sessionQueue.async {
                // Update video output connection
                if let connection = self.videoOutput.connection(with: .video),
                   connection.isVideoOrientationSupported {
                    
                    // Only update if orientation actually changed
                    if connection.videoOrientation != videoOrientation {
                        connection.videoOrientation = videoOrientation
                        print("DEBUG: [CameraService] Video output orientation updated to: \(videoOrientation.rawValue)")
                    }
                    
                    // Mirror front camera
                    if self.videoDeviceInput?.device.position == .front,
                       connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    } else {
                        connection.isVideoMirrored = false
                    }
                }
                
                // Update preview layer connection
                DispatchQueue.main.async {
                    if let previewConnection = self.currentPreviewLayer?.connection,
                       previewConnection.isVideoOrientationSupported,
                       previewConnection.videoOrientation != videoOrientation {
                        previewConnection.videoOrientation = videoOrientation
                        print("DEBUG: [CameraService] Updated preview layer orientation to: \(videoOrientation.rawValue)")
                    }
                }
            }
        }
    }
    
    // New method to attach preview layer
    public func attachPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.currentPreviewLayer = layer
    }

    // MARK: - Camera Control
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self, let currentInput = self.videoDeviceInput else { return }
            
            let currentPosition = currentInput.device.position
            let targetPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
            
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: targetPosition),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
                
                // Update camera orientation and mirroring
                DispatchQueue.main.async {
                    self.updateOutputOrientation()
                }
            } else {
                // If failed, re-add old input to avoid broken session
                if self.session.canAddInput(currentInput) {
                    self.session.addInput(currentInput)
                }
            }
            
            self.session.commitConfiguration()
            print("CameraService: Switched to \(targetPosition == .back ? "back" : "front") camera")
        }
    }

    // MARK: - Deinitialization
    deinit {
        stopSession(sync: true)          // now safe – does not form weak refs
        cancellables.forEach { $0.cancel() }
        print("CameraService deinitialized.")
    }
} 