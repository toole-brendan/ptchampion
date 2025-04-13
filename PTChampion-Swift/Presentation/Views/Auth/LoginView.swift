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
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    
    // State to control navigation to RegisterView
    @State private var navigateToRegister = false
    
    var body: some View {
        NavigationView { // Embed in NavigationView for title and navigation link
            VStack(spacing: 20) {
                Text("PT Champion Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                if authManager.isLoading {
                    ProgressView()
                } else {
                    Button("Login") {
                        Task {
                            let credentials = LoginRequest(email: email, password: password)
                            await authManager.login(credentials: credentials)
                        }
                    }
                    .buttonStyle(PTButtonStyle(style: .primary, size: .large))
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                if let error = authManager.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Link to Register View
                 NavigationLink(destination: RegisterView().environmentObject(authManager), isActive: $navigateToRegister) { EmptyView() }
                 Button("Don't have an account? Register") {
                     navigateToRegister = true
                 }
                 .padding(.bottom)

            }
            .padding()
            .navigationBarHidden(true) // Hide the default navigation bar if desired
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthManager()) // Provide dummy for preview
    }
}