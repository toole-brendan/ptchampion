// ios/ptchampion/Views/Utility/CameraPreviewView.swift

import SwiftUI
import AVFoundation
import UIKit

/// A SwiftUI view that displays the video feed from an AVCaptureSession with dynamic orientation support.
struct CameraPreviewView: UIViewRepresentable {
    /// The AVCaptureSession providing the video feed.
    let session: AVCaptureSession
    /// The camera service to inform about preview layer changes
    let cameraService: CameraServiceProtocol

    /// Creates the underlying UIView with orientation-aware preview layer.
    func makeUIView(context: Context) -> CameraPreviewLayerView {
        let view = CameraPreviewLayerView()
        view.backgroundColor = .black
        
        // Create the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        // Set initial orientation
        view.updateOrientation(previewLayer: previewLayer)
        
        // Register the preview layer with camera service
        cameraService.attachPreviewLayer(previewLayer)
        
        // Add the layer to view
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        
        return view
    }
    
    /// Updates the UIView when SwiftUI state changes.
    func updateUIView(_ uiView: CameraPreviewLayerView, context: Context) {
        // Update frame and orientation
        DispatchQueue.main.async {
            uiView.previewLayer?.frame = uiView.bounds
            if let layer = uiView.previewLayer {
                uiView.updateOrientation(previewLayer: layer)
            }
        }
    }
    
    /// Custom UIView subclass to handle orientation changes
    class CameraPreviewLayerView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?
        private let orientationManager = OrientationManager.shared
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Update preview layer frame when view layout changes
            previewLayer?.frame = bounds
            // Update orientation when layout changes
            if let layer = previewLayer {
                updateOrientation(previewLayer: layer)
            }
        }
        
        func updateOrientation(previewLayer: AVCaptureVideoPreviewLayer) {
            guard let connection = previewLayer.connection,
                  connection.isVideoOrientationSupported else { return }
            
            // Use OrientationManager for consistent orientation handling
            let interfaceOrientation = orientationManager.interfaceOrientation
            let videoOrientation = orientationManager.videoOrientation(for: interfaceOrientation)
            
            // Only update if orientation actually changed
            if connection.videoOrientation != videoOrientation {
                print("DEBUG: [CameraPreviewView] Updating preview orientation to: \(videoOrientation.rawValue)")
                connection.videoOrientation = videoOrientation
            }
        }
    }
}

// Optional: Add a preview for CameraPreviewView itself
#Preview(traits: .sizeThatFitsLayout) {
    // Create a dummy session for preview purposes (won't show live feed)
    let dummySession = AVCaptureSession()
    let dummyService = CameraService()
    
    return CameraPreviewView(session: dummySession, cameraService: dummyService)
        .frame(width: 300, height: 500)
        .background(Color.gray)
} 