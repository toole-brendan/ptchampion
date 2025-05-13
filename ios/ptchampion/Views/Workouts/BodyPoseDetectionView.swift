import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreMedia

// Helper extension for reliable string conversion
extension VNHumanBodyPoseObservation.JointName {
    /// Bridged textual identifier of the Vision joint key
    var asString: String { String(describing: rawValue) }
}

struct BodyPoseDetectionView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var poseDetector = PoseDetectorService()
    
    @State private var detectedBody: DetectedBody? = nil
    @State private var permissionDenied = false
    @State private var showPermissionRequest = true
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // Full-screen camera background
            CameraPreviewView(session: cameraService.session)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay pose detection
            if let body = detectedBody {
                PoseOverlayView(detectedBody: body)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Pre-permission request view
            if showPermissionRequest {
                ZStack {
                    ThemeColor.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                    CameraPermissionRequestView(
                        onRequestPermission: {
                            showPermissionRequest = false
                            cameraService.requestCameraPermission()
                        },
                        onCancel: {
                            showPermissionRequest = false
                            permissionDenied = true
                        }
                    )
                }
                .transition(.opacity)
                .zIndex(2)
            }
            
            // Permission denied view
            if permissionDenied {
                permissionDeniedView()
                    .zIndex(1)
            }
            
            // Debug info overlay (only in development)
            #if DEBUG
            VStack {
                Spacer()
                Text("Body detected: \(detectedBody != nil ? "Yes" : "No")")
                    .padding(6)
                    .background(ThemeColor.black.opacity(0.7)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
            }
            #endif
        }
        .onAppear {
            setupSubscriptions()
            setupOrientationNotification()
            // Permission is now requested via the custom permission view
        }
        .onDisappear {
            cancellables.forEach { $0.cancel() }
            cameraService.stopSession()
            // Remove orientation notification observer
            NotificationCenter.default.removeObserver(
                self,
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        }
    }
    
    private func setupOrientationNotification() {
        // Register for orientation change notifications
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Update camera orientation when device rotates
            // Use a slight delay to ensure the interface has updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.cameraService.updateOutputOrientation()
            }
        }
    }
    
    private func setupSubscriptions() {
        // Subscribe to camera authorization status
        cameraService.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { status in
                permissionDenied = status == .denied || status == .restricted
                if status == .authorized {
                    cameraService.startSession()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to camera frames and pipe them to pose detector
        cameraService.framePublisher
            .sink { [weak poseDetector] (frame: CMSampleBuffer) in
                poseDetector?.processFrame(frame)
            }
            .store(in: &cancellables)
        
        // Subscribe to detected body poses
        poseDetector.detectedBodyPublisher
            .receive(on: DispatchQueue.main)
            .sink { body in
                detectedBody = body
                if let body = body {
                    logJointCoordinates(body)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to errors
        cameraService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Camera error: \(error.localizedDescription)")
            }
            .store(in: &cancellables)
        
        poseDetector.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Pose detection error: \(error.localizedDescription)")
            }
            .store(in: &cancellables)
    }
    
    private func logJointCoordinates(_ body: DetectedBody) {
        #if DEBUG
        guard body.confidence > 0.7 else { return }
        
        print("==== High-Confidence Body Detected ====")
        
        // Sort the dictionary by the textual key
        let sortedPoints = body.points.sorted { $0.key.asString < $1.key.asString }
        
        // Log every joint
        for (jointKey, point) in sortedPoints {
            print("\(jointKey.asString): (\(point.location.x), \(point.location.y))  "
                  + "confidence: \(point.confidence)")
        }
        #endif
    }
    
    private func permissionDeniedView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 50)
                .foregroundColor(.white)
            
            Text("Camera Access Denied")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("PT Champion needs camera access to detect body poses. Please enable camera access in your device settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .frame(minWidth: 200)
                    .padding()
                    .background(ThemeColor.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColor.black.opacity(0.8)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    BodyPoseDetectionView()
} 