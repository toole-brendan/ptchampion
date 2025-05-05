import SwiftUI
import UIKit
import PTDesignSystem
import Introspect

// Font extensions - Replace with AppTheme.GeneratedTypography
extension Font {
    // These methods are deprecated and should use AppTheme.GeneratedTypography instead
    static func bebasNeueBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.heading(size: size)
    }
    
    static func montserratBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.bodyBold(size: size)
    }
    
    static func montserratSemiBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.bodySemibold(size: size)
    }
    
    static func montserratRegular(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.body(size: size)
    }
}

// Custom SwiftUI TextField that properly handles keyboard
struct LoginTextField: View {
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
                    .cornerRadius(AppTheme.GeneratedRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                            .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                    )
                    .introspectTextField { tf in
                        tf.inputAssistantItem.leadingBarButtonGroups  = []
                        tf.inputAssistantItem.trailingBarButtonGroups = []
                    }
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(AppTheme.GeneratedRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.input)
                            .stroke(AppTheme.GeneratedColors.brassGold, lineWidth: 1)
                    )
                    .introspectTextField { tf in
                        tf.inputAssistantItem.leadingBarButtonGroups  = []
                        tf.inputAssistantItem.trailingBarButtonGroups = []
                    }
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
    @State private var didLogBodyOnce = false
    
    // Add explicit navigation feedback from Comprehensive Solution
    @State private var isTransitioning = false
    
    // Diagnostic state
    @State private var authDebugText: String = "No auth state change detected yet"
    
    // Local form fields
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
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
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
                        } else {
                            // Fallback to text if image is missing
                            PTLabel("PT CHAMPION", style: .heading)
                                .foregroundColor(AppTheme.GeneratedColors.brassGold)
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
                    PTLabel("Welcome Back", style: .heading)
                        .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                        .padding(.top, 10)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        PTTextField("Email", text: $email)
                        
                        PTTextField("Password", text: $password, isSecure: true)
                        
                        // Login Button
                        if auth.isLoading {
                            Button(action: {}) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.GeneratedColors.cream))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(AppTheme.GeneratedRadius.button)
                            .disabled(true)
                        } else {
                            PTButton("Log In") {
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
                            }
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                        
                        // Debug buttons only in dev mode
                        if showDevOptions {
                            PTButton("Check Auth State", style: .secondary) {
                                authDebugText = "Current auth state: \(auth.authState.isAuthenticated ? "authenticated" : "unauthenticated")"
                                print("DEBUG: Current auth state from LoginView diagnostic button: \(auth.authState)")
                            }
                            .padding(.top, 8)
                            
                            PTLabel(authDebugText, style: .body)
                                .foregroundColor(AppTheme.GeneratedColors.textPrimary)
                                .padding(.top, 8)
                        
                            // Dev bypass buttons
                            PTButton("DEV: Bypass Login", style: .secondary) {
                                auth.loginAsDeveloper()
                            }
                            .padding(.top, 8)
                            
                            PTButton("DEBUG: Force Auth State", style: .primary) {
                                auth.debugForceAuthenticated()
                            }
                            .padding(.top, 8)
                        }
                        
                        // Register Link (Add NavigationLink later if needed)
                        HStack {
                            PTLabel("Don't have an account?", style: .caption)
                                .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                            
                            AnyView(
                                NavigationLink(destination: RegistrationView()) {
                                    PTLabel("Register", style: .caption)
                                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                }
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let errorMessage = auth.errorMessage {
                        PTLabel(errorMessage, style: .caption)
                            .foregroundColor(AppTheme.GeneratedColors.error)
                            .padding(.top, 16)
                    }
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
                .padding(.bottom, keyboardHeight)
            }
            .background(
                AppTheme.GeneratedColors.cream
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
        .environment(\.colorScheme, .light)
} 