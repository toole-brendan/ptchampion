import SwiftUI
import Combine

struct LoginView: View {
    // View model would handle the API calls
    @StateObject private var viewModel = LoginViewModel()
    
    // Form state
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isShowingPassword: Bool = false
    
    // Validation state
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                        
                        Text("PT Champion")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to track your fitness performance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 50)
                    
                    // Login form
                    VStack(spacing: 20) {
                        // Username field
                        PTTextField(
                            title: "Username",
                            placeholder: "Enter your username",
                            text: $username,
                            icon: "person.fill",
                            errorMessage: usernameError
                        )
                        
                        // Password field
                        PTTextField(
                            title: "Password",
                            placeholder: "Enter your password",
                            text: $password,
                            isSecure: true,
                            icon: "lock.fill",
                            errorMessage: passwordError
                        )
                        
                        // Error message (if login fails)
                        if let error = viewModel.error {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                        
                        // Sign in button
                        Button(action: signIn) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.0)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(PTButtonStyle(backgroundColor: .blue))
                        .disabled(viewModel.isLoading)
                        .padding(.top, 10)
                        
                        // Forgot password
                        Button("Forgot Password?") {
                            // Handle forgot password
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Register option
                    VStack(spacing: 5) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    
    // Sign in action
    private func signIn() {
        // Reset errors
        usernameError = nil
        passwordError = nil
        
        // Validate inputs
        var isValid = true
        
        if username.isEmpty {
            usernameError = "Username is required"
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        }
        
        // If validation passes, attempt to sign in
        if isValid {
            viewModel.login(username: username, password: password)
        }
    }
}

// View Model for Login
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func login(username: String, password: String) {
        isLoading = true
        error = nil
        
        let credentials = LoginCredentials(username: username, password: password)
        
        APIClient.shared.login(credentials: credentials)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    switch error {
                    case .unauthorized:
                        self?.error = "Invalid username or password"
                    default:
                        self?.error = "Login failed: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] user in
                self?.isAuthenticated = true
                // In a real app, we'd store the user info and authentication state
                print("User \(user.username) logged in successfully")
            })
            .store(in: &cancellables)
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

// Placeholder for RegisterView (to be implemented)
struct RegisterView: View {
    var body: some View {
        Text("Register Screen")
            .navigationTitle("Create Account")
    }
}