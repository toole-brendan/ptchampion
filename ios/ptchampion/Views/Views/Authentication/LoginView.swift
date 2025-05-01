import SwiftUI

struct LoginView: View {
    // Use EnvironmentObject assuming it's provided by a parent view (e.g., App)
    @EnvironmentObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showDevOptions = false

    var body: some View {
        // NavigationStack needed for NavigationLink to RegistrationView
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                // TODO: Add App Logo here based on style guide
                // Placeholder for LogoIcon component
                Image(systemName: "shield.lefthalf.filled") // Replace with actual logo/icon
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48) // Style guide suggests 32-48px height max
                    .foregroundColor(Color(red: 0.749, green: 0.635, blue: 0.302)) // brassGold
                    .padding(.bottom)
                    // Allow opening dev options by tapping logo 5 times
                    .onTapGesture(count: 5) {
                        showDevOptions = true
                    }

                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .submitLabel(.next)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .submitLabel(.done)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.vertical, 10)
                } else {
                    Button("Log In") {
                        // viewModel.login(email: email, password: password)
                        viewModel.testLoginDirect(email: email, password: password)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(8)
                    .disabled(email.isEmpty || password.isEmpty) // Basic validation
                    
                    // Add dev bypass button
                    if showDevOptions {
                        Button("DEV: Bypass Login") {
                            // Use the direct developer bypass instead of mock credentials
                            viewModel.loginAsDeveloper()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .font(.footnote)
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                }

                NavigationLink("Don't have an account? Register") {
                    RegistrationView()
                        // RegistrationView will also need the environmentObject
                        // It implicitly receives it if provided to LoginView's parent
                }
                .padding(.top)
                .font(.footnote)
                .foregroundColor(Color.gray)

                // Add debug info display
                Text("Auth state: \(viewModel.isAuthenticated ? "Authenticated" : "Not authenticated")")
                    .padding(.top)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(0.7)

                Spacer()
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.957, green: 0.945, blue: 0.902).ignoresSafeArea()) // tacticalCream
            // Dismiss keyboard on tap outside
            .onTapGesture {
                 hideKeyboard()
            }
            // Add alert for login errors
            .alert("Login Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil } // Clear error on dismiss
            }, message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            })
        }
    }
}

// Helper to dismiss keyboard
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    // Provide a mock AuthViewModel for the preview
    LoginView()
        .environmentObject(AuthViewModel())
} 