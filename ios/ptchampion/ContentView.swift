import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("PT Champion - iOS")
                    .font(.title)
                    .fontWeight(.bold)
                
                NavigationLink {
                    PoseDetectionDemoView()
                } label: {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                        Text("Try Body Pose Detection")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Add other app features/navigation here
            }
            .padding()
            .navigationTitle("PT Champion")
        }
    }
}

#Preview {
    ContentView()
} 