import Foundation

// Implementation of AuthServiceProtocol using the shared NetworkClient
class AuthService: AuthServiceProtocol {

    private let networkClient: NetworkClient

    // Inject the NetworkClient
    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - API Endpoints (Paths only)
    // Base URL and methods are handled by NetworkClient
    private enum APIEndpoint {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let profileLocation = "/profile/location"
    }

    // MARK: - Protocol Implementation

    func login(credentials: LoginRequest) async throws -> AuthResponse {
        print("AuthService: Attempting login...")
        let response: AuthResponse = try await networkClient.performRequest(
            endpointPath: APIEndpoint.login,
            method: "POST",
            body: credentials
        )
        
        // On successful login, save the token AND user ID
        // Safely convert user ID string to Int for Keychain storage
        guard let userIdInt = Int(response.user.id) else {
            // Handle the error appropriately - throw an error if the ID is invalid
            print("AuthService Error: Could not convert user ID string '\(response.user.id)' to Int.")
            throw APIError.underlying(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format received from server: '\(response.user.id)'."])) // Throw specific error
        }
        networkClient.saveLoginCredentials(token: response.token, userId: userIdInt)
        
        print("AuthService: Login successful, credentials saved.")
        return response
    }

    func register(userInfo: RegistrationRequest) async throws -> Void {
        print("AuthService: Attempting registration...")
        // Use performRequestNoContent as registration likely returns 201 or 204 on success
        try await networkClient.performRequestNoContent(
            endpointPath: APIEndpoint.register,
            method: "POST",
            body: userInfo
        )
        print("AuthService: Registration successful.")
        // No response body expected, return Void
    }
    
    // Add a logout function to clear the token and user ID
    func logout() {
        print("AuthService: Logging out, clearing credentials.")
        networkClient.clearLoginCredentials()
        // Post notification or update state if needed
    }
    
    func updateUserLocation(latitude: Double, longitude: Double) async throws -> Void {
        print("AuthService: Updating user location to (\(latitude), \(longitude))")
        let requestBody = UpdateLocationRequest(latitude: latitude, longitude: longitude)
        try await networkClient.performRequestNoContent(
            endpointPath: APIEndpoint.profileLocation,
            method: "PUT",
            body: requestBody
        )
        print("AuthService: User location update successful.")
    }
}

// Note: APIError enum and APIErrorResponse struct were moved to NetworkClient.swift 