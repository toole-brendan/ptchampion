import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var isShowingLogin = true
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack {
                // Logo and title
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                    
                    Text("PT Champion")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your fitness evaluation companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Authentication form
                VStack(spacing: 20) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
                    Button(action: handleAuth) {
                        Text(isShowingLogin ? "Login" : "Register")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    .disabled(authViewModel.isLoading)
                    .overlay(
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    )
                }
                .padding(.horizontal)
                
                // Toggle between login and register
                Button(action: {
                    withAnimation {
                        isShowingLogin.toggle()
                        username = ""
                        password = ""
                    }
                }) {
                    Text(isShowingLogin ? "Don't have an account? Register" : "Already have an account? Login")
                        .font(.callout)
                        .foregroundColor(.accentColor)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func handleAuth() {
        if isShowingLogin {
            authViewModel.login(username: username, password: password)
        } else {
            authViewModel.register(username: username, password: password)
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}