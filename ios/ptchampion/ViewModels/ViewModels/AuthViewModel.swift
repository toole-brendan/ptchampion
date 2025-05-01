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
        print("AuthViewModel: login() called with email=\(email)") // DEBUG
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            print("AuthViewModel: Starting network login task") // DEBUG
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

    // Add this new function after the loginAsDeveloper function
    func testLoginDirect(email: String, password: String) {
        print("TEST DIRECT LOGIN: Starting with \(email)")
        isLoading = true
        errorMessage = nil
        
        // Create the request object - same as in the async version
        let loginRequest = LoginRequest(username: email, password: password)
        
        // Dispatch to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("TEST DIRECT LOGIN: Background thread started")
            
            guard let self = self else {
                print("TEST DIRECT LOGIN: Self was deallocated")
                return
            }
            
            // Force direct network request using URLSession
            let url = URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                // Encode request
                let jsonData = try JSONEncoder().encode(loginRequest)
                request.httpBody = jsonData
                print("TEST DIRECT LOGIN: Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
                
                // Send request synchronously (still in background thread)
                let semaphore = DispatchSemaphore(value: 0)
                var responseData: Data?
                var responseError: Error?
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    responseData = data
                    responseError = error
                    print("TEST DIRECT LOGIN: Network callback received")
                    if let httpResponse = response as? HTTPURLResponse {
                        print("TEST DIRECT LOGIN: Status code: \(httpResponse.statusCode)")
                    }
                    semaphore.signal()
                }
                
                print("TEST DIRECT LOGIN: Starting network request")
                task.resume()
                
                // Wait for response with timeout
                let timeoutResult = semaphore.wait(timeout: .now() + 10.0)
                
                if timeoutResult == .timedOut {
                    print("TEST DIRECT LOGIN: Network request timed out after 10 seconds")
                    DispatchQueue.main.async {
                        self.errorMessage = "Login request timed out"
                        self.isLoading = false
                    }
                    return
                }
                
                if let error = responseError {
                    print("TEST DIRECT LOGIN: Network error: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                
                guard let data = responseData else {
                    print("TEST DIRECT LOGIN: No data received")
                    DispatchQueue.main.async {
                        self.errorMessage = "No data received from server"
                        self.isLoading = false
                    }
                    return
                }
                
                print("TEST DIRECT LOGIN: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                
                // Parse the JSON response
                do {
                    // Try to decode the response as a dictionary first
                    if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("TEST DIRECT LOGIN: Raw JSON: \(jsonDict)")
                        
                        // Extract the token
                        if let accessToken = jsonDict["access_token"] as? String {
                            print("TEST DIRECT LOGIN: Successfully extracted access_token")
                            
                            // Get user ID from the user dictionary
                            if let userDict = jsonDict["user"] as? [String: Any],
                               let userId = userDict["id"] as? Int {
                                
                                print("TEST DIRECT LOGIN: Extracted user ID: \(userId)")
                                
                                // Update UI and save token on main thread
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    
                                    // First update isAuthenticated state - do this first!
                                    self.isAuthenticated = true
                                    print("TEST DIRECT LOGIN: Set isAuthenticated = true")
                                    
                                    // Save token to keychain
                                    do {
                                        try self.keychainService.saveToken(accessToken)
                                        print("TEST DIRECT LOGIN: Token saved to keychain")
                                        
                                        // Create a User object
                                        let displayName = userDict["displayName"] as? String
                                        let username = userDict["username"] as? String
                                        
                                        // Create a User model object
                                        let user = User(
                                            id: String(userId), // Convert Int to String
                                            email: username ?? "unknown",
                                            firstName: displayName,
                                            lastName: nil,
                                            profilePictureUrl: userDict["profilePictureUrl"] as? String
                                        )
                                        
                                        // Update view model state
                                        self.currentUser = user
                                        self.isLoading = false
                                        self.errorMessage = nil
                                        print("TEST DIRECT LOGIN: Authentication state updated, isAuthenticated = true")
                                    } catch {
                                        print("TEST DIRECT LOGIN: Failed to save token: \(error)")
                                        self.errorMessage = "Failed to save login credentials: \(error.localizedDescription)"
                                        self.isLoading = false
                                    }
                                }
                                return
                            }
                        }
                    }
                    
                    // If we get here, we couldn't parse the token or user properly
                    DispatchQueue.main.async {
                        self.errorMessage = "Could not process login response properly"
                        self.isLoading = false
                    }
                } catch {
                    print("TEST DIRECT LOGIN: JSON parsing error: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Response parsing error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
                
            } catch {
                print("TEST DIRECT LOGIN: JSON encoding error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Request encoding error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// Placeholder User model - move to Models/
// struct User: Identifiable, Codable {
//     let id: String // Or Int depending on your backend
//     let email: String
//     let firstName: String?
//     let lastName: String?
// } 