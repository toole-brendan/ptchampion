import Foundation

class AuthService: AuthServiceProtocol {
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
        print("AuthService: Attempting login with username: \(credentials.username)...")
        print("AuthService: Mock auth is disabled, will make real network request")
        
        if useMockAuth {
            print("AuthService: Using mock authentication!")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-12345",
                user: AuthUserModel(
                    id: "123",
                    email: credentials.username,
                    firstName: "Test",
                    lastName: "User",
                    profilePictureUrl: nil as String?
                )
            )
            
            networkClient.saveLoginCredentials(token: mockResponse.token, userId: 123)
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
            
            guard let userIdInt = Int(response.user.id) else {
                print("AuthService Error: Could not convert user ID string '\(response.user.id)' to Int.")
                throw APIError.underlying(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format received from server: '\(response.user.id)'."])) 
            }
            networkClient.saveLoginCredentials(token: response.token, userId: userIdInt)
            
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
        print("AuthService: Attempting registration with username: \(userInfo.username)...")
        print("AuthService: Registration request details: display name: \(userInfo.displayName ?? "nil")")
        print("AuthService: Mock auth is disabled, will make real network request")
        
        if useMockAuth {
            print("AuthService: Using mock registration!")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            print("AuthService: Mock registration successful.")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-registration-12345",
                user: AuthUserModel(
                    id: "456",
                    email: userInfo.username,
                    firstName: userInfo.displayName,
                    lastName: nil as String?,
                    profilePictureUrl: userInfo.profilePictureUrl
                )
            )
            
            networkClient.saveLoginCredentials(token: mockResponse.token, userId: 456)
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
        networkClient.clearLoginCredentials()
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
}

// Removed the duplicate UpdateLocationRequest struct as it's already defined in UserProfileModels.swift
