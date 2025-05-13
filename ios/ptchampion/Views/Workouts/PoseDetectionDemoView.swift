import SwiftUI

struct PoseDetectionDemoView: View {
    @State private var showPoseDetection = false
    @State private var isNavigating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.stand")
                .font(.system(size: 60)
                .foregroundColor(.blue)
            
            Text("Body Pose Detection")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This demo uses Apple's Vision framework to detect body poses in real-time using your device's camera.")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("The app will show 19 key body points and connections between them.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { isNavigating = true }) {
                Text("Start Body Pose Detection")
                    .fontWeight(.semibold)
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 30)
            
            Text("Note: This will use your front camera and requires a real device (not the simulator).")
                .caption()
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .fullScreenCover(isPresented: $isNavigating) {
            BodyPoseDetectionView()
        }
    }
}

#Preview {
    PoseDetectionDemoView()
} 