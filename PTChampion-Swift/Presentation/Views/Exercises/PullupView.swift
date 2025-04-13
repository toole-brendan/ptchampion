import SwiftUI
import Combine

struct PullupView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = PullupViewModel()
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    Text("Unable to load pull-up exercise data.")
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
            trailing: Button(action: {
                viewModel.toggleFullscreen()
            }) {
                Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .opacity(viewModel.isFullscreen ? 0 : 1)
        )
        .onAppear {
            viewModel.loadExercise()
        }
    }
}

class PullupViewModel: ObservableObject {
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
                if let pullupExercise = exercises.first(where: { $0.type == .pullup }) {
                    self?.exercise = pullupExercise
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
struct PullupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PullupView()
                .environmentObject(AuthManager())
        }
    }
}