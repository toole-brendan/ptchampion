import SwiftUI
import AVFoundation

struct CameraPermissionRequestView: View {
    var onRequestPermission: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "camera.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("Camera Permission")
                .font(.title)
                .fontWeight(.bold)
            
            Text("PT Champion needs your camera to track exercise form and rep count. No video is stored or uploaded.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("The app will use computer vision to analyze your movements in real-time and provide feedback on your form.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("Not Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SwiftUI.Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: onRequestPermission) {
                    Text("Allow Camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        SwiftUI.Color.gray.opacity(0.3).ignoresSafeArea()
        CameraPermissionRequestView(
            onRequestPermission: {},
            onCancel: {}
        )
    }
} 