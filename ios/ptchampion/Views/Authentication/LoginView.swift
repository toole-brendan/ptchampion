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
    // Make sure we're using the shared AuthViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @State private var keyboardHeight: CGFloat = 0
    @State private var showDevOptions = false
    
    // Add explicit navigation feedback from Comprehensive Solution
    @State private var isTransitioning = false
    
    // Diagnostic state
    @State private var authDebugText: String = "No auth state change detected yet"
    
    // Local form fields
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        // Print LoginView's auth instance ID to verify it's the same one
        let _ = print("DEBUG: LoginView body with AuthViewModel instance: \(ObjectIdentifier(auth))")
        
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Logo with fallback
                    Group {
                        if UIImage(named: "pt_champion_logo") != nil {
                            Image("pt_champion_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(AppTheme.Colors.brassGold)
                        } else {
                            // Fallback to text if image is missing
                            Text("PT CHAMPION")
                                .font(Font.bebasNeueBold(size: 32))
                                .foregroundColor(AppTheme.Colors.brassGold)
                                .frame(width: 120, height: 120)
                                .onAppear {
                                    print("WARNING: Logo file not found in asset catalog. Please ensure pt_champion_logo.png is added to Assets.xcassets.")
                                }
                        }
                    }
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
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        PTTextField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        
                        // Login Button
                        Button(action: {
                            auth.errorMessage = nil // Clear error before login
                            print("DEBUG: Login button tapped for email: \(email)")
                            
                            // Ensure we're using the async Task correctly
                            Task {
                                do {
                                    await auth.login(email: email, password: password)
                                } catch {
                                    print("Login error caught in view: \(error)")
                                }
                            }
                        }) {
                            if auth.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.cream))
                            } else {
                                Text("Log In")
                                    .font(Font.montserratBold(size: 16))
                                    .foregroundColor(AppTheme.Colors.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(auth.isLoading ? Color.gray : AppTheme.Colors.brassGold)
                        .cornerRadius(8)
                        .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
                        
                        // Debug buttons only in dev mode
                        if showDevOptions {
                            Button(action: { 
                                authDebugText = "Current auth state: \(auth.authState.isAuthenticated ? "authenticated" : "unauthenticated")"
                                print("DEBUG: Current auth state from LoginView diagnostic button: \(auth.authState)")
                            }) {
                                Text("Check Auth State")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                            
                            Text(authDebugText)
                                .font(Font.montserratRegular(size: 14))
                                .foregroundColor(Color.black)
                                .padding(.top, 8)
                        
                            // Dev bypass buttons
                            Button(action: { auth.loginAsDeveloper() }) {
                                Text("DEV: Bypass Login")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                            
                            Button(action: { auth.debugForceAuthenticated() }) {
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
                            NavigationLink(destination: RegistrationView()) {
                                Text("Register")
                                    .font(Font.montserratSemiBold(size: 14))
                                    .foregroundColor(AppTheme.Colors.brassGold)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .font(Font.montserratRegular(size: 14))
                            .foregroundColor(Color.red)
                            .padding(.top, 16)
                    }
                    
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
            .onChange(of: auth.authState.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated && !isTransitioning {
                    isTransitioning = true
                    authDebugText = "Authentication state changed to: \(isAuthenticated)"
                    print("DEBUG: LoginView detected authentication state change to isAuthenticated=true")
                }
            }
            .onAppear {
                print("DEBUG: LoginView onAppear called with AuthViewModel instance: \(ObjectIdentifier(auth))")
                isTransitioning = false // Reset transitioning state
                
                // For debugging, verify if auth is already authenticated on appear
                if auth.authState.isAuthenticated {
                    print("⚠️ WARNING: LoginView appeared but auth is already authenticated!")
                }
                
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