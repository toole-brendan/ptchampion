import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignUp = false
    
    var body: some View {
        VStack {
            Text("PT Champion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.top, 10)
            
            Button(action: {
                // Placeholder login action
                authViewModel.isAuthenticated = true
                authViewModel.currentUser = User(id: "test-id", email: email, firstName: "Test", lastName: "User", profilePictureUrl: nil)
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            Button(action: {
                showingSignUp = true
            }) {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
} 