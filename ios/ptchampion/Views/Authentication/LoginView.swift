import SwiftUI
import UIKit

// Font extensions
extension Font {
    static func bebasNeueBold(size: CGFloat) -> Font {
        return Font.custom("BebasNeue-Bold", size: size)
    }
    
    static func montserratBold(size: CGFloat) -> Font {
        return Font.custom("Montserrat-Bold", size: size)
    }
    
    static func montserratSemiBold(size: CGFloat) -> Font {
        return Font.custom("Montserrat-SemiBold", size: size)
    }
    
    static func montserratRegular(size: CGFloat) -> Font {
        return Font.custom("Montserrat-Regular", size: size)
    }
}

// Import AppTheme symbols directly in file scope for LoginView
extension LoginView {
    enum AppTheme {
        enum Colors {
            static let brassGold = Color("BrassGold")
            static let cream = Color("Cream")
            static let commandBlack = Color("CommandBlack")
            static let tacticalGray = Color("TacticalGray")
        }
    }
}

// Use the same AppTheme extension for PTTextField
extension PTTextField {
    typealias AppTheme = LoginView.AppTheme
}

// Custom SwiftUI TextField that properly handles keyboard
struct PTTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        ZStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.brassGold, lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.brassGold, lineWidth: 1)
                    )
            }
        }
    }
}

// Login View with keyboard avoidance
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Restore EnvironmentObject
    @State private var keyboardHeight: CGFloat = 0
    @State private var showDevOptions = false
    
    // Add explicit navigation feedback from Comprehensive Solution
    @State private var isTransitioning = false
    
    var body: some View {
        // DEBUG: Check if LoginView body is executing
        let _ = print("DEBUG: LoginView body executing.")
        
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image(uiImage: UIImage(named: "pt_champion_logo") ?? 
                          (Bundle.main.path(forResource: "pt_champion_logo", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) ?? 
                          UIImage(systemName: "shield.lefthalf.filled")!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(AppTheme.Colors.brassGold)
                        .padding(.top, 60)
                        // Allow opening dev options by tapping logo 5 times
                        .onTapGesture(count: 5) {
                            showDevOptions = true
                        }
                    
                    // Welcome Text
                    Text("Welcome Back")
                        .font(Font.bebasNeueBold(size: 36))
                        .foregroundColor(AppTheme.Colors.commandBlack)
                        .padding(.top, 10)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        PTTextField(
                            placeholder: "Email",
                            text: $authViewModel.username,
                            keyboardType: .emailAddress
                        )
                        
                        PTTextField(
                            placeholder: "Password",
                            text: $authViewModel.password,
                            isSecure: true
                        )
                        
                        // Login Button
                        Button(action: {
                            authViewModel.errorMessage = nil // Clear error before login
                            authViewModel.login()
                            // Remove fallback logic - handled by improved AuthViewModel
                        }) {
                            Text("Log In")
                                .font(Font.montserratBold(size: 16))
                                .foregroundColor(AppTheme.Colors.cream)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.Colors.brassGold)
                                .cornerRadius(8)
                        }
                        .disabled(authViewModel.isLoading)
                        
                        // Progress view during loading
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.brassGold))
                                .padding(.top, 8)
                        }
                        
                        // Dev bypass button
                        if showDevOptions {
                            Button(action: { authViewModel.loginAsDeveloper() }) {
                                Text("DEV: Bypass Login")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                            
                            Button(action: { authViewModel.debugForceAuthenticated() }) {
                                Text("DEBUG: Force Auth State")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Register Link (Add NavigationLink later if needed)
                        HStack {
                            Text("Don't have an account?")
                                .font(Font.montserratRegular(size: 14))
                                .foregroundColor(AppTheme.Colors.tacticalGray)
                            Button(action: { /* Navigate to registration */ }) {
                                Text("Register")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.brassGold)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(Font.montserratRegular(size: 14))
                            .foregroundColor(Color.red)
                            .padding(.top, 16)
                    }
                    
                    // Debug info (Optional)
                    // Text("Auth state: \\(authViewModel.authState == .authenticated ? \"Authenticated\" : \"Not authenticated\")")
                    //     .font(Font.montserratRegular(size: 12))
                    //     .foregroundColor(AppTheme.Colors.tacticalGray)
                    //     .padding(.top, 24)
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
                .padding(.bottom, keyboardHeight)
            }
            .background(
                LoginView.AppTheme.Colors.cream // Use defined theme color
                    .ignoresSafeArea(.all)
            )
            .onTapGesture {
                hideKeyboard()
            }
            // --- Add onChange handler from Comprehensive Solution ---
            .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
                if newValue && !isTransitioning { // Check isTransitioning flag
                    isTransitioning = true
                    print("LoginView detected authentication state change: \(newValue)")
                    
                    // Explicitly post notification as backup
                    NotificationCenter.default.post(
                        name: Notification.Name("PTChampionAuthStateChanged"),
                        object: nil
                    )
                }
            }
             // --- Add onAppear handler from Comprehensive Solution ---
            .onAppear {
                 print("DEBUG: LoginView onAppear called.") // Add debug print
                 isTransitioning = false // Reset transitioning state
                // Force auth check on appear
                authViewModel.checkAuthentication()
                
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                        keyboardHeight = keyboardSize.height
                    }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
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
    LoginView()
        .environmentObject(AuthViewModel())
} 