import SwiftUI
import AVFoundation

/// A SwiftUI view that displays the video feed from an AVCaptureSession.
struct CameraPreviewView: UIViewRepresentable {
    /// The AVCaptureSession providing the video feed.
    let session: AVCaptureSession

    /// Creates the underlying UIView (the preview layer's view).
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black // Set background color

        // Create the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill // Fill the view
        previewLayer.connection?.videoOrientation = .portrait // Adjust if needed

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
    // You could potentially add a dummy input/output to make it look like a camera is active

    return CameraPreviewView(session: dummySession)
        .frame(width: 300, height: 500)
        .background(ThemeColor.gray)
} 