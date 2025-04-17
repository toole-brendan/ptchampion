import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("PT Champion - iOS")
        }
        .padding()
    }
}

#Preview {
    ContentView()
} 