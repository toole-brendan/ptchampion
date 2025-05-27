import SwiftUI
import AVFoundation

// Add this debug view to test camera functionality independently
struct CameraDebugView: View {
    @StateObject private var cameraDebugger = CameraDebugger()
    
    var body: some View {
        ZStack {
            if cameraDebugger.isSessionConfigured {
                CameraDebugPreview(session: cameraDebugger.session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Configuring Camera...")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            if let error = cameraDebugger.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    )
            }
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Camera Debug Info")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Group {
                            Text("Session Running: \(cameraDebugger.session.isRunning ? "✅" : "❌")")
                            Text("Configured: \(cameraDebugger.isSessionConfigured ? "✅" : "❌")")
                            Text("Permission: \(cameraDebugger.permissionStatus)")
                            Text("Inputs: \(cameraDebugger.session.inputs.count)")
                            Text("Outputs: \(cameraDebugger.session.outputs.count)")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 20) {
                    Button("Restart Camera") {
                        cameraDebugger.restartCamera()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Stop Camera") {
                        cameraDebugger.stopSession()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraDebugger.checkAndSetupCamera()
        }
        .onDisappear {
            cameraDebugger.stopSession()
        }
        .navigationTitle("Camera Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Camera Debugger Class
class CameraDebugger: ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionConfigured = false
    @Published var permissionStatus = "Unknown"
    @Published var errorMessage: String?
    
    func checkAndSetupCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = "Authorized ✅"
            setupCamera()
        case .notDetermined:
            permissionStatus = "Not Determined"
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = granted ? "Authorized ✅" : "Denied ❌"
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.errorMessage = "Camera permission denied"
                    }
                }
            }
        case .denied:
            permissionStatus = "Denied ❌"
            errorMessage = "Camera permission denied. Please enable in Settings."
        case .restricted:
            permissionStatus = "Restricted ⚠️"
            errorMessage = "Camera access is restricted"
        @unknown default:
            permissionStatus = "Unknown"
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Clear existing inputs and outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Try to get the front camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            errorMessage = "No front camera available"
            session.commitConfiguration()
            return
        }
        
        do {
            // Create and add input
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                print("✅ Added camera input")
            } else {
                errorMessage = "Cannot add camera input"
            }
            
            // Create and add output
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                print("✅ Added video output")
            } else {
                errorMessage = "Cannot add video output"
            }
            
            session.sessionPreset = .high
            
        } catch {
            errorMessage = "Camera setup error: \(error.localizedDescription)"
            print("❌ Camera setup error: \(error)")
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.isSessionConfigured = true
            self.errorMessage = nil
        }
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                print("📷 Camera session started: \(self?.session.isRunning ?? false)")
            }
        }
    }
    
    func restartCamera() {
        stopSession()
        isSessionConfigured = false
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAndSetupCamera()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                DispatchQueue.main.async {
                    print("📷 Camera session stopped")
                }
            }
        }
    }
}

// Simple Camera Preview for debugging
struct CameraDebugPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        layer.frame = uiView.bounds
    }
}

// MARK: - Preview
struct CameraDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CameraDebugView()
        }
    }
} 