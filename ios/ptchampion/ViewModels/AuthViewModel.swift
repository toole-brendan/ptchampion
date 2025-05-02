import Foundation
import Combine
import SwiftUI

// Define authentication states
enum AuthState {
    case authenticated
    case unauthenticated
}

@MainActor // Ensure UI updates happen on the main thread
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var _isAuthenticatedInternal: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil // For registration success
    @Published var currentUser: User? = nil // Populated after successful login
    
    // User fields
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var userId: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("DEBUG: AuthViewModel init() called") // Add debug print
        // Check for existing token on startup
        checkAuthentication()
    }
    
    func checkAuthentication() {
        if let token = KeychainService.shared.getAccessToken(), !token.isEmpty,
           let userId = KeychainService.shared.getUserId() {
            self.userId = userId
            self.authState = .authenticated
            self._isAuthenticatedInternal = true
            print("AuthViewModel: User is authenticated with ID: \(userId)")
        } else {
            if KeychainService.shared.getAccessToken() != nil {
                KeychainService.shared.clearAllTokens()
            }
            self.authState = .unauthenticated
            self._isAuthenticatedInternal = false
            print("AuthViewModel: No valid token found in keychain.")
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Set username and password properties
        self.username = email
        self.password = password
        
        // Call the direct login method
        login()
    }
    
    func login() {
        print("AuthViewModel: Starting login process for \(username)")
        isLoading = true
        errorMessage = nil
        
        // Create request body
        let loginBody = [
            "username": username,
            "password": password
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: loginBody) else {
            self.errorMessage = "Error creating request"
            self.isLoading = false
            return
        }
        
        // API URL
        guard let url = URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("TEST DIRECT LOGIN: Starting with \(username)")
        print("TEST DIRECT LOGIN: Background thread started")
        print("TEST DIRECT LOGIN: Request body: \(String(data: jsonData, encoding: .utf8) ?? "Could not decode")")
        print("TEST DIRECT LOGIN: Starting network request")
        
        // Make API call
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // --- tryMap Logging START ---
                print("Login tryMap: Entered tryMap block.")
                
                print("Login tryMap: Checking response type...")
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Login tryMap: Failed to cast response to HTTPURLResponse. Response: \(response)")
                    throw URLError(.badServerResponse)
                }
                print("Login tryMap: Successfully cast response to HTTPURLResponse.")
                
                print("Login tryMap: Checking status code (\(httpResponse.statusCode))...")
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Login tryMap: Status code \(httpResponse.statusCode) is not OK.")
                    if let errorStr = String(data: data, encoding: .utf8) {
                        print("Login tryMap: Server error response body: \(errorStr)")
                    }
                    throw URLError(.badServerResponse)
                }
                print("Login tryMap: Status code is OK (\(httpResponse.statusCode)).")
                
                print("Login tryMap: Successfully processed, returning data.")
                // --- tryMap Logging END ---
                return data
            }
            .receive(on: DispatchQueue.main) // RESTORE: Ensure sink closures execute on main thread
            .sink(receiveCompletion: { [weak self] completion in
                // --- receiveCompletion Logging START ---
                print("Login Sink: Entered receiveCompletion block (Thread: \(Thread.current))") // Log entry unconditionally and thread
                self?.isLoading = false
                switch completion {
                case .finished:
                    print("Login Sink: Publisher finished successfully.")
                    // Do nothing more on success here, handled by receiveValue
                    break
                case .failure(let error):
                    self?.errorMessage = "Login failed: Processing error or network issue."
                    print("Login Sink: Publisher failed with error: \(error)")
                    if let urlError = error as? URLError {
                        print("Login Sink: URL Error Code: \(urlError.errorCode)")
                    }
                    print("Login Sink: Error Description: \(error.localizedDescription)")
                }
                // --- receiveCompletion Logging END ---
            }, receiveValue: { [weak self] data in
                // --- START Enhanced Logging --- 
                guard let self = self else { 
                    print("Login receiveValue: self is nil, cannot proceed.")
                    return 
                }
                print("Login receiveValue: Entered receiveValue block (Thread: \(Thread.current))") // Log entry and thread
                
                // Log raw data unconditionally
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("Login receiveValue: Raw response data string:\n---\n\(responseStr)\n---")
                } else {
                    print("Login receiveValue: Could not convert raw response data to UTF8 string.")
                }
                
                // --- END Enhanced Logging ---
                
                do {
                    print("Login receiveValue: Attempting JSON parsing...")
                    // Parse response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Login receiveValue: JSON parsing successful. Raw JSON: \(json)")
                        
                        // Extract access token - try different key formats that might be in the response
                        let possibleTokenKeys = ["access_token", "accessToken", "token", "jwt", "authToken"]
                        var accessToken: String? = nil
                        
                        // Try to find a token with any of the possible keys
                        for key in possibleTokenKeys {
                            if let token = json[key] as? String {
                                accessToken = token
                                print("Login receiveValue: Found token with key '\(key)': \(token)")
                                break
                            }
                        }
                        
                        if accessToken == nil {
                             print("Login receiveValue: No access token found using keys: \(possibleTokenKeys.joined(separator: ", "))")
                        }
                        
                        // Extract user info - try to be flexible with response format
                        var userId: String? = nil
                        var firstName: String? = nil
                        var lastName: String? = nil
                        var email: String? = nil
                        var profilePicUrl: String? = nil // Added profile pic url extraction
                        
                        print("Login receiveValue: Attempting to extract user info...")
                        // First try to extract from user object if present
                        if let userDict = json["user"] as? [String: Any] {
                            print("Login receiveValue: Found 'user' object in JSON: \(userDict)")
                            // Try to extract userId as either string or int
                            if let id = userDict["id"] as? String {
                                userId = id
                                print("Login receiveValue: Extracted userId (String) from user object: \(id)")
                            } else if let id = userDict["id"] as? Int {
                                userId = String(id)
                                print("Login receiveValue: Extracted userId (Int) from user object: \(id)")
                            } else {
                                print("Login receiveValue: Could not extract userId from user object.")
                            }
                            
                            // Extract other user fields from user object
                            email = userDict["username"] as? String ?? userDict["email"] as? String
                            print("Login receiveValue: Extracted email from user object: \(email ?? "nil")")
                            profilePicUrl = userDict["profile_picture_url"] as? String // Extract profile pic
                            print("Login receiveValue: Extracted profilePicUrl from user object: \(profilePicUrl ?? "nil")")
                            
                            // Try to extract name in different formats from user object
                            if let fullName = userDict["displayName"] as? String ?? userDict["display_name"] as? String {
                                let nameParts = fullName.components(separatedBy: " ")
                                firstName = nameParts.first ?? ""
                                lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : nil
                                print("Login receiveValue: Extracted name from displayName/display_name in user object: \(firstName ?? ""), \(lastName ?? "nil")")
                            } else {
                                firstName = userDict["firstName"] as? String ?? userDict["first_name"] as? String
                                lastName = userDict["lastName"] as? String ?? userDict["last_name"] as? String
                                print("Login receiveValue: Extracted name from firstName/lastName in user object: \(firstName ?? "nil"), \(lastName ?? "nil")")
                            }
                            // Default if names still nil
                            if firstName == nil { firstName = "User"; print("Login receiveValue: Defaulted firstName to 'User'") }
                            
                        } else {
                             print("Login receiveValue: No 'user' object found in JSON. Trying top-level keys...")
                            // Try to extract user info directly from response if no user object
                            if let id = json["userId"] as? String ?? json["user_id"] as? String {
                                userId = id
                                print("Login receiveValue: Extracted userId (String) from top-level: \(id)")
                            } else if let id = json["userId"] as? Int ?? json["user_id"] as? Int {
                                userId = String(id)
                                print("Login receiveValue: Extracted userId (Int) from top-level: \(id)")
                            } else if let id = json["id"] as? String { // Fallback to top-level 'id'
                                userId = id
                                print("Login receiveValue: Extracted userId (String) from top-level 'id': \(id)")
                            } else if let id = json["id"] as? Int {
                                userId = String(id)
                                print("Login receiveValue: Extracted userId (Int) from top-level 'id': \(id)")
                            } else {
                                print("Login receiveValue: Could not extract userId from top-level keys.")
                            }
                            
                            // Extract other fields directly
                            email = json["username"] as? String ?? json["email"] as? String
                            profilePicUrl = json["profile_picture_url"] as? String
                            firstName = json["firstName"] as? String ?? json["first_name"] as? String ?? "User"
                            lastName = json["lastName"] as? String ?? json["last_name"] as? String
                            print("Login receiveValue: Extracted from top-level: email=\(email ?? "nil"), firstName=\(firstName ?? "nil"), lastName=\(lastName ?? "nil"), profilePicUrl=\(profilePicUrl ?? "nil")")
                        }
                        
                        print("Login receiveValue: Final check before saving keychain data...")
                        // Save user ID if found
                        if let userId = userId, !userId.isEmpty {
                            print("Login receiveValue: Saving userId to keychain: \(userId)")
                            KeychainService.shared.saveUserId(userId)
                            self.userId = userId
                        } else {
                            // Generate a fallback user ID if none found in response
                            let fallbackId = "user-\(UUID().uuidString)"
                             print("Login receiveValue: No valid userId extracted. Generating fallback: \(fallbackId)")
                            KeychainService.shared.saveUserId(fallbackId)
                            self.userId = fallbackId
                        }
                        
                        // Save token if found
                        if let accessToken = accessToken, !accessToken.isEmpty {
                            print("Login receiveValue: Saving accessToken to keychain.")
                            KeychainService.shared.saveAccessToken(accessToken)
                            // Also save potential refresh token if present (key might vary)
                            if let refreshToken = json["refresh_token"] as? String ?? json["refreshToken"] as? String {
                                print("Login receiveValue: Saving refreshToken to keychain.")
                                KeychainService.shared.saveRefreshToken(refreshToken)
                            }
                        } else {
                            // If no token was explicitly found, but we got 200 OK, 
                            // we might be in a state where the backend considers login valid
                            // but didn't return a token (e.g., session-based auth on web?).
                            // For mobile, we usually *need* a token. Log a warning.
                            print("⚠️ Login receiveValue: No valid token found in successful (200 OK) response. Cannot complete mobile authentication flow without a token.")
                            // Set error message and prevent further state changes
                            self.errorMessage = "Login successful, but no authentication token received from server."
                            self.isLoading = false // Ensure loading indicator stops
                            return // Exit early, do not proceed to update auth state
                        }
                        
                        // Create user object with available info or fallbacks
                        print("Login receiveValue: Creating User object...")
                        self.currentUser = User(
                            id: self.userId ?? "user-\(UUID().uuidString)", // Use self.userId which includes fallback
                            email: email ?? self.username, // Fallback to entered username if needed
                            firstName: firstName ?? "User", // Ensure default
                            lastName: lastName ?? "",
                            profilePictureUrl: profilePicUrl
                        )
                        print("Login receiveValue: User object created: \(self.currentUser!)")
                        
                        print("Login receiveValue: Preparing to update auth state...") // No longer explicitly dispatching to main
                        // Update auth state directly, as we are already on the main thread due to .receive(on:)
                        // REMOVE DispatchQueue.main.async wrapper
                        // DispatchQueue.main.async { [weak self] in
                            // self is already captured strongly earlier in this closure after the first guard; no need to unwrap again.
                            print("Login receiveValue: Executing state updates directly on main thread.")
                            
                            // First, set user data
                            self.currentUser = self.currentUser // Make sure user is set
                            
                            // Critical: Force UI update BEFORE changing auth state
                            self.objectWillChange.send()
                            
                            // Now set authentication state
                            self.authState = .authenticated
                            self._isAuthenticatedInternal = true // Update internal property
                            print("Login receiveValue: Set authState=authenticated, _isAuthenticatedInternal=true")
                            
                            // Force immediate UI update
                            self.objectWillChange.send()
                            
                            print("Login receiveValue: Authentication state updated successfully.")
                            
                            // Add a delayed second update for SwiftUI's next render cycle
                            // Keep this dispatch as it's specifically for a *delayed* update/notification
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                print("Login receiveValue: Sending delayed objectWillChange notification.")
                                // This forces a refresh on the next render cycle
                                self.objectWillChange.send()
                                
                                // Post a notification for views that might not be directly observing
                                print("Login receiveValue: Posting PTChampionAuthStateChanged notification.")
                                NotificationCenter.default.post(
                                    name: Notification.Name("PTChampionAuthStateChanged"),
                                    object: nil
                                )
                                
                                print("Login receiveValue: Sent delayed auth state update components.")
                            }
                        // } // End of REMOVED DispatchQueue.main.async wrapper
                    } else {
                        // If JSONSerialization failed but we got 200 OK.
                        print("Login receiveValue: JSON parsing failed, but received 200 status code.")
                        // This is unexpected. A 200 OK should usually contain valid JSON.
                        // Set an error message indicating the unexpected response format.
                        self.errorMessage = "Login failed: Server returned success, but response format was invalid."
                        self.isLoading = false
                    }
                } catch {
                    // Catch errors specifically from JSONSerialization or subsequent processing
                    print("Login receiveValue: Error during JSON processing: \(error.localizedDescription)")
                    self.errorMessage = "Login failed: Error processing server response."
                    self.isLoading = false
                }
            })
            .store(in: &cancellables)
    }
    
    func register(username: String, password: String, displayName: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Create registration request with standard field names that match web implementation
        let registrationBody: [String: Any] = [
            "username": username,
            "password": password,
            "display_name": displayName,  // Using snake_case for API
            "email": username  // Ensure email is always set (matches web app)
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: registrationBody) else {
            self.errorMessage = "Error creating request"
            self.isLoading = false
            return
        }
        
        // API URL
        guard let url = URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/register") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make API call
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let errorStr = String(data: data, encoding: .utf8) {
                        print("Server error response: \(errorStr)")
                    }
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [self] completion in
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = "Registration failed: \(error.localizedDescription)"
                    print("Registration error: \(error)")
                }
            }, receiveValue: { [self] _ in
                // Registration success
                self.successMessage = "Registration successful! Please log in."
                print("Registration successful")
            })
            .store(in: &cancellables)
    }
    
    // Provide a computed property for external use that reads the internal state
    var isAuthenticated: Bool {
        return _isAuthenticatedInternal && validateTokenRuntime()
    }

    // Add a runtime validation check used by the public computed property
    private func validateTokenRuntime() -> Bool {
        guard let token = KeychainService.shared.getAccessToken() else {
            return false 
        }
        // Add more checks here if needed (e.g., expiration)
        return !token.isEmpty
    }
    
    func logout() {
        // Clear tokens from keychain
        KeychainService.shared.clearAllTokens()
        
        // Reset user data
        self.userId = nil
        self.currentUser = nil
        
        // Update auth state on the main thread to ensure SwiftUI updates properly
        DispatchQueue.main.async { [self] in
            self.authState = .unauthenticated
            self._isAuthenticatedInternal = false
            // Force UI update with objectWillChange
            self.objectWillChange.send()
            print("AuthViewModel: User logged out successfully")
        }
    }
    
    // MARK: - Developer Mode Functions
    
    /// Bypasses the normal authentication flow for development purposes
    func loginAsDeveloper() {
        print("AuthViewModel: Bypassing authentication flow for development")
        
        // Update state on the main thread to ensure SwiftUI updates properly
        DispatchQueue.main.async { [self] in
            self.authState = .authenticated
            self._isAuthenticatedInternal = true
            self.currentUser = User(
                id: "dev-123",
                email: "dev@example.com",
                firstName: "Developer",
                lastName: "User",
                profilePictureUrl: nil
            )
            self.errorMessage = nil
            // Force UI update with objectWillChange
            self.objectWillChange.send()
            print("AuthViewModel: Developer login successful without token")
        }
    }
    
    // Debug method for directly forcing authentication state
    func debugForceAuthenticated() {
        print("DEBUG: Starting force authentication")
        DispatchQueue.main.async {
            self.authState = .authenticated
            self._isAuthenticatedInternal = true
            
            // Create a dummy user if needed
            if self.currentUser == nil {
                self.currentUser = User(
                    id: "debug-123",
                    email: "debug@example.com",
                    firstName: "Debug",
                    lastName: "User",
                    profilePictureUrl: nil
                )
            }
            
            // Force UI update with objectWillChange
            self.objectWillChange.send()
            print("DEBUG: Forced authentication state to true, isAuthenticated=\(self.isAuthenticated)")
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