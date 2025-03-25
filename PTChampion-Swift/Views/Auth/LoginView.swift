import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func login(authManager: AuthManager) {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both username and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        APIClient.shared.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] user in
                self?.isLoading = false
                authManager.isAuthenticated = true
                authManager.currentUser = user
            })
            .store(in: &cancellables)
    }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showingRegistration = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and welcome message
                    VStack(spacing: 15) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                        
                        Text("PT Champion")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Elevate your fitness training to new heights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    
                    // Login form
                    VStack(spacing: 20) {
                        PTTextField(
                            title: "Username",
                            placeholder: "Enter your username",
                            text: $viewModel.username
                        )
                        
                        PTTextField(
                            title: "Password",
                            placeholder: "Enter your password",
                            text: $viewModel.password,
                            isSecure: true
                        )
                        
                        // Error message if any
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, -5)
                        }
                        
                        // Login button
                        Button(action: {
                            viewModel.login(authManager: authManager)
                        }) {
                            Text("Sign In")
                                .font(.headline)
                        }
                        .ptStyle(.primary, isLoading: viewModel.isLoading)
                        .padding(.top, 10)
                        
                        // Registration link
                        Button(action: {
                            showingRegistration = true
                        }) {
                            Text("Don't have an account? Register")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .ptStyle(.outline)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showingRegistration) {
                RegisterView()
                    .environmentObject(authManager)
            }
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}