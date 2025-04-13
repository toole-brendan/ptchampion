import SwiftUI
import Combine

class RegisterViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func register(authManager: AuthManager, completion: @escaping (Bool) -> Void) {
        // Validate input
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both username and password"
            completion(false)
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            completion(false)
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        APIClient.shared.register(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                if case .failure(let error) = completionResult {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }, receiveValue: { [weak self] user in
                self?.isLoading = false
                authManager.isAuthenticated = true
                authManager.currentUser = user
                completion(true)
            })
            .store(in: &cancellables)
    }
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Register for PT Champion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)
            
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            TextField("Username", text: $username)
                 .autocapitalization(.none)
                 .padding()
                 .background(Color(.secondarySystemBackground))
                 .cornerRadius(8)
            
            SecureField("Password (min 6 chars)", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if authManager.isLoading {
                ProgressView()
            } else {
                Button("Register") {
                    Task {
                        let details = RegisterRequest(username: username, email: email, password: password)
                        await authManager.register(details: details)
                        // AuthManager will set isAuthenticated, triggering App view change
                    }
                }
                .buttonStyle(PTButtonStyle(style: .primary, size: .large))
                .disabled(!isFormValid)
            }
            
            if let error = authManager.authError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Already have an account? Login") {
                // Pop this view to go back to LoginView
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.bottom)
        }
        .padding()
        .navigationTitle("Register") // Set title for the navigation bar
        .navigationBarBackButtonHidden(true) // Hide default back button if using custom
        .navigationBarItems(leading: Button(action: { presentationMode.wrappedValue.dismiss() }) { 
             Image(systemName: "chevron.left")
             Text("Login") 
         })
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for preview context
             RegisterView().environmentObject(AuthManager()) // Provide dummy
        }
    }
}