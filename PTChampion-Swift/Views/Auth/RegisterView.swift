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
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Join PT Champion to track your physical training progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Registration form
                    VStack(spacing: 20) {
                        PTTextField(
                            title: "Username",
                            placeholder: "Choose a username",
                            text: $viewModel.username
                        )
                        
                        PTTextField(
                            title: "Password",
                            placeholder: "Choose a password",
                            text: $viewModel.password,
                            isSecure: true
                        )
                        
                        PTTextField(
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            text: $viewModel.confirmPassword,
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
                    }
                    
                    // Register button
                    Button(action: {
                        viewModel.register(authManager: authManager) { success in
                            if success {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Text("Create Account")
                            .font(.headline)
                    }
                    .ptStyle(.primary, isLoading: viewModel.isLoading)
                    .padding(.top, 10)
                    
                    // Already have account button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Already have an account? Sign In")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .ptStyle(.outline)
                }
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
            })
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

// Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthManager())
    }
}