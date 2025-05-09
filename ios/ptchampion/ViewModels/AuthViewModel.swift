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
    case authenticated(AuthUserModel)
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
        case requestFailed(statusCode: Int, message: String)
        case invalidResponse
    }
    
    static func login(_ email: String, _ password: String) async throws -> (token: String, user: AuthUserModel) {
        print("⚙️ Starting login for email: \(email)")
        let request = AuthLoginRequest(username: email, password: password)
        let url = URL(string: "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login")!
        
        print("⚙️ About to send login request")
        let response: AuthResponse = try await post(request, to: url)
        print("⚙️ Received login response with token: \(response.token.prefix(10))... and user: \(response.user.id)")
        
        return (response.token, response.user)
    }
    
    static func post<R: Encodable, T: Decodable>(_ body: R, to url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Success ----------------------------------------------------------------
        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        }

        // Failure ----------------------------------------------------------------
        // Try to decode the server's message; if that fails fall back to statusCode
        let envelope = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.message
        throw APIError.requestFailed(statusCode: http.statusCode,
                                 message: envelope ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode))
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

    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        print("⚙️ LOGIN START with email: \(email) - AuthViewModel ID: \(instanceId)")
        
        Task.detached(priority: .userInitiated) {
            await MainActor.run { self.isLoading = true }
            
            do {
                print("A. Starting API.login call - AuthViewModel ID: \(self.instanceId)")
                // Normalize email: trim whitespace and convert to lowercase
                let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let (token, user) = try await API.login(normalizedEmail, password)
                print("B. API.login SUCCESS - token: \(token.prefix(10))... user: \(user.id) - AuthViewModel ID: \(self.instanceId)")
                
                // Using a local variable to ensure this sequence completes
                print("C. Saving token - AuthViewModel ID: \(self.instanceId)")
                try KeychainService.shared.saveAccessToken(token)
                
                print("D. Saving user ID - AuthViewModel ID: \(self.instanceId)")
                KeychainService.shared.saveUserID(user.id)
                
                print("E. Updating authState - AuthViewModel ID: \(self.instanceId)")
                await MainActor.run {
                    print("E. On MainActor, setting authState - AuthViewModel ID: \(self.instanceId)")
                    print("BEFORE state change: \(self.authState)")
                    
                    // Force state change with animation
                    withTransaction(Transaction(animation: .easeInOut)) {
                        self.authState = .authenticated(user)
                    }
                    
                    // Verify state change happened
                    print("AFTER state change: \(self.authState)")
                    print("Auth state is now: \(self.isAuthenticated ? "AUTHENTICATED" : "UNAUTHENTICATED")")
                }
                
                print("🟢 F. Login sequence COMPLETED for \(user.id) - AuthViewModel ID: \(self.instanceId)")
            } catch {
                print("🔴 API call failed - \(error) - AuthViewModel ID: \(self.instanceId)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    withAnimation { self.authState = .unauthenticated }
                }
            }
            
            // Always reset loading state at the end (instead of using defer)
            await MainActor.run { self.isLoading = false }
            print("⚙️ LOGIN SEQUENCE FINISHED - AuthViewModel ID: \(self.instanceId)")
        }
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
        
        // Normalize username/email: trim whitespace and convert to lowercase
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Create registration request with standard field names that match web implementation
        let registrationBody: [String: Any] = [
            "username": normalizedUsername,
            "password": password,
            "display_name": displayName,  // Using snake_case for API
            "email": normalizedUsername  // Ensure email is always set (matches web app)
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
        let devUser = AuthUserModel(
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
        let debugUser = AuthUserModel(
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
            let uid = KeychainService.shared.getUserID()
            
            // Update UI state on main thread
            await MainActor.run {
                if let token = token, !token.isEmpty, let uid = uid {
                    print("⚙️ Found token and user ID in keychain, setting state to authenticated with user ID: \(uid)")
                    authState = .authenticated(AuthUserModel(id: uid, email: "", firstName: "User", lastName: "", profilePictureUrl: nil))
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

    // MARK: - Convenience Properties
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        } else {
            return false
        }
    }
    
    var displayName: String {
        if case .authenticated(let user) = authState {
            return user.firstName ?? "User"
        }
        return "User"
    }

    var email: String? {
        if case .authenticated(let user) = authState {
            return user.email
        }
        return nil
    }
}

// MARK: – Compatibility shims (delete when gallery is refactored)
extension AuthViewModel {
    /// Legacy API kept so that ComponentGalleryView still compiles
    @MainActor
    var currentUser: User? { 
        guard case .authenticated(let authUser) = authState else { return nil }
        return User(id: authUser.id, email: authUser.email, firstName: authUser.firstName, lastName: authUser.lastName, profilePictureUrl: authUser.profilePictureUrl)
    }

    @MainActor
    var galleryDisplayName: String {
        currentUser?.fullName ?? "Athlete"
    }
    
    /// Updates the current user for preview/testing purposes only
    @MainActor
    func setMockUser(_ user: User) {
        self.authState = .authenticated(user)
    }
}

// Compatibility User model for gallery is now replaced by the typealias in AppModels.swift
// struct User: Identifiable, Codable {
//     let id: String
//     let email: String
//     let displayName: String
// }

// Placeholder User model - move to Models/
// struct User: Identifiable, Codable {
//     let id: String // Or Int depending on your backend
//     let email: String
//     let firstName: String?
//     let lastName: String?
// } 