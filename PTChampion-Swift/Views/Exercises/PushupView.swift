import SwiftUI
import Combine

struct PushupView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = PushupViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDetectionOptions = false
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading exercise...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            } else if let exercise = viewModel.exercise {
                ExerciseViewContainer(exercise: exercise)
                    .environmentObject(authManager)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Exercise not found")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unable to load pushup exercise data.")
                        .foregroundColor(.secondary)
                    
                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .ptStyle(.primary)
                    .padding(.top, 20)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .navigationBarBackButtonHidden(viewModel.isFullscreen)
        .navigationBarItems(
            leading: Button(action: {
                if viewModel.isFullscreen {
                    viewModel.exitFullscreen()
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                Text("Back")
            }
            .opacity(viewModel.isFullscreen ? 0 : 1),
            trailing: HStack(spacing: 16) {
                // New detection options button
                Button(action: {
                    showingDetectionOptions = true
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .bold))
                }
                .opacity(viewModel.isFullscreen ? 0 : 1)
                
                // Existing fullscreen button
                Button(action: {
                    viewModel.toggleFullscreen()
                }) {
                    Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .opacity(viewModel.isFullscreen ? 0 : 1)
            }
        )
        .onAppear {
            viewModel.loadExercise()
        }
        .actionSheet(isPresented: $showingDetectionOptions) {
            ActionSheet(
                title: Text("Pose Detection Options"),
                message: Text("Select the pose detection technology to use"),
                buttons: [
                    .default(Text("Toggle MediaPipe Detection")) {
                        togglePoseDetection()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // Toggle between Vision and MediaPipe pose detection
    func togglePoseDetection() {
        // Switch between Vision and MediaPipe
        let viewModel = ExerciseViewModel()
        let usingMediaPipe = viewModel.toggleMediaPipe()
        print("Using MediaPipe for pose detection: \(usingMediaPipe)")
    }
}

class PushupViewModel: ObservableObject {
    @Published var exercise: Exercise?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isFullscreen = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadExercise() {
        isLoading = true
        
        APIClient.shared.getExercises()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] exercises in
                if let pushupExercise = exercises.first(where: { $0.type == .pushup }) {
                    self?.exercise = pushupExercise
                }
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    func toggleFullscreen() {
        withAnimation {
            isFullscreen.toggle()
        }
    }
    
    func exitFullscreen() {
        withAnimation {
            isFullscreen = false
        }
    }
}

// Preview
struct PushupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PushupView()
                .environmentObject(AuthManager())
        }
    }
}
