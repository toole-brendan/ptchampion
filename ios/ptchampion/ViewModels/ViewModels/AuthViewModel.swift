import Foundation
import Combine

@MainActor // Ensure UI updates happen on the main thread
class AuthViewModel: ObservableObject {

    // Services will be injected
    private let authService: AuthServiceProtocol
    private let keychainService: KeychainServiceProtocol
    // TODO: Add UserService for fetching profile if needed

    @Published var isAuthenticated: Bool = false // Tracks if user is logged in
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil // For registration success
    @Published var currentUser: User? = nil // Populated after successful login

    private var cancellables = Set<AnyCancellable>()

    // Initialization with dependency injection
    init(authService: AuthServiceProtocol = AuthService(), // Use default implementation
         keychainService: KeychainServiceProtocol = KeychainService()) { // Use default implementation
        self.authService = authService
        self.keychainService = keychainService
        checkInitialAuthenticationState()
    }

    func checkInitialAuthenticationState() {
        Task {
            do {
                // Check if a token exists without assigning it if not needed
                if (try keychainService.loadToken()) != nil {
                    print("AuthViewModel: Found token in keychain.")
                    // Optional: Add a step here to validate the token against the backend
                    // If valid:
                    self.isAuthenticated = true
                    // TODO: Fetch user profile using the token
                    // self.currentUser = try await userService.getCurrentUserProfile()
                    // Mock user for now if profile fetch not implemented
                    self.currentUser = User(id: "loaded-user-id", email: "user@example.com", firstName: "Loaded", lastName: "User", profilePictureUrl: nil)
                    print("AuthViewModel: User authenticated from stored token.")
                } else {
                    print("AuthViewModel: No token found in keychain.")
                    self.isAuthenticated = false
                }
            } catch {
                print("AuthViewModel: Failed to load token from keychain: \(error.localizedDescription)")
                // Handle error appropriately, maybe set an error message
                self.isAuthenticated = false
                self.errorMessage = "Failed to check login status."
            }
        }
    }

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                // Use 'username' label as expected by LoginRequest initializer
                let loginRequest = LoginRequest(username: email, password: password)
                let authResponse = try await authService.login(credentials: loginRequest)

                print("AuthViewModel: Login successful, received token.")
                try keychainService.saveToken(authResponse.token)
                self.isAuthenticated = true
                self.isLoading = false
                // TODO: Fetch user profile after login
                // self.currentUser = try await userService.getCurrentUserProfile(token: authResponse.token)
                // Mock user for now
                self.currentUser = User(id: "logged-in-id", email: email, firstName: "Logged", lastName: "In", profilePictureUrl: nil)
                print("AuthViewModel: User logged in and token saved.")

            } catch let error as APIErrorResponse { // Catch specific backend error
                print("AuthViewModel: Login failed with API error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isAuthenticated = false
                self.isLoading = false
            } catch let error as APIError { // Catch generic API client error
                 print("AuthViewModel: Login failed with API client error: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription
                 self.isAuthenticated = false
                 self.isLoading = false
            } catch {
                print("AuthViewModel: Login failed with unexpected error: \(error.localizedDescription)")
                self.errorMessage = "An unexpected error occurred during login."
                self.isAuthenticated = false
                self.isLoading = false
            }
        }
    }

    func register(username: String, password: String, displayName: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                // Create request using the expected properties
                let registrationRequest = RegistrationRequest(
                    username: username,
                    password: password,
                    displayName: displayName,
                    profilePictureUrl: nil, // Set to nil or provide default/optional value
                    location: nil // Set to nil or provide default/optional value
                )
                try await authService.register(userInfo: registrationRequest)

                print("AuthViewModel: Registration successful.")
                self.isLoading = false
                // Set a success message or navigate to login
                self.successMessage = "Registration successful! Please log in."

            } catch let error as APIErrorResponse {
                print("AuthViewModel: Registration failed with API error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            } catch let error as APIError {
                 print("AuthViewModel: Registration failed with API client error: \(error.localizedDescription)")
                 self.errorMessage = error.localizedDescription
                 self.isLoading = false
            } catch {
                print("AuthViewModel: Registration failed with unexpected error: \(error.localizedDescription)")
                self.errorMessage = "An unexpected error occurred during registration."
                self.isLoading = false
            }
        }
    }

    func logout() {
        Task {
            do {
                try keychainService.deleteToken()
                self.isAuthenticated = false
                self.currentUser = nil
                print("AuthViewModel: User logged out and token deleted.")
            } catch {
                print("AuthViewModel: Failed to delete token during logout: \(error.localizedDescription)")
                // Even if token deletion fails, proceed with logging out the user state
                self.isAuthenticated = false
                self.currentUser = nil
                self.errorMessage = "Could not fully log out. Please try again."
            }
        }
    }

    // MARK: - Developer Mode Functions
    
    /// Bypasses the normal authentication flow for development purposes
    func loginAsDeveloper() {
        print("AuthViewModel: Bypassing authentication flow for development")
        self.isAuthenticated = true
        self.currentUser = User(
            id: "dev-123",
            email: "dev@example.com",
            firstName: "Developer",
            lastName: "User",
            profilePictureUrl: nil
        )
        self.errorMessage = nil
        print("AuthViewModel: Developer login successful without token")
    }
}

// Placeholder User model - move to Models/
// struct User: Identifiable, Codable {
//     let id: String // Or Int depending on your backend
//     let email: String
//     let firstName: String?
//     let lastName: String?
// } 