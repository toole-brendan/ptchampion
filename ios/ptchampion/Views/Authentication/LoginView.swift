import SwiftUI
import UIKit
import PTDesignSystem
import SwiftUIIntrospect

// Font extensions have been migrated to use AppTheme.GeneratedTypography
// These are kept solely for backward compatibility and should be removed in future updates
extension Font {
    // These methods are deprecated and should use AppTheme.GeneratedTypography instead
    @available(*, deprecated, message: "Use AppTheme.GeneratedTypography.heading instead")
    static func bebasNeueBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.heading(size: size)
    }
    
    @available(*, deprecated, message: "Use AppTheme.GeneratedTypography.bodyBold instead")
    static func montserratBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.bodyBold(size: size)
    }
    
    @available(*, deprecated, message: "Use AppTheme.GeneratedTypography.bodySemibold instead")
    static func montserratSemiBold(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.bodySemibold(size: size)
    }
    
    @available(*, deprecated, message: "Use AppTheme.GeneratedTypography.body instead")
    static func montserratRegular(size: CGFloat) -> Font {
        return AppTheme.GeneratedTypography.body(size: size)
    }
}

// Login View with keyboard avoidance
struct LoginView: View {
    // Make sure we're using the shared AuthViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var navigationState: NavigationState
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
        NavigationView {  // Wrap in NavigationView to enable navigation
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo with fallback - use a more structured approach
                        Group {
                            let logoImage: UIImage? = {
                                if let namedImage = UIImage(named: "pt_champion_logo") {
                                    return namedImage
                                }
                                return nil
                            }()
                            
                            if let logo = logoImage {
                                Image(uiImage: logo)
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
                            FocusableTextField(
                                "Email",
                                text: $email,
                                keyboardType: .emailAddress,
                                icon: Image(systemName: "envelope")
                            )
                            
                            FocusableTextField(
                                "Password",
                                text: $password,
                                isSecure: true,
                                icon: Image(systemName: "lock")
                            )
                            
                            // Login Button
                            if auth.isLoading {
                                // Use a typed local variable to resolve ambiguity
                                let coreButtonStyle: PTButton.ButtonStyle = .primary
                                PTButton("Log In", style: coreButtonStyle, isLoading: true) {
                                    // No action when loading
                                }
                                .disabled(true)
                            } else {
                                // Use a typed local variable to resolve ambiguity
                                let coreButtonStyle: PTButton.ButtonStyle = .primary
                                PTButton("Log In", style: coreButtonStyle) {
                                    auth.errorMessage = nil // Clear error before login
                                    print("DEBUG: Login button tapped for email: \(email)")
                                    
                                    // Ensure we're using the async Task correctly
                                    Task {
                                        do {
                                            await auth.login(email: email, password: password)
                                            // Explicitly check and navigate after login attempt
                                            if auth.isAuthenticated && !isTransitioning {
                                                isTransitioning = true
                                                print("LoginView: Navigating to main post-login task.")
                                                navigationState.navigateTo(.main)
                                                // isTransitioning will be reset by onChange or onAppear if needed
                                                // but to be safe for this path:
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isTransitioning = false } 
                                            }
                                        } catch {
                                            print("Login error caught in view: \(error)")
                                        }
                                    }
                                }
                                .disabled(email.isEmpty || password.isEmpty)
                            }
                            
                            // Debug buttons only in dev mode
                            if showDevOptions {
                                // Add coreButtonStyle for the debug button
                                let coreButtonStyle: PTButton.ButtonStyle = .primary
                                let secondaryButtonStyle: PTButton.ButtonStyle = .secondary
                                PTButton("Check Auth State", style: secondaryButtonStyle) {
                                    authDebugText = "Current auth state: \(auth.isAuthenticated ? "authenticated" : "unauthenticated")"
                                    print("DEBUG: Current auth state from LoginView diagnostic button: \(auth.isAuthenticated)")
                                }
                                .padding(.top, 8)
                                .disabled(auth.isLoading)
                                
                                PTButton("DEV: Bypass Login", style: secondaryButtonStyle) {
                                    auth.loginAsDeveloper()
                                }
                                .padding(.top, 8)
                                
                                PTButton("DEBUG: Force Auth State", style: coreButtonStyle) {
                                    auth.debugForceAuthenticated()
                                }
                                .padding(.top, 8)
                            }
                            
                            // Register Link - Fixed to use direct navigation
                            HStack {
                                PTLabel("Don't have an account?", style: .caption)
                                    .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                                
                                Button(action: {
                                    // Set navigating to register screen using NavigationState
                                    navigationState.navigateTo(.register)
                                }) {
                                    PTLabel("Register", style: .caption)
                                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                }
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
                        
                        if !authDebugText.isEmpty {
                            Text(authDebugText)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top)
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
                .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
                    if isAuthenticated && !isTransitioning {
                        isTransitioning = true
                        // Delay navigation slightly to allow UI to settle if needed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("LoginView: Navigating to main due to auth change.")
                            navigationState.navigateTo(.main)
                            isTransitioning = false
                        }
                    }
                }
                .onAppear {
                    print("DEBUG: LoginView onAppear called with AuthViewModel instance: \(ObjectIdentifier(auth))")
                    isTransitioning = false // Reset transitioning state
                    
                    // For debugging, verify if auth is already authenticated on appear
                    if auth.isAuthenticated {
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
            }  // End GeometryReader
            .navigationBarHidden(true)  // Hide the navigation bar on the login screen
        }  // End NavigationView
    }
}

// Helper to dismiss keyboard - MOVED TO FILE SCOPE
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

// Preview - Ensure it's at file scope after all other definitions
#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .environmentObject(NavigationState()) // Added missing NavigationState for preview
        .environment(\.colorScheme, .light)
} 