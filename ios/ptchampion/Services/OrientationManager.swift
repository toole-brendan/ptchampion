import Foundation
import UIKit
import Combine
import AVFoundation

/// Centralized orientation management service
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    @Published var interfaceOrientation: UIInterfaceOrientation = .portrait
    @Published var isLandscape: Bool = false
    @Published var orientationAngle: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let orientationSubject = PassthroughSubject<UIDeviceOrientation, Never>()
    
    // Debounced orientation publisher to avoid rapid changes
    var debouncedOrientationPublisher: AnyPublisher<UIDeviceOrientation, Never> {
        orientationSubject
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private init() {
        setupOrientationMonitoring()
    }
    
    private func setupOrientationMonitoring() {
        // Monitor device orientation changes
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .filter { $0.isValidInterfaceOrientation || $0 == .faceUp || $0 == .faceDown }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orientation in
                self?.handleOrientationChange(orientation)
            }
            .store(in: &cancellables)
        
        // Monitor interface orientation changes (more reliable for UI)
        NotificationCenter.default.publisher(for: UIApplication.didChangeStatusBarOrientationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateInterfaceOrientation()
            }
            .store(in: &cancellables)
        
        // Initial setup
        updateCurrentState()
    }
    
    private func handleOrientationChange(_ orientation: UIDeviceOrientation) {
        // Filter out invalid orientations
        guard orientation.isValidInterfaceOrientation else {
            return
        }
        
        currentOrientation = orientation
        updateInterfaceOrientation()
        updateDerivedProperties()
        
        // Send to debounced publisher
        orientationSubject.send(orientation)
        
        print("OrientationManager: Device orientation changed to \(orientation.debugDescription)")
    }
    
    private func updateInterfaceOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        interfaceOrientation = windowScene.interfaceOrientation
        updateDerivedProperties()
    }
    
    private func updateDerivedProperties() {
        isLandscape = interfaceOrientation.isLandscape
        orientationAngle = angleForOrientation(interfaceOrientation)
    }
    
    private func updateCurrentState() {
        currentOrientation = UIDevice.current.orientation
        updateInterfaceOrientation()
    }
    
    private func angleForOrientation(_ orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        default:
            return 0
        }
    }
    
    // Convert interface orientation to AVCaptureVideoOrientation
    func videoOrientation(for interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
    
    // Convert interface orientation to UIImage.Orientation for MediaPipe
    // FIXED: Adjusted mapping for correct MediaPipe orientation handling
    func imageOrientation(for interfaceOrientation: UIInterfaceOrientation) -> UIImage.Orientation {
        // For front camera (selfie mode), the mapping is:
        // The image from the camera is always captured in landscape right orientation
        // We need to tell MediaPipe how to rotate it to match the current interface orientation
        
        switch interfaceOrientation {
        case .portrait:
            // Camera is rotated 90° clockwise from portrait
            return .leftMirrored  // Changed from .right to handle front camera mirroring
        case .portraitUpsideDown:
            // Camera is rotated 90° counter-clockwise from portrait upside down
            return .rightMirrored  // Changed from .left to handle front camera mirroring
        case .landscapeLeft:
            // Camera matches landscape left (home button on left)
            return .upMirrored  // Changed from .up to handle front camera mirroring
        case .landscapeRight:
            // Camera is 180° from landscape right
            return .downMirrored  // Changed from .down to handle front camera mirroring
        default:
            return .leftMirrored
        }
    }
    
    // Convert interface orientation to UIImage.Orientation for back camera
    func imageOrientationBackCamera(for interfaceOrientation: UIInterfaceOrientation) -> UIImage.Orientation {
        switch interfaceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
    
    // Transform normalized coordinates based on orientation
    // NOTE: This should NOT be used for MediaPipe coordinates as they are already transformed
    func transformNormalizedPoint(_ point: CGPoint, for orientation: UIInterfaceOrientation) -> CGPoint {
        var x = point.x
        var y = point.y
        
        switch orientation {
        case .landscapeLeft:
            let temp = x
            x = 1 - y
            y = temp
        case .landscapeRight:
            let temp = x
            x = y
            y = 1 - temp
        case .portraitUpsideDown:
            x = 1 - x
            y = 1 - y
        case .portrait:
            // No transformation needed
            break
        default:
            // Default to portrait
            break
        }
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Extensions

extension UIDeviceOrientation {
    var debugDescription: String {
        switch self {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Portrait Upside Down"
        case .landscapeLeft: return "Landscape Left"
        case .landscapeRight: return "Landscape Right"
        case .faceUp: return "Face Up"
        case .faceDown: return "Face Down"
        default: return "Unknown"
        }
    }
}

extension UIInterfaceOrientation {
    var debugDescription: String {
        switch self {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Portrait Upside Down"
        case .landscapeLeft: return "Landscape Left"
        case .landscapeRight: return "Landscape Right"
        default: return "Unknown"
        }
    }
}
