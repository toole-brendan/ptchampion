import SwiftUI
import AVFoundation

/// A SwiftUI view that displays the video feed from an AVCaptureSession.
struct CameraPreviewView: UIViewRepresentable {
    /// The AVCaptureSession providing the video feed.
    let session: AVCaptureSession
    /// The camera service to inform about preview layer changes
    let cameraService: CameraServiceProtocol

    /// Creates the underlying UIView (the preview layer's view).
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black // Set background color

        // Create the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill // Fill the view
        
        // Remove fixed orientation (will be set dynamically):
        // previewLayer.connection?.videoOrientation = .portrait
        
        // Set initial orientation based on device orientation
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            let deviceOrientation = UIDevice.current.orientation
            switch deviceOrientation {
            case .landscapeLeft:  connection.videoOrientation = .landscapeRight // Reversed due to camera orientation
            case .landscapeRight: connection.videoOrientation = .landscapeLeft  // Reversed due to camera orientation
            case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
            default: connection.videoOrientation = .portrait
            }
        }
        
        // Register the preview layer with the camera service
        cameraService.attachPreviewLayer(previewLayer)

        // Add the layer to the view's layer hierarchy
        view.layer.addSublayer(previewLayer)

        // Store the layer in the context coordinator for later layout updates
        context.coordinator.previewLayer = previewLayer

        // Layout the preview layer initially
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    /// Updates the UIView when SwiftUI state changes (not typically needed for basic preview).
    func updateUIView(_ uiView: UIView, context: Context) {
        // Ensure the preview layer's frame tracks the view's bounds during layout changes
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    /// Creates a Coordinator to manage state or delegates if needed.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Coordinator class to hold references (like the preview layer).
    class Coordinator: NSObject {
        var parent: CameraPreviewView
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
    }
}

// Optional: Add a preview for CameraPreviewView itself
#Preview(traits: .sizeThatFitsLayout) {
    // Create a dummy session for preview purposes (won't show live feed)
    let dummySession = AVCaptureSession()
    let dummyService = CameraService()
    // You could potentially add a dummy input/output to make it look like a camera is active

    return CameraPreviewView(session: dummySession, cameraService: dummyService)
        .frame(width: 300, height: 500)
        .background(Color.gray)
} 