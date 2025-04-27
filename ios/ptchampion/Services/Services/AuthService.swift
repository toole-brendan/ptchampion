import Foundation

class AuthService: AuthServiceProtocol {
    private let networkClient: NetworkClient
    private let useMockAuth: Bool

    init(networkClient: NetworkClient = NetworkClient(), useMockAuth: Bool = true) {
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
    func login(credentials: LoginRequest) async throws -> AuthResponse {
        print("AuthService: Attempting login...")
        
        if useMockAuth {
            print("AuthService: Using mock authentication!")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-12345",
                user: User(
                    id: "123",
                    email: credentials.username,
                    firstName: "Test",
                    lastName: "User",
                    profilePictureUrl: nil
                )
            )
            
            networkClient.saveLoginCredentials(token: mockResponse.token, userId: 123)
            print("AuthService: Mock login successful, credentials saved.")
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return mockResponse
        }
        
        let response: AuthResponse = try await networkClient.performRequest(
            endpointPath: APIEndpoint.login,
            method: "POST",
            body: credentials
        )
        
        guard let userIdInt = Int(response.user.id) else {
            print("AuthService Error: Could not convert user ID string '\(response.user.id)' to Int.")
            throw APIError.underlying(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format received from server: '\(response.user.id)'."])) 
        }
        networkClient.saveLoginCredentials(token: response.token, userId: userIdInt)
        
        print("AuthService: Login successful, credentials saved.")
        return response
    }

    func register(userInfo: RegistrationRequest) async throws -> Void {
        print("AuthService: Attempting registration...")
        
        if useMockAuth {
            print("AuthService: Using mock registration!")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            print("AuthService: Mock registration successful.")
            
            let mockResponse = AuthResponse(
                token: "mock-jwt-token-for-testing-registration-12345",
                user: User(
                    id: "456",
                    email: userInfo.username,
                    firstName: userInfo.displayName,
                    lastName: nil,
                    profilePictureUrl: userInfo.profilePictureUrl
                )
            )
            
            networkClient.saveLoginCredentials(token: mockResponse.token, userId: 456)
            return
        }
        
        try await networkClient.performRequestNoContent(
            endpointPath: APIEndpoint.register,
            method: "POST",
            body: userInfo
        )
        print("AuthService: Registration successful.")
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
