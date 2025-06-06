import Foundation
import Combine // For ObservableObject

class AuthService: ObservableObject, AuthServiceProtocol {
    // Published properties can be added here if AuthService needs to drive UI updates directly
    // For example: @Published var isAuthenticated: Bool = false (though this is often handled in AuthViewModel)

    private let networkClient: NetworkClient
    private let useMockAuth: Bool

    init(networkClient: NetworkClient = NetworkClient(), useMockAuth: Bool = false) {
        self.networkClient = networkClient
        self.useMockAuth = useMockAuth
    }

    // MARK: - API Endpoints
    private enum APIEndpoint {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let profileLocation = "/profile/location"
    }

    // MARK: - Protocol Implementation
    func login(credentials: AuthLoginRequest) async throws -> AuthResponse {
        print("AuthService: Attempting login with email: \(credentials.email)...")
        print("AuthService: Mock auth is disabled, will make real network request")
        
        if useMockAuth {
            print("AuthService: Using mock authentication!")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-12345",
                refreshToken: "mock-refresh-token-12345",
                user: AuthUserModel(
                    id: "123",
                    email: credentials.email,
                    firstName: "Test",
                    lastName: "User",
                    profilePictureUrl: nil as String?
                )
            )
            
            KeychainService.shared.saveAccessToken(mockResponse.token)
            KeychainService.shared.saveUserID(mockResponse.user.id)
            KeychainService.shared.saveRefreshToken(mockResponse.refreshToken)
            NetworkClient.shared.updateAuthToken(mockResponse.token)
            print("AuthService: Mock login successful, credentials saved.")
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return mockResponse
        }
        
        print("AuthService: Sending real login request to: \(APIEndpoint.login)...")
        
        do {
            let response: AuthResponse = try await networkClient.performRequest(
                endpointPath: APIEndpoint.login,
                method: "POST",
                body: credentials
            )
            
            print("AuthService: Login response received successfully!")
            print("AuthService: Token received: \(response.token.prefix(10))...")
            print("AuthService: User ID: \(response.user.id)")
            
            KeychainService.shared.saveAccessToken(response.token)
            KeychainService.shared.saveUserID(response.user.id)
            KeychainService.shared.saveRefreshToken(response.refreshToken)
            
            // Update shared NetworkClient with the new token
            NetworkClient.shared.updateAuthToken(response.token)
            
            print("AuthService: Login successful, credentials saved.")
            return response
        } catch {
            print("AuthService: Login request failed with error: \(error)")
            if let apiError = error as? APIError {
                print("AuthService: API Error details: \(apiError.localizedDescription)")
                switch apiError {
                case .requestFailed(let statusCode, let message):
                    print("AuthService: Request failed with status code: \(statusCode), message: \(message ?? "None")")
                default:
                    break
                }
            }
            throw error
        }
    }

    func register(userInfo: RegistrationRequest) async throws -> Void {
        print("AuthService: Attempting registration with email: \(userInfo.email)...")
        print("AuthService: Registration request details: name: \(userInfo.firstName) \(userInfo.lastName)")
        print("AuthService: Mock auth is disabled, will make real network request")
        
        if useMockAuth {
            print("AuthService: Using mock registration!")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            print("AuthService: Mock registration successful.")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-registration-12345",
                refreshToken: "mock-refresh-token-for-registration-12345",
                user: AuthUserModel(
                    id: "456",
                    email: userInfo.email,
                    username: userInfo.username,
                    firstName: userInfo.firstName,
                    lastName: userInfo.lastName,
                    profilePictureUrl: nil
                )
            )
            
            KeychainService.shared.saveAccessToken(mockResponse.token)
            KeychainService.shared.saveUserID(mockResponse.user.id)
            KeychainService.shared.saveRefreshToken(mockResponse.refreshToken)
            NetworkClient.shared.updateAuthToken(mockResponse.token)
            return
        }
        
        print("AuthService: Sending real registration request to: \(APIEndpoint.register)...")
        
        do {
            try await networkClient.performRequestNoContent(
                endpointPath: APIEndpoint.register,
                method: "POST",
                body: userInfo
            )
            print("AuthService: Registration successful.")
        } catch {
            print("AuthService: Registration request failed with error: \(error)")
            if let apiError = error as? APIError {
                print("AuthService: API Error details: \(apiError.localizedDescription)")
                switch apiError {
                case .requestFailed(let statusCode, let message):
                    print("AuthService: Request failed with status code: \(statusCode), message: \(message ?? "None")")
                default:
                    break
                }
            }
            throw error
        }
    }
    
    func logout() {
        print("AuthService: Logging out, clearing credentials.")
        KeychainService.shared.clearAllTokens()
        
        // Clear the shared NetworkClient token
        NetworkClient.shared.updateAuthToken(nil)
    }
    
    func updateUserLocation(latitude: Double, longitude: Double) async throws -> Void {
        print("AuthService: Updating user location to (\(latitude), \(longitude))")
        
        if useMockAuth {
            print("AuthService: Using mock location update!")
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            print("AuthService: Mock location update successful.")
            return
        }
        
        let requestBody = UpdateLocationRequest(latitude: latitude, longitude: longitude)
        try await networkClient.performRequestNoContent(
            endpointPath: APIEndpoint.profileLocation,
            method: "PUT",
            body: requestBody
        )
        print("AuthService: User location update successful.")
    }

    func loginWithSocial(provider: String, token: String, additionalData: [String: String]? = nil) async throws -> AuthResponse {
        print("AuthService: Attempting login with \(provider) provider...")
        
        if useMockAuth {
            print("AuthService: Using mock authentication for social login!")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-\(provider)-testing-12345",
                refreshToken: "mock-refresh-token-for-\(provider)-12345",
                user: AuthUserModel(
                    id: "789",
                    email: "\(provider)User@example.com",
                    firstName: "\(provider)",
                    lastName: "User",
                    profilePictureUrl: nil as String?
                )
            )
            
            KeychainService.shared.saveAccessToken(mockResponse.token)
            KeychainService.shared.saveUserID(mockResponse.user.id)
            KeychainService.shared.saveRefreshToken(mockResponse.refreshToken)
            NetworkClient.shared.updateAuthToken(mockResponse.token)
            print("AuthService: Mock \(provider) login successful, credentials saved.")
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return mockResponse
        }
        
        print("AuthService: Sending real \(provider) login request to: /auth/\(provider)...")
        
        // Create the request body based on provider
        var requestBody: [String: Any] = [:]
        
        if provider == "apple" {
            // For Apple, the backend expects the identity token (JWT) in the token field
            requestBody["provider"] = provider
            
            // The backend expects the identity token as the main token
            requestBody["token"] = token  // This should be the identity token
            
            // Add additional data if provided
            if let additionalData = additionalData {
                // Add authorization code if available (some backends may use this)
                if let authCode = additionalData["authorizationCode"] {
                    requestBody["code"] = authCode
                }
                
                // Add nonce if available
                if let nonce = additionalData["nonce"] {
                    requestBody["nonce"] = nonce
                }
                
                // Add user info if this is first sign-in
                if let email = additionalData["email"] {
                    requestBody["email"] = email
                }
                
                if let firstName = additionalData["firstName"] {
                    requestBody["first_name"] = firstName
                }
                
                if let lastName = additionalData["lastName"] {
                    requestBody["last_name"] = lastName
                }
                
                if let userId = additionalData["userId"] {
                    requestBody["user_id"] = userId
                }
            }
            
            print("AuthService: Apple Sign In request body keys: \(requestBody.keys.joined(separator: ", "))")
        } else {
            // For other providers (Google), use the original format
            requestBody = [
                "token": token,
                "provider": provider
            ]
        }
        
        do {
            // Convert request body to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Debug: Print the JSON payload
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("AuthService: \(provider) login request payload: \(jsonString)")
            }
            
            let response: AuthResponse = try await networkClient.performRequest(
                endpointPath: "/auth/\(provider)",
                method: "POST",
                body: jsonData
            )
            
            print("AuthService: \(provider) login response received successfully!")
            print("AuthService: Token received: \(response.token.prefix(10))...")
            print("AuthService: User ID: \(response.user.id)")
            
            KeychainService.shared.saveAccessToken(response.token)
            KeychainService.shared.saveUserID(response.user.id)
            KeychainService.shared.saveRefreshToken(response.refreshToken)
            
            // Update shared NetworkClient with the new token
            NetworkClient.shared.updateAuthToken(response.token)
            
            print("AuthService: \(provider) login successful, credentials saved.")
            return response
        } catch {
            print("AuthService: \(provider) login request failed with error: \(error)")
            if let apiError = error as? APIError {
                print("AuthService: API Error details: \(apiError.localizedDescription)")
                switch apiError {
                case .requestFailed(let statusCode, let message):
                    print("AuthService: Request failed with status code: \(statusCode), message: \(message ?? "None")")
                    
                    // If we get a 400 or 401 error with Apple Sign In, log more details
                    if provider == "apple" && (statusCode == 400 || statusCode == 401) {
                        print("AuthService: Apple Sign In failed. Check if:")
                        print("  - The identity token is valid and not expired")
                        print("  - The backend is configured with correct Apple credentials")
                        print("  - The token verification on backend is working properly")
                    }
                default:
                    break
                }
            }
            
            // If it's a network error, provide more context
            if let urlError = error as? URLError {
                print("AuthService: Network error: \(urlError.localizedDescription)")
                print("AuthService: Error code: \(urlError.code)")
            }
            
            throw error
        }
    }
}

// Removed the duplicate UpdateLocationRequest struct as it's already defined in UserProfileModels.swift
