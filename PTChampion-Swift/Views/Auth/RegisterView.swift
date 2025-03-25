import SwiftUI
import Combine

struct RegisterView: View {
    // View model
    @StateObject private var viewModel = RegisterViewModel()
    
    // Form state
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    // Validation state
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var emailError: String? = nil
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Title
                Text("Create Your Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Registration form
                VStack(spacing: 20) {
                    // Username
                    PTTextField(
                        title: "Username",
                        placeholder: "Enter a username",
                        text: $username,
                        icon: "person.fill",
                        errorMessage: usernameError
                    )
                    
                    // First name (optional)
                    PTTextField(
                        title: "First Name",
                        placeholder: "Enter your first name (optional)",
                        text: $firstName,
                        autocapitalization: .words,
                        icon: "person.text.rectangle.fill"
                    )
                    
                    // Last name (optional)
                    PTTextField(
                        title: "Last Name",
                        placeholder: "Enter your last name (optional)",
                        text: $lastName,
                        autocapitalization: .words,
                        icon: "person.text.rectangle.fill"
                    )
                    
                    // Email
                    PTTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress,
                        icon: "envelope.fill",
                        errorMessage: emailError
                    )
                    
                    // Password
                    PTTextField(
                        title: "Password",
                        placeholder: "Enter a password",
                        text: $password,
                        isSecure: true,
                        icon: "lock.fill",
                        errorMessage: passwordError
                    )
                    
                    // Confirm password
                    PTTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $confirmPassword,
                        isSecure: true,
                        icon: "lock.shield.fill",
                        errorMessage: confirmPasswordError
                    )
                    
                    // Error message (if registration fails)
                    if let error = viewModel.error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                    
                    // Register button
                    Button(action: register) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.0)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PTButtonStyle(backgroundColor: .blue))
                    .disabled(viewModel.isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                
                // Login option
                VStack(spacing: 5) {
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Sign In") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 20)
                
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.isRegistrationSuccessful) {
            Alert(
                title: Text("Account Created"),
                message: Text("Your account has been created successfully. You can now sign in."),
                dismissButton: .default(Text("Sign In")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Register action
    private func register() {
        // Reset errors
        usernameError = nil
        passwordError = nil
        confirmPasswordError = nil
        emailError = nil
        
        // Validate inputs
        var isValid = true
        
        if username.isEmpty {
            usernameError = "Username is required"
            isValid = false
        } else if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            isValid = false
        }
        
        if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }
        
        if !email.isEmpty {
            // Basic email validation
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                emailError = "Please enter a valid email"
                isValid = false
            }
        }
        
        // If validation passes, attempt to register
        if isValid {
            viewModel.register(
                username: username,
                password: password,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName,
                email: email.isEmpty ? nil : email
            )
        }
    }
}

// View Model for Registration
class RegisterViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var isRegistrationSuccessful = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func register(username: String, password: String, firstName: String?, lastName: String?, email: String?) {
        isLoading = true
        error = nil
        
        let credentials = RegisterCredentials(
            username: username,
            password: password,
            firstName: firstName,
            lastName: lastName,
            email: email
        )
        
        APIClient.shared.register(credentials: credentials)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    switch error {
                    case .httpError(409):
                        self?.error = "Username already exists"
                    default:
                        self?.error = "Registration failed: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] user in
                self?.isRegistrationSuccessful = true
                print("User \(user.username) registered successfully")
            })
            .store(in: &cancellables)
    }
}

// Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegisterView()
        }
    }
}