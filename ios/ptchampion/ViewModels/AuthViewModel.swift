import Foundation
import SwiftUI

// Error extension for nicer user-facing messages
private extension Error {
    var userFacingMessage: String {
        (self as? URLError)?.failureURLString ?? localizedDescription
    }
}

// Define authentication states with associated user data
enum AuthState: Equatable {
    case authenticated(User)
    case unauthenticated
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        default:
            return false
        }
    }
}

// String extension for name parsing
extension String {
    func splitDisplayName() -> (firstName: String, lastName: String) {
        let components = self.split(separator: " ")
        let firstName = components.first.map(String.init) ?? "User"
        let lastName = components.count > 1 ? 
            components.dropFirst().joined(separator: " ") : ""
        return (firstName, lastName)
    }
}

// API helper
enum API {
    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
    }
    
    static func login(_ email: String, _ password: String) async throws -> (token: String, user: User) {
        print("⚙️ Starting login for email: \(email)")
        let request = LoginRequest(username: email, password: password)
        let url = URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login")!
        
        print("⚙️ About to send login request")
        let response: AuthResponse = try await post(request, to: url)
        print("⚙️ Received login response with token: \(response.token.prefix(10))... and user: \(response.user.id)")
        
        return (response.token, response.user)
    }
    
    static func post<R: Encodable, T: Decodable>(_ request: R, to url: URL) async throws -> T {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        do {
            print("⚙️ Sending HTTP request to \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                print("❌ HTTP error: \(response)")
                throw APIError.invalidResponse
            }
            
            print("✅ HTTP response: \(httpResponse.statusCode)")
            
            // Print raw response for debugging
            #if DEBUG
            if let responseStr = String(data: data, encoding: .utf8) {
                print("🔍 Raw JSON response: \(responseStr)")
            }
            #endif
            
            print("⚙️ Attempting to decode response")
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                print("✅ Successfully decoded response")
                return result
            } catch {
                print("🛑 Decoding failed - DETAILED ERROR: \(error)")
                print("🛑 Decoding error localized description: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("🛑 Type mismatch: expected \(type), context: \(context)")
                    case .valueNotFound(let type, let context):
                        print("🛑 Value not found: expected \(type), context: \(context)")
                    case .keyNotFound(let key, let context):
                        print("🛑 Key not found: \(key), context: \(context)")
                    case .dataCorrupted(let context):
                        print("🛑 Data corrupted: context: \(context)")
                    @unknown default:
                        print("🛑 Unknown decoding error")
                    }
                }
                throw APIError.requestFailed(error)
            }
        } catch {
            print("🛑 Network or decoding error: \(error)")
            throw APIError.requestFailed(error)
        }
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published private(set) var authState: AuthState = .unauthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String? = nil
    
    // Add a unique identifier for debugging
    private let instanceId = UUID().uuidString.prefix(8)

    init() { 
        print("⚙️ AuthViewModel init – ID: \(instanceId)", ObjectIdentifier(self))
        checkAuthentication() 
    }

    // MARK: – Public API -----------------------------------------------------

    func login(email: String, password: String) async {
        print("⚙️ LOGIN START with email: \(email) - AuthViewModel ID: \(instanceId)")
        
        // Update loading state on main thread
        await MainActor.run { withAnimation { isLoading = true } }

        // Create a SINGLE strong task reference that won't be cancelled when view disappears
        do {
            print("A. Starting API.login call - AuthViewModel ID: \(self.instanceId)")
            let (token, user) = try await API.login(email, password)
            print("B. API.login SUCCESS - token: \(token.prefix(10))... user: \(user.id) - AuthViewModel ID: \(self.instanceId)")
            
            // Using a local variable to ensure this sequence completes
            print("C. Saving token - AuthViewModel ID: \(self.instanceId)")
            KeychainService.shared.saveAccessToken(token)
            
            print("D. Saving user ID - AuthViewModel ID: \(self.instanceId)")
            KeychainService.shared.saveUserId(user.id)
            
            print("E. Updating authState - AuthViewModel ID: \(self.instanceId)")
            await MainActor.run {
                print("E. On MainActor, setting authState - AuthViewModel ID: \(self.instanceId)")
                print("BEFORE state change: \(self.authState)")
                
                // Force state change on the main actor with animation
                withAnimation {
                    self.authState = .authenticated(user)
                }
                
                // Verify state change happened
                print("AFTER state change: \(self.authState)")
                print("Auth state is now: \(self.authState.isAuthenticated ? "AUTHENTICATED" : "UNAUTHENTICATED")")
            }
            
            print("🟢 F. Login sequence COMPLETED for \(user.id) - AuthViewModel ID: \(self.instanceId)")
        } catch {
            print("🔴 API call failed - \(error) - AuthViewModel ID: \(self.instanceId)")
            await MainActor.run {
                self.errorMessage = "Login failed: \(error.localizedDescription)"
                withAnimation {
                    self.authState = .unauthenticated
                }
            }
        }
        
        // Always reset loading state
        await MainActor.run { withAnimation { isLoading = false } }
        print("⚙️ LOGIN SEQUENCE FINISHED - AuthViewModel ID: \(self.instanceId)")
    }

    func logout() {
        print("⚙️ LOGOUT - AuthViewModel ID: \(instanceId)")
        
        // Create a Task to handle logout asynchronously
        Task { @MainActor in
            // First update UI state
            withAnimation {
                // Set state to unauthenticated first
                self.authState = .unauthenticated
            }
            
            // Then clear storage - do this after UI update to prevent freezes
            print("Clearing keychain tokens")
            KeychainService.shared.clearAllTokens()
            
            print("🟢 Logout complete - AuthViewModel ID: \(instanceId)")
        }
    }
    
    // MARK: - Registration
    
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
        
        // Use straightforward Task with await pattern
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                self.isLoading = false
                self.successMessage = "Registration successful! Please log in."
            } catch {
                self.isLoading = false
                self.errorMessage = "Registration failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Developer Mode Functions
    
    /// Bypasses the normal authentication flow for development purposes
    func loginAsDeveloper() {
        let devUser = User(
            id: "dev-123",
            email: "dev@example.com",
            firstName: "Developer", 
            lastName: "User",
            profilePictureUrl: nil
        )
        
        self.authState = .authenticated(devUser)
    }
    
    // Debug method for directly forcing authentication state
    func debugForceAuthenticated() {
        let debugUser = User(
            id: "debug-123",
            email: "debug@example.com",
            firstName: "Debug",
            lastName: "User",
            profilePictureUrl: nil
        )
        
        self.authState = .authenticated(debugUser)
        print("🟢 DEBUG: Force set authState to authenticated with user ID: \(debugUser.id)")
    }

    // MARK: – Startup --------------------------------------------------------

    func checkAuthentication() {
        // Move keychain operations to a background task to prevent main thread blocking
        Task {
            // Get token and user ID from keychain
            let token = KeychainService.shared.getAccessToken()
            let uid = KeychainService.shared.getUserId()
            
            // Update UI state on main thread
            await MainActor.run {
                if let token = token, !token.isEmpty, let uid = uid {
                    print("⚙️ Found token and user ID in keychain, setting state to authenticated with user ID: \(uid)")
                    authState = .authenticated(User(id: uid, email: "", firstName: "User", lastName: "", profilePictureUrl: nil))
                } else {
                    print("⚙️ No valid token or user ID found in keychain, setting state to unauthenticated")
                    authState = .unauthenticated
                }
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        print("⚙️ AuthViewModel deinit - ID: \(instanceId)")
    }
}

// Placeholder User model - move to Models/
// struct User: Identifiable, Codable {
//     let id: String // Or Int depending on your backend
//     let email: String
//     let firstName: String?
//     let lastName: String?
// } 