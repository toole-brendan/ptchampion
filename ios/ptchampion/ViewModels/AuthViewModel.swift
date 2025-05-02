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
    @Published var isAuthenticated: Bool = false // For compatibility with existing code
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
        // Check for existing token on startup
        checkAuthentication()
    }
    
    func checkAuthentication() {
        if let token = KeychainService.shared.getAccessToken(),
           let userId = KeychainService.shared.getUserId() {
            self.userId = userId
            self.authState = .authenticated
            self.isAuthenticated = true // Update both state properties for compatibility
            print("AuthViewModel: User is authenticated with ID: \(userId)")
        } else {
            self.authState = .unauthenticated
            self.isAuthenticated = false // Update both state properties for compatibility
            print("AuthViewModel: No token found in keychain.")
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
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("TEST DIRECT LOGIN: Network callback received")
                print("TEST DIRECT LOGIN: Status code: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let errorStr = String(data: data, encoding: .utf8) {
                        print("Server error response: \(errorStr)")
                    }
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    print("Login error: \(error)")
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                
                do {
                    if let responseStr = String(data: data, encoding: .utf8) {
                        print("TEST DIRECT LOGIN: Response data: \(responseStr)")
                    }
                    
                    // Parse response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("TEST DIRECT LOGIN: Raw JSON: \(json)")
                        
                        if let accessToken = json["access_token"] as? String {
                            print("TEST DIRECT LOGIN: Successfully extracted access_token")
                            
                            // Save tokens to keychain
                            KeychainService.shared.saveAccessToken(accessToken)
                            
                            if let refreshToken = json["refresh_token"] as? String {
                                KeychainService.shared.saveRefreshToken(refreshToken)
                            }
                            
                            // Save user info
                            if let user = json["user"] as? [String: Any], 
                               let userId = user["id"] as? Int {
                                print("TEST DIRECT LOGIN: Extracted user ID: \(userId)")
                                KeychainService.shared.saveUserId(String(userId))
                                self.userId = String(userId)
                                
                                // Create a User object
                                let displayName = user["displayName"] as? String ?? ""
                                let username = user["username"] as? String ?? self.username
                                let firstName = displayName.components(separatedBy: " ").first
                                let lastName = displayName.components(separatedBy: " ").dropFirst().joined(separator: " ")
                                
                                // Set current user
                                self.currentUser = User(
                                    id: String(userId),
                                    email: username,
                                    firstName: firstName,
                                    lastName: lastName.isEmpty ? nil : lastName,
                                    profilePictureUrl: user["profilePictureUrl"] as? String
                                )
                            }
                            
                            // Update auth state - these should happen at the same time
                            self.authState = .authenticated
                            self.isAuthenticated = true
                            print("AuthViewModel: Authentication state updated successfully")
                        } else {
                            self.errorMessage = "Invalid response format"
                        }
                    } else {
                        self.errorMessage = "Could not parse response"
                    }
                } catch {
                    self.errorMessage = "Error parsing response: \(error.localizedDescription)"
                    print("JSON parsing error: \(error)")
                }
            })
            .store(in: &cancellables)
    }
    
    func register(username: String, password: String, displayName: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Create registration request
        let registrationBody: [String: Any] = [
            "username": username,
            "password": password,
            "displayName": displayName
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
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = "Registration failed: \(error.localizedDescription)"
                    print("Registration error: \(error)")
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                
                // Registration success
                self.successMessage = "Registration successful! Please log in."
                print("Registration successful")
            })
            .store(in: &cancellables)
    }
    
    func logout() {
        // Clear tokens from keychain
        KeychainService.shared.clearAllTokens()
        
        // Reset user data
        self.userId = nil
        self.currentUser = nil
        
        // Update auth state - these should happen at the same time
        self.authState = .unauthenticated
        self.isAuthenticated = false
        print("AuthViewModel: User logged out successfully")
    }
    
    // MARK: - Developer Mode Functions
    
    /// Bypasses the normal authentication flow for development purposes
    func loginAsDeveloper() {
        print("AuthViewModel: Bypassing authentication flow for development")
        self.authState = .authenticated
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