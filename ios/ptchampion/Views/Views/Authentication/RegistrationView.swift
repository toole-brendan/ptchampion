import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss // To dismiss the view if needed

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""

    // Form validation state
    @State private var passwordMismatch = false

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty && password == confirmPassword
    }

    var body: some View {
        VStack(spacing: 15) {
            Text("Create Account")
                .headingStyle()
                .padding(.bottom)

            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.givenName)
                .submitLabel(.next)

            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.familyName)
                .submitLabel(.next)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .submitLabel(.next)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
                .submitLabel(.next)
                .onChange(of: password) { _ in validatePasswords() }

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
                .submitLabel(.done)
                .onChange(of: confirmPassword) { _ in validatePasswords() }

            if passwordMismatch {
                Text("Passwords do not match.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }

            if let successMessage = viewModel.successMessage {
                 Text(successMessage)
                     .foregroundColor(.green)
                     .font(.caption)
                     .padding(.top, 5)
            }

            if viewModel.isLoading {
                 ProgressView()
                     .padding(.vertical, 10)
            } else {
                Button("Register") {
                    if validatePasswords() {
                        viewModel.register(email: email,
                                           password: password,
                                           firstName: firstName,
                                           lastName: lastName)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isFormValid)
                .padding(.top)
            }

            // Button to go back (useful if presented modally or for clarity)
            // If using NavigationStack, the back button is usually automatic
            // Button("Already have an account? Log In") {
            //     dismiss()
            // }
            // .padding(.top)
            // .font(.footnote)
            // .foregroundColor(Color.tacticalGray)

            Spacer()
        }
        .padding(AppConstants.globalPadding)
        .background(Color.tacticalCream.ignoresSafeArea())
        // Set navigation title if needed, e.g., .navigationTitle("Register")
        // .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
             hideKeyboard()
        }
        // Clear messages when view appears or fields change significantly
        .onAppear { clearMessages() }
        .onChange(of: email) { _ in clearMessages() }
        .onChange(of: password) { _ in clearMessages() }
        // Add alert for registration errors
        .alert("Registration Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil } // Clear error on dismiss
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })

    }

    private func validatePasswords() -> Bool {
        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
            passwordMismatch = true
            return false
        } else {
            passwordMismatch = false
            return true
        }
    }

    private func clearMessages() {
         viewModel.errorMessage = nil
         viewModel.successMessage = nil
    }
}

#Preview {
    // Needs NavigationStack for preview if using NavigationLink navigation
    NavigationStack {
        RegistrationView()
            .environmentObject(AuthViewModel())
    }
} 