import SwiftUI
import AVFoundation

// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession // Pass the session from the service/viewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false // We handle mirroring in CameraService
        view.layer.addSublayer(previewLayer)
        // Ensure the layer is accessible for layout updates
        view.layer.name = "CameraPreviewLayerContainer"
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the preview layer and update its frame
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }

    // Optional: Coordinator can handle delegate callbacks if needed
    // class Coordinator: NSObject { ... }
    // func makeCoordinator() -> Coordinator { Coordinator() }
} 