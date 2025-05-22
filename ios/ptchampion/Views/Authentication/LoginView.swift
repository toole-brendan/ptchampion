import SwiftUI
import UIKit
import PTDesignSystem
import SwiftUIIntrospect
import AuthenticationServices // Import for Sign in with Apple
import CryptoKit // Import for SHA256 hashing
import GoogleSignIn // Import for Google Sign-In

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
    
    // Futura fonts
    static func futuraMedium(size: CGFloat) -> Font {
        return Font.custom("Jost-500-Medium", size: size, relativeTo: .body)
    }
    
    static func futuraRegular(size: CGFloat) -> Font {
        return Font.custom("Jost-400-Book", size: size, relativeTo: .body)
    }
    
    static func futuraBold(size: CGFloat) -> Font {
        return Font.custom("Jost-700-Bold", size: size, relativeTo: .body)
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
                                if let namedImage = UIImage(named: "pt_champion_logo_2") {
                                    return namedImage
                                }
                                return nil
                            }()
                            
                            if let logo = logoImage {
                                Image(uiImage: logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                            } else {
                                // Fallback to text if image is missing
                                PTLabel("PT CHAMPION", style: .heading)
                                    .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    .frame(width: 200, height: 200)
                                    .onAppear {
                                        print("WARNING: Logo file not found in asset catalog. Please ensure pt_champion_logo_2.png is added to Assets.xcassets.")
                                    }
                            }
                        }
                        .padding(.top, 40)
                        // Allow opening dev options by tapping logo 5 times
                        .onTapGesture(count: 5) {
                            showDevOptions = true
                        }
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            PTLabel("Welcome", style: .heading)
                                .foregroundColor(AppTheme.GeneratedColors.commandBlack)
                            
                            // Add separator line to match web version
                            Rectangle()
                                .fill(AppTheme.GeneratedColors.brassGold)
                                .frame(width: 64, height: 2)
                        }
                        .padding(.top, 10)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            VStack(spacing: 4) {
                                PTTextField(
                                    "",
                                    text: $email,
                                    label: "EMAIL",
                                    icon: Image(systemName: "envelope"),
                                    keyboardType: .emailAddress
                                )
                            }
                            
                            VStack(spacing: 4) {
                                // Password label and Forgot password in same row
                                PTTextField(
                                    "",
                                    text: $password,
                                    label: "PASSWORD",
                                    isSecure: true,
                                    icon: Image(systemName: "lock")
                                )
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        // Handle forgot password
                                    }) {
                                        Text("Forgot password?")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                    }
                                    .padding(.trailing, 4)
                                    .padding(.top, 0)
                                }
                            }
                            
                            // Login Button
                            if auth.isLoading {
                                // Use a typed local variable to resolve ambiguity
                                let coreButtonStyle: PTButton.ButtonStyle = .primary
                                PTButton("LOG IN", style: coreButtonStyle, isLoading: true) {
                                    // No action when loading
                                }
                                .disabled(true)
                            } else {
                                // Use a typed local variable to resolve ambiguity
                                let coreButtonStyle: PTButton.ButtonStyle = .primary
                                PTButton("LOG IN", style: coreButtonStyle) {
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
                            
                            // Register Link - Fixed to use direct navigation
                            HStack {
                                Text("Don't have an account?")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                                
                                Button(action: {
                                    // Set navigating to register screen using NavigationState
                                    navigationState.navigateTo(.register)
                                }) {
                                    Text("Sign up")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(AppTheme.GeneratedColors.brassGold)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Separator
                            HStack {
                                Rectangle()
                                    .fill(AppTheme.GeneratedColors.tacticalGray.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("or continue with")
                                    .font(.system(.caption))
                                    .foregroundColor(AppTheme.GeneratedColors.tacticalGray)
                                    .padding(.horizontal, 8)
                                
                                Rectangle()
                                    .fill(AppTheme.GeneratedColors.tacticalGray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 16)
                            
                            // Sign in with Apple button
                            SignInWithAppleButton(.signIn, onRequest: configureAppleRequest, onCompletion: handleAppleSignInCompletion)
                                .frame(height: 50)
                                .cornerRadius(8)
                            
                            // Sign in with Google button
                            Button(action: signInWithGoogle) {
                                HStack {
                                    Spacer()
                                    
                                    // Use the logo3x asset
                                    Image("logo3x")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .padding(.trailing, 8)
                                    
                                    Text("Sign in with Google")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(Color.black.opacity(0.87))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .accessibilityLabel("Sign in with Google")
                            
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
    
    // MARK: - Social Sign In Methods
    
    // Configure Apple Sign In Request
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        // Request user name and email
        request.requestedScopes = [.fullName, .email]
        // Generate a random nonce to include in the request (for token validation)
        let nonce = generateNonce()
        // Save the nonce for token validation later
        UserDefaults.standard.set(nonce, forKey: "appleSignInNonce")
        // Set the SHA256 hashed nonce on the request
        request.nonce = sha256(nonce)
    }
    
    // Handle Apple Sign In Completion
    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResult):
            if let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential {
                // Retrieve the identity token
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    print("Error: Unable to retrieve Apple identity token")
                    auth.errorMessage = "Unable to complete Apple sign-in. Please try again."
                    return
                }
                
                // Get the nonce we sent with the request
                let nonce = UserDefaults.standard.string(forKey: "appleSignInNonce") ?? ""
                
                // Here you can verify the nonce in the identityToken if your backend requires it
                // The identityToken is a JWT containing a 'nonce' claim that should match the SHA256 hash of our original nonce
                // For extra security, you could send both the identityToken and original nonce to your backend
                
                // Extract user info (only available on first sign-in)
                let userId = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                print("Successfully signed in with Apple: \(userId)")
                if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                    print("Name: \(givenName) \(familyName)")
                }
                print("Email: \(email ?? "Not provided")")
                
                // Call backend via AuthViewModel to complete sign-in
                Task {
                    await auth.loginWithApple(identityToken: identityToken)
                }
            }
        case .failure(let error):
            print("Apple Sign-In failed: \(error.localizedDescription)")
            auth.errorMessage = "Apple Sign-In failed. Please try again."
        }
    }
    
    // Sign in with Google
    private func signInWithGoogle() {
        print("Initiating Google Sign In")
        
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_IOS_CLIENT_ID") as? String ?? 
              ProcessInfo.processInfo.environment["GOOGLE_IOS_CLIENT_ID"] else {
            print("Google ClientID not found")
            auth.errorMessage = "Google Sign-In configuration error"
            return
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        
        // Get the current view controller to present Google Sign-In
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            auth.errorMessage = "Unable to present Google Sign-In"
            return
        }
        
        // Present Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.auth.errorMessage = "Google Sign-In failed. Please try again."
                }
                return
            }
            
            guard let signInResult = signInResult else { return }
            let user = signInResult.user
            
            // Get ID token from Google user
            guard let idToken = user.idToken?.tokenString else {
                print("Error: No Google ID token")
                Task { @MainActor in
                    self.auth.errorMessage = "Google Sign-In failed: No ID token received"
                }
                return
            }
            
            // Send the token to backend via AuthViewModel
            Task {
                await self.auth.loginWithGoogle(idToken: idToken)
            }
        }
    }
    
    // Helper function to generate a secure random nonce
    private func generateNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        guard status == errSecSuccess else {
            // Fall back to a less secure random generation if SecRandomCopyBytes fails
            print("Warning: SecRandomCopyBytes failed. Using less secure random generation.")
            var nonce = ""
            let allowedChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
            for _ in 0..<length {
                let randomIndex = Int.random(in: 0..<allowedChars.count)
                let randomChar = allowedChars[allowedChars.index(allowedChars.startIndex, offsetBy: randomIndex)]
                nonce.append(randomChar)
            }
            return nonce
        }
        
        // Convert random bytes to base64 string and remove characters that could cause issues
        return Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
            .description
    }
    
    // Helper function to create a SHA256 hash of the nonce
    private func sha256(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else {
            return input // Return input as fallback if encoding fails
        }
        
        let hashedData = SHA256.hash(data: data)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        
        return hashString
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

// MARK: - Helper Views

/// Google G logo implementation with official colors
struct GoogleGLogo: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                // Main 'G' shape
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                
                // Top red portion
                Path { path in
                    let width = size
                    let height = size
                    path.move(to: CGPoint(x: width * 0.25, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
                    path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.4))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.91, green: 0.27, blue: 0.21)) // Google red
                
                // Right yellow portion
                Path { path in
                    let width = size
                    let height = size
                    path.move(to: CGPoint(x: width * 0.75, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.95, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.95, y: height * 0.75))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.75))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.98, green: 0.73, blue: 0.01)) // Google yellow
                
                // Bottom green portion
                Path { path in
                    let width = size
                    let height = size
                    path.move(to: CGPoint(x: width * 0.25, y: height * 0.6))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.6))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.75))
                    path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.75))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.0, green: 0.59, blue: 0.53)) // Google green
                
                // Left blue portion
                Path { path in
                    let width = size
                    let height = size
                    path.move(to: CGPoint(x: width * 0.05, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.25))
                    path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.75))
                    path.addLine(to: CGPoint(x: width * 0.05, y: height * 0.75))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.01, green: 0.44, blue: 0.87)) // Google blue
                
                // White center
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .offset(x: size * 0.075, y: 0)
            }
        }
    }
}

// MARK: - Helper Extensions

// Helper extension to list available image assets
extension UIImage {
    static var assetNames: [String] {
        var names = [String]()
        
        // Get the main bundle
        if let bundle = Bundle(identifier: Bundle.main.bundleIdentifier!) {
            // Get the path to the asset catalog
            if let path = bundle.path(forResource: "Assets", ofType: "car") {
                // Get the names of all the asset catalogs
                if let enumerator = FileManager.default.enumerator(atPath: path) {
                    for case let fileName as String in enumerator {
                        if fileName.hasSuffix(".png") || fileName.hasSuffix(".jpg") {
                            names.append(fileName)
                        }
                    }
                }
            }
        }
        
        return names
    }
} 